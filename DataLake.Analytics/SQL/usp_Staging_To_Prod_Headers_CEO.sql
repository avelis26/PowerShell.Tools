USE								[7ELE]
GO
DROP PROCEDURE IF EXISTS		[dbo].[usp_Staging_To_Prod_Headers_CEO]
GO
CREATE PROCEDURE				[dbo].[usp_Staging_To_Prod_Headers_CEO]
AS
SET NOCOUNT ON
INSERT INTO						[dbo].[prod_121_Headers_CEO]
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
								[RewardMemberID],
								[RawFileName],
								[LineNo],
								[StageInsertStamp],
								[CsvFile],
								[DataLakeFolder],
								[Pk]
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
								[RewardMemberID],
								[RawFileName],
								[LineNo],
								[StageInsertStamp],
								[CsvFile],
								[DataLakeFolder],
								[Pk]
FROM							[dbo].[stg_121_Headers_1]
INSERT INTO						[dbo].[prod_121_Headers_CEO]
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
								[RewardMemberID],
								[RawFileName],
								[LineNo],
								[StageInsertStamp],
								[CsvFile],
								[DataLakeFolder],
								[Pk]
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
								[RewardMemberID],
								[RawFileName],
								[LineNo],
								[StageInsertStamp],
								[CsvFile],
								[DataLakeFolder],
								[Pk]
FROM							[dbo].[stg_121_Headers_2]
INSERT INTO						[dbo].[prod_121_Headers_CEO]
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
								[RewardMemberID],
								[RawFileName],
								[LineNo],
								[StageInsertStamp],
								[CsvFile],
								[DataLakeFolder],
								[Pk]
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
								[RewardMemberID],
								[RawFileName],
								[LineNo],
								[StageInsertStamp],
								[CsvFile],
								[DataLakeFolder],
								[Pk]
FROM							[dbo].[stg_121_Headers_3]
INSERT INTO						[dbo].[prod_121_Headers_CEO]
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
								[RewardMemberID],
								[RawFileName],
								[LineNo],
								[StageInsertStamp],
								[CsvFile],
								[DataLakeFolder],
								[Pk]
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
								[RewardMemberID],
								[RawFileName],
								[LineNo],
								[StageInsertStamp],
								[CsvFile],
								[DataLakeFolder],
								[Pk]
FROM							[dbo].[stg_121_Headers_4]
INSERT INTO						[dbo].[prod_121_Headers_CEO]
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
								[RewardMemberID],
								[RawFileName],
								[LineNo],
								[StageInsertStamp],
								[CsvFile],
								[DataLakeFolder],
								[Pk]
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
								[RewardMemberID],
								[RawFileName],
								[LineNo],
								[StageInsertStamp],
								[CsvFile],
								[DataLakeFolder],
								[Pk]
FROM							[dbo].[stg_121_Headers_5]
GO