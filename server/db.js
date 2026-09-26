import 'dotenv/config'

const driver = process.env.DB_DRIVER
if (!['msnodesqlv8', 'tedious'].includes(driver)) throw new Error('DB_DRIVER must be msnodesqlv8 or tedious.')

const useLocalDriver = driver === 'msnodesqlv8'
const sql = useLocalDriver ? (await import('mssql/msnodesqlv8.js')).default : (await import('mssql')).default
const server = process.env.DB_SERVER
const database = process.env.DB_DATABASE
if (!server || !database) throw new Error('DB_SERVER and DB_DATABASE are required.')
const asBoolean = (value) => value?.trim().toLowerCase() === 'true'

const config = useLocalDriver
  ? { driver: 'msnodesqlv8', connectionString: `Driver={ODBC Driver 18 for SQL Server};Server=${server};Database=${database};Trusted_Connection=Yes;TrustServerCertificate=${asBoolean(process.env.DB_TRUST_SERVER_CERTIFICATE) ? 'Yes' : 'No'};` }
  : {
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      server,
      database,
      port: Number(process.env.DB_PORT || 1433),
      options: { encrypt: asBoolean(process.env.DB_ENCRYPT), trustServerCertificate: asBoolean(process.env.DB_TRUST_SERVER_CERTIFICATE) },
    }

let pool
export async function getPool() {
  if (!pool) pool = await sql.connect(config)
  return pool
}
export { sql }
