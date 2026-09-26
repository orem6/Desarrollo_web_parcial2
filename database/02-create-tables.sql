USE SubastasVehiculosDB;
GO

CREATE TABLE dbo.Users (
    UserID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
    FirstName NVARCHAR(80) NOT NULL,
    LastName NVARCHAR(80) NOT NULL,
    Email NVARCHAR(254) NOT NULL,
    Phone NVARCHAR(30) NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSUTCDATETIME(),
    IsActive BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT 1,
    CONSTRAINT UQ_Users_Email UNIQUE (Email)
);
GO

CREATE TABLE dbo.Vehicles (
    VehicleID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Vehicles PRIMARY KEY,
    OwnerUserID INT NOT NULL,
    [Year] SMALLINT NOT NULL,
    ItemType NVARCHAR(40) NOT NULL CONSTRAINT DF_Vehicles_ItemType DEFAULT N'Automovil',
    Brand NVARCHAR(80) NOT NULL,
    Model NVARCHAR(80) NOT NULL,
    Engine NVARCHAR(100) NULL,
    Transmission NVARCHAR(40) NULL,
    FuelType NVARCHAR(40) NULL,
    DriveTrain NVARCHAR(40) NULL,
    Cylinders TINYINT NULL,
    DamageLevel VARCHAR(10) NOT NULL,
    [Description] NVARCHAR(1500) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Vehicles_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Vehicles_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Vehicles_Owner FOREIGN KEY (OwnerUserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT CK_Vehicles_Year CHECK ([Year] BETWEEN 1886 AND 2100),
    CONSTRAINT CK_Vehicles_DamageLevel CHECK (DamageLevel IN ('GREEN', 'YELLOW', 'RED')),
    CONSTRAINT CK_Vehicles_Cylinders CHECK (Cylinders IS NULL OR Cylinders BETWEEN 1 AND 16)
);
GO

CREATE TABLE dbo.VehicleImages (
    ImageID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VehicleImages PRIMARY KEY,
    VehicleID INT NOT NULL,
    ImageURL NVARCHAR(2048) NOT NULL,
    PublicId NVARCHAR(255) NULL,
    SortOrder SMALLINT NOT NULL CONSTRAINT DF_VehicleImages_SortOrder DEFAULT 0,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_VehicleImages_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_VehicleImages_Vehicle FOREIGN KEY (VehicleID) REFERENCES dbo.Vehicles(VehicleID),
    CONSTRAINT UQ_VehicleImages_Vehicle_SortOrder UNIQUE (VehicleID, SortOrder),
    CONSTRAINT CK_VehicleImages_SortOrder CHECK (SortOrder >= 0)
);
GO

CREATE TABLE dbo.Auctions (
    AuctionID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Auctions PRIMARY KEY,
    VehicleID INT NOT NULL,
    BasePrice DECIMAL(18,2) NOT NULL,
    StartAt DATETIME2(0) NOT NULL,
    EndAt DATETIME2(0) NOT NULL,
    Status VARCHAR(15) NOT NULL CONSTRAINT DF_Auctions_Status DEFAULT 'SCHEDULED',
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Auctions_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Auctions_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Auctions_Vehicle FOREIGN KEY (VehicleID) REFERENCES dbo.Vehicles(VehicleID),
    CONSTRAINT UQ_Auctions_Vehicle UNIQUE (VehicleID),
    CONSTRAINT CK_Auctions_BasePrice CHECK (BasePrice > 0),
    CONSTRAINT CK_Auctions_Dates CHECK (StartAt < EndAt),
    CONSTRAINT CK_Auctions_Status CHECK (Status IN ('SCHEDULED', 'ACTIVE', 'ENDED', 'CANCELLED'))
);
GO

CREATE TABLE dbo.Bids (
    BidID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Bids PRIMARY KEY,
    AuctionID INT NOT NULL,
    BidderUserID INT NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Bids_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Bids_Auction FOREIGN KEY (AuctionID) REFERENCES dbo.Auctions(AuctionID),
    CONSTRAINT FK_Bids_Bidder FOREIGN KEY (BidderUserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT CK_Bids_Amount CHECK (Amount > 0)
);
GO

CREATE OR ALTER PROCEDURE dbo.PlaceBid
    @AuctionID INT,
    @BidderUserID INT,
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRANSACTION;
    DECLARE @BasePrice DECIMAL(18,2), @StartAt DATETIME2(0), @EndAt DATETIME2(0), @Status VARCHAR(15), @HighestBid DECIMAL(18,2), @MinimumBid DECIMAL(18,2);

    SELECT @BasePrice = BasePrice, @StartAt = StartAt, @EndAt = EndAt, @Status = Status
    FROM dbo.Auctions WITH (UPDLOCK, HOLDLOCK)
    WHERE AuctionID = @AuctionID;

    IF @BasePrice IS NULL
        THROW 50001, 'La subasta no existe.', 1;
    IF @Status <> 'ACTIVE' OR SYSUTCDATETIME() NOT BETWEEN @StartAt AND @EndAt
        THROW 50002, 'La subasta no esta activa.', 1;

    SELECT @HighestBid = MAX(Amount)
    FROM dbo.Bids WITH (UPDLOCK, HOLDLOCK)
    WHERE AuctionID = @AuctionID;

    SET @MinimumBid = CASE WHEN @HighestBid IS NULL THEN @BasePrice ELSE @HighestBid + 100.00 END;
    IF @Amount < @MinimumBid
        THROW 50003, 'La oferta es menor que el minimo permitido.', 1;

    INSERT dbo.Bids (AuctionID, BidderUserID, Amount) VALUES (@AuctionID, @BidderUserID, @Amount);
    COMMIT TRANSACTION;
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS BidID, @MinimumBid AS AcceptedMinimum;
END
GO
