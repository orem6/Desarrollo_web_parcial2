import express from 'express'
import { createServer } from 'node:http'
import cors from 'cors'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { Server } from 'socket.io'
import 'dotenv/config'
import { getPool, sql } from './db.js'

const app = express()
const secret = process.env.JWT_SECRET || 'development-only-secret-change-me'
const prefix = process.env.DB_TABLE_PREFIX || ''
if (!['', 'Keily_Subasta_'].includes(prefix)) throw new Error('DB_TABLE_PREFIX is not an allowed configuration value.')
const productionTables = prefix === 'Keily_Subasta_'
const tables = productionTables
  ? { users: 'dbo.Keily_Subasta_Users', vehicles: 'dbo.Keily_Subasta_Vehicles', images: 'dbo.Keily_Subasta_VehicleImages', auctions: 'dbo.Keily_Subasta_Auctions', bids: 'dbo.Keily_Subasta_Bids', placeBid: 'dbo.Keily_Subasta_PlaceBid' }
  : { users: 'dbo.Users', vehicles: 'dbo.Vehicles', images: 'dbo.VehicleImages', auctions: 'dbo.Auctions', bids: 'dbo.Bids', placeBid: 'dbo.PlaceBid' }
const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:5173'
const httpServer = createServer(app)
const io = new Server(httpServer, { cors: { origin: frontendUrl, methods: ['GET', 'POST'] } })
app.use(cors({ origin: frontendUrl }))
app.use(express.json())

io.on('connection', (socket) => {
  socket.on('auction:join', (auctionId) => {
    if (Number.isInteger(Number(auctionId)) && Number(auctionId) > 0) socket.join(`auction:${auctionId}`)
  })
  socket.on('auction:leave', (auctionId) => socket.leave(`auction:${auctionId}`))
})

function tokenFor(user) {
  return jwt.sign({ userId: user.UserID, firstName: user.FirstName, email: user.Email }, secret, { expiresIn: '8h' })
}

function auth(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '')
  try { req.user = jwt.verify(token, secret); next() } catch { res.status(401).json({ error: 'Inicia sesion para continuar.' }) }
}

const vehicleSelect = `
SELECT v.VehicleID, v.[Year], v.ItemType, v.Brand, v.Model, v.Engine, v.Transmission, v.FuelType, v.DriveTrain, v.Cylinders, v.DamageLevel, v.[Description],
 a.AuctionID, a.BasePrice, a.StartAt, a.EndAt, a.Status,
 COALESCE((SELECT MAX(b.Amount) FROM ${tables.bids} b WHERE b.AuctionID = a.AuctionID), a.BasePrice) AS CurrentPrice,
 (SELECT TOP 1 ImageURL FROM ${tables.images} i WHERE i.VehicleID = v.VehicleID ORDER BY SortOrder) AS CoverImage
FROM ${tables.vehicles} v JOIN ${tables.auctions} a ON a.VehicleID = v.VehicleID`

const minimumNextBidExpression = productionTables ? 'ROUND(topBid.Amount * 1.10, 2)' : 'topBid.Amount + 100.00'
async function getAuctionState(pool, auctionId) {
  const result = await pool.request().input('auctionId', sql.Int, auctionId).query(`
    SELECT a.AuctionID, a.EndAt,
      CASE WHEN a.Status = 'CANCELLED' THEN 'CANCELLED' WHEN SYSUTCDATETIME() < a.StartAt THEN 'SCHEDULED' WHEN SYSUTCDATETIME() >= a.EndAt THEN 'ENDED' ELSE 'ACTIVE' END AS Status,
      COALESCE(topBid.Amount, a.BasePrice) AS CurrentBid,
      CASE WHEN topBid.Amount IS NULL THEN a.BasePrice ELSE ${minimumNextBidExpression} END AS MinimumNextBid,
      topBid.BidderUserID AS HighestBidderId
    FROM ${tables.auctions} a
    OUTER APPLY (SELECT TOP 1 Amount, BidderUserID FROM ${tables.bids} WHERE AuctionID=a.AuctionID ORDER BY Amount DESC, CreatedAt DESC) topBid
    WHERE a.AuctionID=@auctionId
  `)
  return result.recordset[0]
}

app.get('/api/health', async (_req, res) => {
  try { await getPool(); res.json({ ok: true }) } catch (error) { res.status(500).json({ ok: false, error: error.message }) }
})

