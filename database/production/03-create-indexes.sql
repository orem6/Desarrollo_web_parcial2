/* NOT EXECUTED. Run only after the prefixed tables were approved and created. */
USE db_WebDevUMG;
GO
CREATE INDEX IX_Keily_Subasta_Vehicles_Owner ON dbo.Keily_Subasta_Vehicles(OwnerUserID);
CREATE INDEX IX_Keily_Subasta_Vehicles_BrandModelYear ON dbo.Keily_Subasta_Vehicles(Brand, Model, [Year]);
CREATE INDEX IX_Keily_Subasta_VehicleImages_VehicleSort ON dbo.Keily_Subasta_VehicleImages(VehicleID, SortOrder);
CREATE INDEX IX_Keily_Subasta_Auctions_StatusEnd ON dbo.Keily_Subasta_Auctions(Status, EndAt) INCLUDE (VehicleID, BasePrice, StartAt);
CREATE INDEX IX_Keily_Subasta_Bids_AuctionAmount ON dbo.Keily_Subasta_Bids(AuctionID, Amount DESC) INCLUDE (BidderUserID, CreatedAt);
CREATE INDEX IX_Keily_Subasta_Bids_Bidder ON dbo.Keily_Subasta_Bids(BidderUserID, CreatedAt DESC);
GO
