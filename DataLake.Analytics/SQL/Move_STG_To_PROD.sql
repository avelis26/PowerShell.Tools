USE								[7ELE]
GO
IF EXISTS						(SELECT * FROM sys.procedures WHERE name = 'usp_Move_STG_To_PROD')
BEGIN
DROP PROCEDURE					[dbo].[usp_Move_STG_To_PROD]
END
GO
CREATE PROCEDURE				[dbo].[usp_Move_STG_To_PROD]
AS
SET NOCOUNT ON
INSERT INTO						[dbo].[prod_121_Header]
(
								[RecordId],
								[StoreNumber],
								[TransactionType],
								[DayNumber],
								[ShiftNumber],
								[TransactionUID],
								[Aborted],
								[DeviceNumber],
								[DeviceType],
								[EmployeeNumber],
								[EndDate],
								[EndTime],
								[StartDate],
								[StartTime],
								[Status],
								[TotalAmount],
								[TransactionCode],
								[TransactionSequence],
								[RewardMemberID]
)
SELECT
								[RecordId],
								[StoreNumber],
								[TransactionType],
								[DayNumber],
								[ShiftNumber],
								[TransactionUID],
								[Aborted],
								[DeviceNumber],
								[DeviceType],
								[EmployeeNumber],
								[EndDate],
								[EndTime],
								[StartDate],
								[StartTime],
								[Status],
								[TotalAmount],
								[TransactionCode],
								[TransactionSequence],
								[RewardMemberID]
FROM							[dbo].[stg_121_Headers]
TRUNCATE TABLE					[dbo].[stg_121_Headers]
INSERT INTO						[dbo].[prod_122_Details]
(
								[RecordID],
								[StoreNumber],
								[TransactionType],
								[DayNumber],
								[ShiftNumber],
								[TransactionUID],
								[SequenceNumber],
								[ProductNumber],
								[PLUNumber],
								[RecordAmount],
								[RecordCount],
								[RecordType],
								[SizeIndx],
								[ErrorCorrectionFlag],
								[PriceOverideFlag],
								[TaxableFlag],
								[VoidFlag],
								[RecommendedFlag],
								[PriceMultiple],
								[CarryStatus],
								[TaxOverideFlag],
								[PromotionCount],
								[SalesPrice],
								[MUBasePrice],
								[HostItemId],
								[CouponCount]
)
SELECT
								[RecordID],
								[StoreNumber],
								[TransactionType],
								[DayNumber],
								[ShiftNumber],
								[TransactionUID],
								[SequenceNumber],
								[ProductNumber],
								[PLUNumber],
								[RecordAmount],
								[RecordCount],
								[RecordType],
								[SizeIndx],
								[ErrorCorrectionFlag],
								[PriceOverideFlag],
								[TaxableFlag],
								[VoidFlag],
								[RecommendedFlag],
								[PriceMultiple],
								[CarryStatus],
								[TaxOverideFlag],
								[PromotionCount],
								[SalesPrice],
								[MUBasePrice],
								[HostItemId],
								[CouponCount]						
FROM							[dbo].[stg_122_Details]
TRUNCATE TABLE					[dbo].[stg_122_Details]
INSERT INTO						[dbo].[prod_124_Media]
(
								[RecordId],
								[StoreNumber],
								[TransactionType],
								[DayNumber],
								[ShiftNumber],
								[TransactionUID],
								[SequenceNumber],
								[MediaNumber],
								[NetworkMediaSequenceNumber],
								[MediaType],
								[RecordCount],
								[RecordAmount],
								[RecordType],
								[ErrorCorrectionFlag],
								[VoidFlag],
								[ExchangeRate],
								[ForeignAmount]
)
SELECT
								[RecordId],
								[StoreNumber],
								[TransactionType],
								[DayNumber],
								[ShiftNumber],
								[TransactionUID],
								[SequenceNumber],
								[MediaNumber],
								[NetworkMediaSequenceNumber],
								[MediaType],
								[RecordCount],
								[RecordAmount],
								[RecordType],
								[ErrorCorrectionFlag],
								[VoidFlag],
								[ExchangeRate],
								[ForeignAmount]
FROM							[dbo].[stg_124_Media]
TRUNCATE TABLE					[dbo].[stg_124_Media]