app.get('/api/catalogs', async (_req, res, next) => {
  try {
    const pool = await getPool()
    const result = await pool.request().query(`SELECT DISTINCT Brand FROM ${tables.vehicles} ORDER BY Brand; SELECT DISTINCT [Year] FROM ${tables.vehicles} ORDER BY [Year] DESC; SELECT DISTINCT Model FROM ${tables.vehicles} ORDER BY Model; SELECT DISTINCT FuelType FROM ${tables.vehicles} WHERE FuelType IS NOT NULL ORDER BY FuelType;`)
    res.json({ brands: result.recordsets[0].map((x) => x.Brand), years: result.recordsets[1].map((x) => x.Year), models: result.recordsets[2].map((x) => x.Model), fuelTypes: result.recordsets[3].map((x) => x.FuelType), damageLevels: ['GREEN', 'YELLOW', 'RED'] })
  } catch (error) { next(error) }
})

app.get('/api/vehicles', async (req, res, next) => {
  try {
    const pool = await getPool()
    const request = pool.request()
    const clauses = []
    if (req.query.brand) { clauses.push('v.Brand = @brand'); request.input('brand', sql.NVarChar, req.query.brand) }
    if (req.query.year) { clauses.push('v.[Year] = @year'); request.input('year', sql.SmallInt, req.query.year) }
    if (req.query.model) { clauses.push('v.Model = @model'); request.input('model', sql.NVarChar, req.query.model) }
    if (req.query.fuelType) { clauses.push('v.FuelType = @fuelType'); request.input('fuelType', sql.NVarChar, req.query.fuelType) }
    if (req.query.damage) { clauses.push('v.DamageLevel = @damage'); request.input('damage', sql.VarChar, req.query.damage) }
    if (req.query.status) { clauses.push('a.Status = @status'); request.input('status', sql.VarChar, req.query.status) }
    const where = clauses.length ? ` WHERE ${clauses.join(' AND ')}` : ''
    const result = await request.query(`${vehicleSelect}${where} ORDER BY CASE a.Status WHEN 'ACTIVE' THEN 0 WHEN 'SCHEDULED' THEN 1 ELSE 2 END, a.EndAt`)
    res.json(result.recordset)
  } catch (error) { next(error) }
})

function publicationError(body) {
  const required = ['year', 'itemType', 'brand', 'model', 'engine', 'transmission', 'fuelType', 'driveTrain', 'cylinders', 'damageLevel', 'basePrice', 'startAt', 'endAt']
  if (required.some((field) => body[field] === undefined || body[field] === '')) return 'Completa todos los campos requeridos.'
  if (!Number.isInteger(Number(body.year)) || Number(body.year) < 1886 || Number(body.year) > 2100) return 'El ano no es valido.'
  if (!Number.isInteger(Number(body.cylinders)) || Number(body.cylinders) < 1 || Number(body.cylinders) > 16) return 'El numero de cilindros no es valido.'
  if (!['GREEN', 'YELLOW', 'RED'].includes(body.damageLevel) || !['AWD', 'FWD', 'RWD', '4WD'].includes(body.driveTrain)) return 'Los valores de dano o traccion no son validos.'
  if (!Number.isFinite(Number(body.basePrice)) || Number(body.basePrice) <= 0) return 'El monto base debe ser mayor que cero.'
  if (!Array.isArray(body.images) || body.images.length < 5 || body.images.some((image) => typeof image !== 'string' || !image.trim())) return 'Incluye al menos cinco URLs de imagen.'
  if (!body.startAt || !body.endAt || new Date(body.startAt) >= new Date(body.endAt)) return 'La fecha de cierre debe ser posterior al inicio.'
  return null
}

