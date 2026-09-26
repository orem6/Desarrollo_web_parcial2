USE SubastasVehiculosDB;
GO
/* Re-runnable seed: inserts data only when the demo email is absent. Password: Demo123! */
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'ana@demo.subastas')
BEGIN
    DECLARE @Hash NVARCHAR(255) = N'$2b$12$ZaSoBX.Pjm.Q3.8/SRy1e.WwxETPFsjJa3W8c87nud2mqEcesIoNC';
    INSERT dbo.Users (FirstName, LastName, Email, Phone, PasswordHash) VALUES
    (N'Ana', N'Garcia', N'ana@demo.subastas', N'+34 600 100 101', @Hash),
    (N'Bruno', N'Lopez', N'bruno@demo.subastas', N'+34 600 100 102', @Hash),
    (N'Carla', N'Martin', N'carla@demo.subastas', N'+34 600 100 103', @Hash);

    DECLARE @Ana INT = (SELECT UserID FROM dbo.Users WHERE Email = N'ana@demo.subastas');
    DECLARE @Bruno INT = (SELECT UserID FROM dbo.Users WHERE Email = N'bruno@demo.subastas');
    DECLARE @Carla INT = (SELECT UserID FROM dbo.Users WHERE Email = N'carla@demo.subastas');
    INSERT dbo.Vehicles (OwnerUserID, [Year], ItemType, Brand, Model, Engine, Transmission, FuelType, DriveTrain, Cylinders, DamageLevel, [Description]) VALUES
    (@Ana, 2021, N'SUV', N'Toyota', N'RAV4', N'2.5L Hybrid', N'Automatica', N'Hibrido', N'AWD', 4, 'GREEN', N'Vehiculo de un propietario, mantenimiento documentado.'),
    (@Bruno, 2019, N'Sedan', N'BMW', N'330i', N'2.0L Turbo', N'Automatica', N'Gasolina', N'RWD', 4, 'YELLOW', N'Danos reparables en el lateral derecho.'),
    (@Carla, 2017, N'Pickup', N'Ford', N'Ranger', N'3.2L TDCi', N'Automatica', N'Diesel', N'4WD', 5, 'RED', N'Requiere reparacion estructural. Ideal para profesionales.'),
    (@Ana, 2022, N'Coupe', N'Mazda', N'MX-5', N'2.0L', N'Manual', N'Gasolina', N'RWD', 4, 'GREEN', N'Unidad cuidada con documentacion completa.');

    INSERT dbo.VehicleImages (VehicleID, ImageURL, SortOrder)
    SELECT v.VehicleID, x.ImageURL, x.SortOrder FROM dbo.Vehicles v CROSS APPLY (VALUES
    (N'https://images.unsplash.com/photo-1550355291-bbee04a92027?auto=format&fit=crop&w=1200&q=80', 0),(N'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80', 1),(N'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&w=1200&q=80', 2),(N'https://images.unsplash.com/photo-1504215680853-026ed2a45def?auto=format&fit=crop&w=1200&q=80', 3),(N'https://images.unsplash.com/photo-1502877338535-766e1452684a?auto=format&fit=crop&w=1200&q=80', 4)) x(ImageURL, SortOrder)
    WHERE v.Brand = N'Toyota';
    INSERT dbo.VehicleImages (VehicleID, ImageURL, SortOrder)
    SELECT v.VehicleID, x.ImageURL, x.SortOrder FROM dbo.Vehicles v CROSS APPLY (VALUES
    (N'https://images.unsplash.com/photo-1520050206274-a1ae44613e6d?auto=format&fit=crop&w=1200&q=80', 0),(N'https://images.unsplash.com/photo-1553440569-bcc63803a83d?auto=format&fit=crop&w=1200&q=80', 1),(N'https://images.unsplash.com/photo-1494905998402-395d579af36f?auto=format&fit=crop&w=1200&q=80', 2),(N'https://images.unsplash.com/photo-1542282088-fe8426682b8f?auto=format&fit=crop&w=1200&q=80', 3),(N'https://images.unsplash.com/photo-1493238792000-8113da705763?auto=format&fit=crop&w=1200&q=80', 4)) x(ImageURL, SortOrder)
    WHERE v.Brand = N'BMW';
    INSERT dbo.VehicleImages (VehicleID, ImageURL, SortOrder)
    SELECT v.VehicleID, x.ImageURL, x.SortOrder FROM dbo.Vehicles v CROSS APPLY (VALUES
    (N'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?auto=format&fit=crop&w=1200&q=80', 0),(N'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?auto=format&fit=crop&w=1200&q=80', 1),(N'https://images.unsplash.com/photo-1514316454349-750a7fd3da3a?auto=format&fit=crop&w=1200&q=80', 2),(N'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=1200&q=80', 3),(N'https://images.unsplash.com/photo-1533106418989-88406c7cc8ca?auto=format&fit=crop&w=1200&q=80', 4)) x(ImageURL, SortOrder)
    WHERE v.Brand = N'Ford';
    INSERT dbo.VehicleImages (VehicleID, ImageURL, SortOrder)
    SELECT v.VehicleID, x.ImageURL, x.SortOrder FROM dbo.Vehicles v CROSS APPLY (VALUES
    (N'https://images.unsplash.com/photo-1544829099-b9a0c07fad1a?auto=format&fit=crop&w=1200&q=80', 0),(N'https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98?auto=format&fit=crop&w=1200&q=80', 1),(N'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=1200&q=80', 2),(N'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?auto=format&fit=crop&w=1200&q=80', 3),(N'https://images.unsplash.com/photo-1525609004556-c46c7d6cf023?auto=format&fit=crop&w=1200&q=80', 4)) x(ImageURL, SortOrder)
    WHERE v.Brand = N'Mazda';
    INSERT dbo.Auctions (VehicleID, BasePrice, StartAt, EndAt, Status) SELECT VehicleID, 18500, DATEADD(day,-1,SYSUTCDATETIME()), DATEADD(day,5,SYSUTCDATETIME()), 'ACTIVE' FROM dbo.Vehicles WHERE Brand=N'Toyota';
    INSERT dbo.Auctions (VehicleID, BasePrice, StartAt, EndAt, Status) SELECT VehicleID, 12600, DATEADD(day,-2,SYSUTCDATETIME()), DATEADD(day,2,SYSUTCDATETIME()), 'ACTIVE' FROM dbo.Vehicles WHERE Brand=N'BMW';
    INSERT dbo.Auctions (VehicleID, BasePrice, StartAt, EndAt, Status) SELECT VehicleID, 5400, DATEADD(day,-10,SYSUTCDATETIME()), DATEADD(day,-1,SYSUTCDATETIME()), 'ENDED' FROM dbo.Vehicles WHERE Brand=N'Ford';
    INSERT dbo.Auctions (VehicleID, BasePrice, StartAt, EndAt, Status) SELECT VehicleID, 22000, DATEADD(day,3,SYSUTCDATETIME()), DATEADD(day,10,SYSUTCDATETIME()), 'SCHEDULED' FROM dbo.Vehicles WHERE Brand=N'Mazda';
    INSERT dbo.Bids (AuctionID, BidderUserID, Amount) SELECT a.AuctionID, @Bruno, 19000 FROM dbo.Auctions a JOIN dbo.Vehicles v ON v.VehicleID=a.VehicleID WHERE v.Brand=N'Toyota';
    INSERT dbo.Bids (AuctionID, BidderUserID, Amount) SELECT a.AuctionID, @Carla, 19300 FROM dbo.Auctions a JOIN dbo.Vehicles v ON v.VehicleID=a.VehicleID WHERE v.Brand=N'Toyota';
    INSERT dbo.Bids (AuctionID, BidderUserID, Amount) SELECT a.AuctionID, @Ana, 13100 FROM dbo.Auctions a JOIN dbo.Vehicles v ON v.VehicleID=a.VehicleID WHERE v.Brand=N'BMW';
END
GO
