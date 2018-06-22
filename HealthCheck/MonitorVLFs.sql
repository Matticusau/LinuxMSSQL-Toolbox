------------------------------
-- Monitor VLFs
-- Author:	MLavery
-- Date:	22/06/2018
-- Purpose: Provides the details of the VLFs where above 1000
--          Based on the script https://github.com/Microsoft/DataInsightsAsia/blob/master/Scripts/VLFs/VLFsReport.sql
--
-- When		Who			What
-- 
------------------------------
--

SET NOCOUNT ON;

-- declare variables required
DECLARE @majorVer SMALLINT, @minorVer SMALLINT, @build SMALLINT
DECLARE @DatabaseId INT;
DECLARE @TSQL varchar(MAX);
DECLARE cur_DBs CURSOR FOR
	SELECT database_id FROM sys.databases;
OPEN cur_DBs;
FETCH NEXT FROM cur_DBs INTO @DatabaseId

-- Get the version
SELECT @majorVer = (@@microsoftversion / 0x1000000) & 0xff, @minorVer = (@@microsoftversion / 0x10000) & 0xff, @build = @@microsoftversion & 0xffff

-- These table variables will be used to store the data
DECLARE @tblAllDBs Table (DBName sysname
	, FileId INT
	, FileSize BIGINT
	, StartOffset BIGINT
	, FSeqNo INT
	, Status TinyInt
	, Parity INT
	, CreateLSN NUMERIC(25,0)
)
IF ( @majorVer >= 11 )
BEGIN
	DECLARE @tblVLFs2012 Table (RecoveryUnitId BIGINT
		, FileId INT
		, FileSize BIGINT
		, StartOffset BIGINT
		, FSeqNo INT
		, Status TinyInt
		, Parity INT
		, CreateLSN NUMERIC(25,0)
	);
END
ELSE
BEGIN
	DECLARE @tblVLFs Table (
		FileId INT
		, FileSize BIGINT
		, StartOffset BIGINT
		, FSeqNo INT
		, Status TinyInt
		, Parity INT
		, CreateLSN NUMERIC(25,0)
	);
END

--loop through each database and get the info
WHILE @@FETCH_STATUS = 0
BEGIN
	
	--PRINT 'DB: ' + CONVERT(varchar(200), DB_NAME(@DatabaseId));
	SET @TSQL = 'DBCC LOGINFO('+CONVERT(varchar(12), @DatabaseId)+') WITH TABLERESULTS, NO_INFOMSGS;';

	IF ( @majorVer >= 11 )
	BEGIN
		DELETE FROM @tblVLFs2012;
		INSERT INTO @tblVLFs2012
		EXEC(@TSQL);
		INSERT INTO @tblAllDBs 
		SELECT DB_NAME(@DatabaseId)
			, FileId
			, FileSize
			, StartOffset
			, FSeqNo
			, Status
			, Parity
			, CreateLSN 
		FROM @tblVLFs2012;
	END
	ELSE
	BEGIN
		DELETE FROM @tblVLFs;
		INSERT INTO @tblVLFs 
		EXEC(@TSQL);
		INSERT INTO @tblAllDBs 
		SELECT DB_NAME(@DatabaseId)
			, FileId
			, FileSize
			, StartOffset
			, FSeqNo
			, Status
			, Parity
			, CreateLSN 
		FROM @tblVLFs;
	END

	FETCH NEXT FROM cur_DBs INTO @DatabaseId
END
CLOSE cur_DBs;
DEALLOCATE cur_DBs;

--Return the data based on what we have found
SELECT a.DBName
	, COUNT(a.FileId) AS [TotalVLFs]
	, MAX(b.[ActiveVLFs]) AS [ActiveVLFs]
	, (SUM(a.FileSize) / COUNT(a.FileId) / 1024) AS [AvgFileSizeKb]
FROM @tblAllDBs a
INNER JOIN (
	SELECT DBName
		, COUNT(FileId) [ActiveVLFs]
	FROM @tblAllDBs 
	WHERE Status = 2
	GROUP BY DBName
	) b
	ON b.DBName = a.DBName
GROUP BY a.DBName
HAVING COUNT(a.FileId) > 1000
ORDER BY TotalVLFs DESC;


SET NOCOUNT OFF;