app.post('/api/vehicles', auth, async (req, res, next) => {
  const error = publicationError(req.body)
  if (error) return res.status(400).json({ error })
  try {
    const pool = await getPool(); const transaction = new sql.Transaction(pool); await transaction.begin()
    try {
      const body = req.body
      const vehicle = await new sql.Request(transaction).input('owner', sql.Int, req.user.userId).input('year', sql.SmallInt, body.year).input('itemType', sql.NVarChar, body.itemType).input('brand', sql.NVarChar, body.brand).input('model', sql.NVarChar, body.model).input('engine', sql.NVarChar, body.engine).input('transmission', sql.NVarChar, body.transmission).input('fuelType', sql.NVarChar, body.fuelType).input('driveTrain', sql.NVarChar, body.driveTrain).input('cylinders', sql.TinyInt, body.cylinders).input('damage', sql.VarChar, body.damageLevel).input('description', sql.NVarChar, body.description || null).query(`INSERT ${tables.vehicles} (OwnerUserID,[Year],ItemType,Brand,Model,Engine,Transmission,FuelType,DriveTrain,Cylinders,DamageLevel,[Description]) OUTPUT inserted.VehicleID VALUES (@owner,@year,@itemType,@brand,@model,@engine,@transmission,@fuelType,@driveTrain,@cylinders,@damage,@description)`)
      const vehicleId = vehicle.recordset[0].VehicleID
      for (const [sortOrder, image] of body.images.entries()) await new sql.Request(transaction).input('vehicleId', sql.Int, vehicleId).input('image', sql.NVarChar, image).input('sortOrder', sql.SmallInt, sortOrder).query(`INSERT ${tables.images} (VehicleID,ImageURL,SortOrder) VALUES (@vehicleId,@image,@sortOrder)`)
      await new sql.Request(transaction).input('vehicleId', sql.Int, vehicleId).input('basePrice', sql.Decimal(18, 2), body.basePrice).input('startAt', sql.DateTime2, new Date(body.startAt)).input('endAt', sql.DateTime2, new Date(body.endAt)).query(`INSERT ${tables.auctions} (VehicleID,BasePrice,StartAt,EndAt,Status) VALUES (@vehicleId,@basePrice,@startAt,@endAt,CASE WHEN @startAt <= SYSUTCDATETIME() THEN 'ACTIVE' ELSE 'SCHEDULED' END)`)
      await transaction.commit(); res.status(201).json({ vehicleId })
    } catch (transactionError) { await transaction.rollback(); throw transactionError }
  } catch (error) { next(error) }
})

app.get('/api/my-vehicles', auth, async (req, res, next) => {
  try { const pool = await getPool(); const result = await pool.request().input('owner', sql.Int, req.user.userId).query(`${vehicleSelect} WHERE v.OwnerUserID=@owner ORDER BY v.CreatedAt DESC`); res.json(result.recordset) } catch (error) { next(error) }
})

app.put('/api/vehicles/:id', auth, async (req, res, next) => {
  const error = publicationError(req.body)
  if (error) return res.status(400).json({ error })
  try {
    const pool = await getPool(); const transaction = new sql.Transaction(pool); await transaction.begin()
    try {
      const body = req.body; const ownership = await new sql.Request(transaction).input('id', sql.Int, req.params.id).input('owner', sql.Int, req.user.userId).query(`SELECT v.VehicleID, a.AuctionID, CASE WHEN EXISTS (SELECT 1 FROM ${tables.bids} WHERE AuctionID=a.AuctionID) THEN 1 ELSE 0 END AS HasBids FROM ${tables.vehicles} v JOIN ${tables.auctions} a ON a.VehicleID=v.VehicleID WHERE v.VehicleID=@id AND v.OwnerUserID=@owner`)
      if (!ownership.recordset[0]) { await transaction.rollback(); return res.status(403).json({ error: 'No puedes editar esta publicacion.' }) }
      if (ownership.recordset[0].HasBids) { await transaction.rollback(); return res.status(409).json({ error: 'No se puede editar una subasta que ya tiene pujas.' }) }
      await new sql.Request(transaction).input('id', sql.Int, req.params.id).input('year', sql.SmallInt, body.year).input('itemType', sql.NVarChar, body.itemType).input('brand', sql.NVarChar, body.brand).input('model', sql.NVarChar, body.model).input('engine', sql.NVarChar, body.engine).input('transmission', sql.NVarChar, body.transmission).input('fuelType', sql.NVarChar, body.fuelType).input('driveTrain', sql.NVarChar, body.driveTrain).input('cylinders', sql.TinyInt, body.cylinders).input('damage', sql.VarChar, body.damageLevel).input('description', sql.NVarChar, body.description || null).query(`UPDATE ${tables.vehicles} SET [Year]=@year,ItemType=@itemType,Brand=@brand,Model=@model,Engine=@engine,Transmission=@transmission,FuelType=@fuelType,DriveTrain=@driveTrain,Cylinders=@cylinders,DamageLevel=@damage,[Description]=@description,UpdatedAt=SYSUTCDATETIME() WHERE VehicleID=@id`)
      await new sql.Request(transaction).input('auction', sql.Int, ownership.recordset[0].AuctionID).input('basePrice', sql.Decimal(18, 2), body.basePrice).input('startAt', sql.DateTime2, new Date(body.startAt)).input('endAt', sql.DateTime2, new Date(body.endAt)).query(`UPDATE ${tables.auctions} SET BasePrice=@basePrice,StartAt=@startAt,EndAt=@endAt,Status=CASE WHEN @startAt <= SYSUTCDATETIME() THEN 'ACTIVE' ELSE 'SCHEDULED' END,UpdatedAt=SYSUTCDATETIME() WHERE AuctionID=@auction`)
      await transaction.commit(); res.json({ ok: true })
    } catch (transactionError) { if (transaction._aborted !== true) await transaction.rollback(); throw transactionError }
  } catch (error) { next(error) }
})

