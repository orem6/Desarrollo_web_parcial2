/* NOT EXECUTED. Creates only project-prefixed objects in db_WebDevUMG. */
USE db_WebDevUMG;
GO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name IN (N'Keily_Subasta_Users',N'Keily_Subasta_Vehicles',N'Keily_Subasta_VehicleImages',N'Keily_Subasta_Auctions',N'Keily_Subasta_Bids')) OR OBJECT_ID(N'dbo.Keily_Subasta_PlaceBid', N'P') IS NOT NULL
    THROW 51000, 'Project-prefixed objects already exist. Review them before any change.', 1;
GO
CREATE TABLE dbo.Keily_Subasta_Users (
 UserID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Keily_Subasta_Users PRIMARY KEY, FirstName NVARCHAR(80) NOT NULL, LastName NVARCHAR(80) NOT NULL, Email NVARCHAR(254) NOT NULL, Phone NVARCHAR(30) NULL, PasswordHash NVARCHAR(255) NOT NULL, CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Keily_Subasta_Users_CreatedAt DEFAULT SYSUTCDATETIME(), IsActive BIT NOT NULL CONSTRAINT DF_Keily_Subasta_Users_IsActive DEFAULT 1, CONSTRAINT UQ_Keily_Subasta_Users_Email UNIQUE (Email)
);
CREATE TABLE dbo.Keily_Subasta_Vehicles (
 VehicleID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Keily_Subasta_Vehicles PRIMARY KEY, OwnerUserID INT NOT NULL, [Year] SMALLINT NOT NULL, ItemType NVARCHAR(40) NOT NULL CONSTRAINT DF_Keily_Subasta_Vehicles_ItemType DEFAULT N'Automovil', Brand NVARCHAR(80) NOT NULL, Model NVARCHAR(80) NOT NULL, Engine NVARCHAR(100) NULL, Transmission NVARCHAR(40) NULL, FuelType NVARCHAR(40) NULL, DriveTrain NVARCHAR(40) NULL, Cylinders TINYINT NULL, DamageLevel VARCHAR(10) NOT NULL, [Description] NVARCHAR(1500) NULL, CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Keily_Subasta_Vehicles_CreatedAt DEFAULT SYSUTCDATETIME(), UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Keily_Subasta_Vehicles_UpdatedAt DEFAULT SYSUTCDATETIME(), CONSTRAINT FK_Keily_Subasta_Vehicles_Owner FOREIGN KEY (OwnerUserID) REFERENCES dbo.Keily_Subasta_Users(UserID), CONSTRAINT CK_Keily_Subasta_Vehicles_Year CHECK ([Year] BETWEEN 1886 AND 2100), CONSTRAINT CK_Keily_Subasta_Vehicles_Damage CHECK (DamageLevel IN ('GREEN','YELLOW','RED')), CONSTRAINT CK_Keily_Subasta_Vehicles_Cylinders CHECK (Cylinders IS NULL OR Cylinders BETWEEN 1 AND 16)
);
CREATE TABLE dbo.Keily_Subasta_VehicleImages (
 ImageID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Keily_Subasta_VehicleImages PRIMARY KEY, VehicleID INT NOT NULL, ImageURL NVARCHAR(2048) NOT NULL, PublicId NVARCHAR(255) NULL, SortOrder SMALLINT NOT NULL CONSTRAINT DF_Keily_Subasta_VehicleImages_Sort DEFAULT 0, CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Keily_Subasta_VehicleImages_CreatedAt DEFAULT SYSUTCDATETIME(), CONSTRAINT FK_Keily_Subasta_VehicleImages_Vehicle FOREIGN KEY (VehicleID) REFERENCES dbo.Keily_Subasta_Vehicles(VehicleID), CONSTRAINT UQ_Keily_Subasta_VehicleImages_Sort UNIQUE (VehicleID, SortOrder), CONSTRAINT CK_Keily_Subasta_VehicleImages_Sort CHECK (SortOrder >= 0)
);
CREATE TABLE dbo.Keily_Subasta_Auctions (
 AuctionID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Keily_Subasta_Auctions PRIMARY KEY, VehicleID INT NOT NULL, BasePrice DECIMAL(18,2) NOT NULL, StartAt DATETIME2(0) NOT NULL, EndAt DATETIME2(0) NOT NULL, Status VARCHAR(15) NOT NULL CONSTRAINT DF_Keily_Subasta_Auctions_Status DEFAULT 'SCHEDULED', CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Keily_Subasta_Auctions_CreatedAt DEFAULT SYSUTCDATETIME(), UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Keily_Subasta_Auctions_UpdatedAt DEFAULT SYSUTCDATETIME(), CONSTRAINT FK_Keily_Subasta_Auctions_Vehicle FOREIGN KEY (VehicleID) REFERENCES dbo.Keily_Subasta_Vehicles(VehicleID), CONSTRAINT UQ_Keily_Subasta_Auctions_Vehicle UNIQUE (VehicleID), CONSTRAINT CK_Keily_Subasta_Auctions_Price CHECK (BasePrice > 0), CONSTRAINT CK_Keily_Subasta_Auctions_Dates CHECK (StartAt < EndAt), CONSTRAINT CK_Keily_Subasta_Auctions_Status CHECK (Status IN ('SCHEDULED','ACTIVE','ENDED','CANCELLED'))
);
CREATE TABLE dbo.Keily_Subasta_Bids (
 BidID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Keily_Subasta_Bids PRIMARY KEY, AuctionID INT NOT NULL, BidderUserID INT NOT NULL, Amount DECIMAL(18,2) NOT NULL, CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Keily_Subasta_Bids_CreatedAt DEFAULT SYSUTCDATETIME(), CONSTRAINT FK_Keily_Subasta_Bids_Auction FOREIGN KEY (AuctionID) REFERENCES dbo.Keily_Subasta_Auctions(AuctionID), CONSTRAINT FK_Keily_Subasta_Bids_User FOREIGN KEY (BidderUserID) REFERENCES dbo.Keily_Subasta_Users(UserID), CONSTRAINT CK_Keily_Subasta_Bids_Amount CHECK (Amount > 0)
);
GO
