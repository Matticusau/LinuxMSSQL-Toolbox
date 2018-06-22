------------------------------
-- Monitor DB Free Space
-- Author:	MLavery
-- Date:	22/06/2018
-- Purpose: Provides the details of the free space of a database
--          Based on the script https://github.com/Matticusau/sqlops-mssql-db-insights/blob/Dev/src/sql/mssql-db-spaceused-detail.sql
--
-- When		Who			What
-- 
------------------------------
--

SET NOCOUNT ON;

-- declare variables required
DECLARE @majorVer SMALLINT, @minorVer SMALLINT, @build SMALLINT
DECLARE @DatabaseId INT;
DECLARE @DatabaseName SYSNAME;
DECLARE @TSQL varchar(MAX);
DECLARE cur_DBs CURSOR FOR
	SELECT database_id, name FROM sys.databases WHERE database_id > 4;
OPEN cur_DBs;
FETCH NEXT FROM cur_DBs INTO @DatabaseId, @DatabaseName

-- Get the version
SELECT @majorVer = (@@microsoftversion / 0x1000000) & 0xff, @minorVer = (@@microsoftversion / 0x10000) & 0xff, @build = @@microsoftversion & 0xffff

DECLARE @tblDBSpace Table (
	DBName sysname
	, file_id int
	, file_name nvarchar(128)
	, type_desc nvarchar(60)
	, physical_name nvarchar(260)
	, file_size_mb decimal(18,2)
	, max_growth_size_mb decimal(18,2)
	, used_space_mb decimal(18,2)
	, free_space_mb decimal(19,2)
	, used_space_percent decimal(18,2)
	, free_space_percent decimal(19,2)
);

--loop through each database and get the info
WHILE @@FETCH_STATUS = 0
BEGIN
	
	--PRINT 'DB: ' + CONVERT(varchar(200), DB_NAME(@DatabaseId));
	SET @TSQL = 'USE ['+@DatabaseName+']; 
	SELECT DB_NAME()
		, file_id
		, name [file_name]
		, type_desc
		, physical_name
		, CONVERT(decimal(18,2), size/128.0) [file_size_mb]
		, CONVERT(decimal(18,2), max_size/128.0) [max_growth_size_mb]
		, CONVERT(decimal(18,2), FILEPROPERTY(name, ''SpaceUsed'')/128.0) [used_space_mb]
		, CONVERT(decimal(18,2), size/128.0) - CONVERT(decimal(18,2), FILEPROPERTY(name,''SpaceUsed'')/128.0) AS [free_space_mb] 
		, CONVERT(decimal(18,2), (FILEPROPERTY(name, ''SpaceUsed'')/128.0) / (size/128.0) * 100) [used_space_percent]
		, 100 - CONVERT(decimal(18,2), (FILEPROPERTY(name, ''SpaceUsed'')/128.0) / (size/128.0) * 100) AS [free_space_percent] 
	FROM sys.database_files
	WHERE type_desc IN (''ROWS'',''LOG'')
	ORDER BY type_desc
    	, file_id;';
	--PRINT (@TSQL);

	INSERT INTO @tblDBSpace
	EXEC(@TSQL);

	FETCH NEXT FROM cur_DBs INTO @DatabaseId, @DatabaseName
END
CLOSE cur_DBs;
DEALLOCATE cur_DBs;

--Return the data based on what we have found
SELECT DBName
	, file_id
	, file_name
	, type_desc
	, physical_name
	, file_size_mb
	, max_growth_size_mb
	, used_space_mb
	, free_space_mb
	, used_space_percent
	, free_space_percent
FROM @tblDBSpace
ORDER BY DBName, type_desc, file_id;

SET NOCOUNT OFF;