app.get('/api/vehicles/:id', async (req, res, next) => {
  try {
    const pool = await getPool()
    const request = pool.request().input('id', sql.Int, req.params.id)
    const result = await request.query(`${vehicleSelect} WHERE v.VehicleID = @id; SELECT ImageURL, PublicId, SortOrder FROM ${tables.images} WHERE VehicleID = @id ORDER BY SortOrder;`)
    if (!result.recordsets[0][0]) return res.status(404).json({ error: 'Vehiculo no encontrado.' })
    const state = await getAuctionState(pool, result.recordsets[0][0].AuctionID)
    res.json({ ...result.recordsets[0][0], ...state, images: result.recordsets[1] })
  } catch (error) { next(error) }
})

app.post('/api/auth/register', async (req, res, next) => {
  try {
    const { firstName, lastName, email, phone, password } = req.body
    if (!firstName || !lastName || !email || !password || password.length < 8) return res.status(400).json({ error: 'Completa los datos y usa una contrasena de al menos 8 caracteres.' })
    const hash = await bcrypt.hash(password, 12)
    const pool = await getPool()
    const result = await pool.request().input('firstName', sql.NVarChar, firstName).input('lastName', sql.NVarChar, lastName).input('email', sql.NVarChar, email.toLowerCase()).input('phone', sql.NVarChar, phone || null).input('hash', sql.NVarChar, hash).query(`INSERT ${tables.users} (FirstName, LastName, Email, Phone, PasswordHash) OUTPUT inserted.UserID, inserted.FirstName, inserted.Email VALUES (@firstName, @lastName, @email, @phone, @hash)`)
    const user = result.recordset[0]
    res.status(201).json({ token: tokenFor(user), user })
  } catch (error) { if (error.number === 2627) return res.status(409).json({ error: 'Ese correo ya esta registrado.' }); next(error) }
})

app.post('/api/auth/login', async (req, res, next) => {
  try {
    const pool = await getPool()
    const result = await pool.request().input('email', sql.NVarChar, req.body.email?.toLowerCase()).query(`SELECT UserID, FirstName, Email, PasswordHash FROM ${tables.users} WHERE Email=@email AND IsActive=1`)
    const user = result.recordset[0]
    if (!user || !await bcrypt.compare(req.body.password || '', user.PasswordHash)) return res.status(401).json({ error: 'Correo o contrasena incorrectos.' })
    res.json({ token: tokenFor(user), user: { UserID: user.UserID, FirstName: user.FirstName, Email: user.Email } })
  } catch (error) { next(error) }
})

app.get('/api/auctions/:id/participation', auth, async (req, res, next) => {
  try {
    const pool = await getPool()
    const result = await pool.request().input('auctionId', sql.Int, req.params.id).input('userId', sql.Int, req.user.userId).query(`SELECT CASE WHEN EXISTS (SELECT 1 FROM ${tables.bids} WHERE AuctionID=@auctionId AND BidderUserID=@userId) THEN 1 ELSE 0 END AS HasParticipated`)
    res.json({ hasParticipated: result.recordset[0].HasParticipated === 1 })
  } catch (error) { next(error) }
})

app.post('/api/auctions/:id/bids', auth, async (req, res, _next) => {
  try {
    const amount = Number(req.body.amount)
    if (!Number.isFinite(amount) || amount <= 0) return res.status(400).json({ error: 'Indica una oferta valida.' })
    const pool = await getPool()
    await pool.request().input('AuctionID', sql.Int, req.params.id).input('BidderUserID', sql.Int, req.user.userId).input('Amount', sql.Decimal(18, 2), amount).execute(tables.placeBid)
    const state = await getAuctionState(pool, req.params.id)
    io.to(`auction:${req.params.id}`).emit('bid:updated', { auctionId: state.AuctionID, currentBid: state.CurrentBid, minimumNextBid: state.MinimumNextBid, highestBidderId: state.HighestBidderId, endAt: state.EndAt, status: state.Status })
    res.status(201).json(state)
  } catch (error) { res.status(400).json({ error: error.originalError?.info?.message || error.message }) }
})

app.use((error, _req, res, _next) => { console.error(error); res.status(500).json({ error: 'Error interno del servidor.' }) })
httpServer.listen(process.env.PORT || 3001, () => console.log(`API ready on port ${process.env.PORT || 3001}`))
