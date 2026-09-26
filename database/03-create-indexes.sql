USE SubastasVehiculosDB;
GO
CREATE INDEX IX_Vehicles_OwnerUserID ON dbo.Vehicles(OwnerUserID);
CREATE INDEX IX_Vehicles_Brand_Model_Year ON dbo.Vehicles(Brand, Model, [Year]);
CREATE INDEX IX_VehicleImages_VehicleID_SortOrder ON dbo.VehicleImages(VehicleID, SortOrder);
CREATE INDEX IX_Auctions_Status_EndAt ON dbo.Auctions(Status, EndAt) INCLUDE (VehicleID, BasePrice, StartAt);
CREATE INDEX IX_Bids_Auction_Amount ON dbo.Bids(AuctionID, Amount DESC) INCLUDE (BidderUserID, CreatedAt);
CREATE INDEX IX_Bids_BidderUserID ON dbo.Bids(BidderUserID, CreatedAt DESC);
GO
