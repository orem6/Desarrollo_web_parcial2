/* NOT EXECUTED. The procedure is limited to Keily_Subasta_* objects. */
USE db_WebDevUMG;
GO
IF OBJECT_ID(N'dbo.Keily_Subasta_PlaceBid', N'P') IS NOT NULL
    THROW 51001, 'Keily_Subasta_PlaceBid already exists. No changes made.', 1;
GO
CREATE PROCEDURE dbo.Keily_Subasta_PlaceBid
    @AuctionID INT,
    @BidderUserID INT,
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @BasePrice DECIMAL(18,2), @StartAt DATETIME2(0), @EndAt DATETIME2(0), @Status VARCHAR(15), @HighestBid DECIMAL(18,2), @MinimumBid DECIMAL(18,2);
        SELECT @BasePrice=BasePrice,@StartAt=StartAt,@EndAt=EndAt,@Status=Status FROM dbo.Keily_Subasta_Auctions WITH (UPDLOCK,HOLDLOCK) WHERE AuctionID=@AuctionID;
        IF @BasePrice IS NULL THROW 50001, 'La subasta no existe.', 1;
        IF @Status <> 'ACTIVE' OR SYSUTCDATETIME() NOT BETWEEN @StartAt AND @EndAt THROW 50002, 'La subasta no esta activa.', 1;
        SELECT @HighestBid=MAX(Amount) FROM dbo.Keily_Subasta_Bids WITH (UPDLOCK,HOLDLOCK) WHERE AuctionID=@AuctionID;
        SET @MinimumBid=CASE WHEN @HighestBid IS NULL THEN @BasePrice ELSE ROUND(@HighestBid * 1.10, 2) END;
        IF @Amount < @MinimumBid THROW 50003, 'La oferta es menor que el minimo permitido.', 1;
        INSERT dbo.Keily_Subasta_Bids (AuctionID,BidderUserID,Amount) VALUES (@AuctionID,@BidderUserID,@Amount);
        COMMIT TRANSACTION;
        SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS BidID,@MinimumBid AS AcceptedMinimum;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
