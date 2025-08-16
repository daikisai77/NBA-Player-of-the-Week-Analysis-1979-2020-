/*============================================================================
  File:     DaikiSaiFinalProjectNBAPOTW.sql

  Summary:  Creates the NBAPOTW (NBA Player of the Week) database. This
  Database is a collection of all the NBA Player of the Weeks from 1979-2020
============================================================================*/

--Create NBAPOTW database

:setvar SqlSamplesSourceDataPath "C:\Data\NBAPOTW\DaikiSaiFinalProjectNBAPOTW.sql"

:setvar DatabaseName "NBAPOTW"


IF '$(SqlSamplesSourceDataPath)' IS NULL OR '$(SqlSamplesSourceDataPath)' = ''
BEGIN
	RAISERROR(N'The variable SqlSamplesSourceDataPath must be defined.', 16, 127) WITH NOWAIT
	RETURN
END;

/* Execute the script
 */

IF '$(SqlSamplesSourceDataPath)' IS NULL OR '$(SqlSamplesSourceDataPath)' = ''
BEGIN
	RAISERROR(N'The variable SqlSamplesSourceDataPath must be defined.', 16, 127) WITH NOWAIT
	RETURN
END;


SET NOCOUNT OFF;
GO

PRINT CONVERT(varchar(1000), @@VERSION);
GO

PRINT '';
PRINT 'Started - ' + CONVERT(varchar, GETDATE(), 121);
GO

USE [master];
GO

-- ****************************************
-- Drop Database
-- ****************************************
PRINT '';
PRINT '*** Dropping Database';
GO

IF EXISTS (SELECT [name] FROM [master].[sys].[databases] WHERE [name] = N'$(DatabaseName)')
    DROP DATABASE $(DatabaseName);

-- If the database has any other open connections close the network connection.
IF @@ERROR = 3702 
    RAISERROR('$(DatabaseName) database cannot be dropped because there are still other open connections', 127, 127) WITH NOWAIT, LOG;
GO

-- ****************************************
-- Create Database
-- ****************************************
PRINT '';
PRINT '*** Creating Database';
GO

CREATE DATABASE $(DatabaseName);
GO

PRINT '';
PRINT '*** Checking for $(DatabaseName) Database';
/* CHECK FOR DATABASE IF IT DOESN'T EXISTS, DO NOT RUN THE REST OF THE SCRIPT */
IF NOT EXISTS (SELECT TOP 1 1 FROM sys.databases WHERE name = N'$(DatabaseName)')
BEGIN
PRINT '*******************************************************************************************************************************************************************'
+char(10)+'********$(DatabaseName) Database does not exist.  Make sure that the script is being run in SQLCMD mode and that the variables have been correctly set.*********'
+char(10)+'*******************************************************************************************************************************************************************';
SET NOEXEC ON;
END
GO

ALTER DATABASE $(DatabaseName) 
SET RECOVERY SIMPLE, 
    ANSI_NULLS ON, 
    ANSI_PADDING ON, 
    ANSI_WARNINGS ON, 
    ARITHABORT ON, 
    CONCAT_NULL_YIELDS_NULL ON, 
    QUOTED_IDENTIFIER ON, 
    NUMERIC_ROUNDABORT OFF, 
    PAGE_VERIFY CHECKSUM, 
    ALLOW_SNAPSHOT_ISOLATION OFF;
GO

USE $(DatabaseName);
GO

-- ****************************************
-- Create DDL Trigger for Database
-- ****************************************
PRINT '';
PRINT '*** Creating DDL Trigger for Database';
GO

-- Create table to store database object creation messages
-- *** WARNING:  THIS TABLE IS INTENTIONALLY A HEAP - DO NOT ADD A PRIMARY KEY ***
CREATE TABLE [dbo].[DatabaseLog](
    [DatabaseLogID] [int] IDENTITY (1, 1) NOT NULL,
    [PostTime] [datetime] NOT NULL, 
    [DatabaseUser] [sysname] NOT NULL, 
    [Event] [sysname] NOT NULL, 
    [Schema] [sysname] NULL, 
    [Object] [sysname] NULL, 
    [TSQL] [nvarchar](max) NOT NULL, 
    [XmlEvent] [xml] NOT NULL
) ON [PRIMARY];
GO

CREATE TRIGGER [ddlDatabaseTriggerLog] ON DATABASE 
FOR DDL_DATABASE_LEVEL_EVENTS AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @data XML;
    DECLARE @schema sysname;
    DECLARE @object sysname;
    DECLARE @eventType sysname;

    SET @data = EVENTDATA();
    SET @eventType = @data.value('(/EVENT_INSTANCE/EventType)[1]', 'sysname');
    SET @schema = @data.value('(/EVENT_INSTANCE/SchemaName)[1]', 'sysname');
    SET @object = @data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname') 

    IF @object IS NOT NULL
        PRINT '  ' + @eventType + ' - ' + @schema + '.' + @object;
    ELSE
        PRINT '  ' + @eventType + ' - ' + @schema;

    IF @eventType IS NULL
        PRINT CONVERT(nvarchar(max), @data);

    INSERT [dbo].[DatabaseLog] 
        (
        [PostTime], 
        [DatabaseUser], 
        [Event], 
        [Schema], 
        [Object], 
        [TSQL], 
        [XmlEvent]
        ) 
    VALUES 
        (
        GETDATE(), 
        CONVERT(sysname, CURRENT_USER), 
        @eventType, 
        CONVERT(sysname, @schema), 
        CONVERT(sysname, @object), 
        @data.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'nvarchar(max)'), 
        @data
        );
END;
GO

-- ******************************************************
-- Create tables
-- ******************************************************

PRINT '';
PRINT '*** Creating Tables';
GO

-- Drop NBAPOTWStaging

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NBAPOTWStaging]') AND type in (N'U'))
DROP TABLE [dbo].[NBAPOTWStaging]
GO

-- Create NBAPOTWStaging

CREATE TABLE NBAPOTWStaging
(
	Player varchar(50),
	Team varchar(50),
	Conference varchar(50),
	WeekDate varchar(50),
	Position varchar(25),
	Height varchar(50),
	WeightPounds int,
	Age int,
	DraftYear int,
	SeasonsInLeague int,
	Season varchar(50),
	SeasonShort varchar(50),
	PreDraftTeam varchar(50),
	RealValue float,
	HeightCM int,
	WeightKG int,
	LastSeason int
)


-- Bulk Load NBAPOTWStaging

BULK INSERT NBAPOTWStaging
FROM 'C:\Data\NBAPOTW\NBA_player_of_the_week.csv'
WITH (
    FORMAT = 'CSV', 
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2
);

SELECT * FROM NBAPOTWStaging

--Create NBAPOTWODS Table

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NBAPOTWODS]') AND type in (N'U'))
DROP TABLE [dbo].[NBAPOTWODS]
GO

-- Create NBAPOTWODS

CREATE TABLE NBAPOTWODS
(
	Player varchar(50),
	Team varchar(50),
	Conference varchar(50),
	WeekDate varchar(50),
	Position varchar(25),
	Height varchar(50),
	WeightPounds int,
	Age int,
	DraftYear int,
	SeasonsInLeague int,
	Season varchar(50),
	SeasonShort varchar(50),
	PreDraftTeam varchar(50),
	RealValue float,
	HeightCM int,
	WeightKG int,
	LastSeason int
)

INSERT INTO NBAPOTWODS
	SELECT *
	FROM NBAPOTWStaging

--Fix NBAPOTWODS Table

BEGIN TRAN;

UPDATE NBAPOTWODS
SET WeekDate = CAST(FORMAT(CONVERT(DATE, WeekDate, 109), 'yyyy-MM-dd') AS DATE)
WHERE ISDATE(WeekDate) = 1;

UPDATE NBAPOTWODS
SET Team = CASE
    WHEN Team = 'San Diego Clippers' THEN 'Los Angeles Clippers'
    WHEN Team = 'Kansas City Kings' THEN 'Sacramento Kings'
    WHEN Team = 'Vancouver Grizzlies' THEN 'Memphis Grizzlies'
    WHEN Team = 'New Orleans Hornets' THEN 'Charlotte Hornets'
    WHEN Team = 'Seattle SuperSonics' THEN 'Oklahoma City Thunder'
    WHEN Team = 'New Jersey Nets' THEN 'Brooklyn Nets'
	WHEN Team = 'Washington Bullets' THEN 'Washington Wizards'
	WHEN Team = 'Charlotte Bobcats' THEN 'Charlotte Hornets'
    ELSE Team -- Retain the original team name if no match
END;
Go

UPDATE NBAPOTWODS
SET Conference = CASE
    -- Eastern Conference Teams
    WHEN Team IN ('Boston Celtics', 'Brooklyn Nets', 'New York Knicks', 'Philadelphia Sixers', 'Toronto Raptors',
                  'Chicago Bulls', 'Cleveland Cavaliers', 'Detroit Pistons', 'Indiana Pacers', 'Milwaukee Bucks',
                  'Atlanta Hawks', 'Charlotte Hornets', 'Miami Heat', 'Orlando Magic', 'Washington Wizards')
    THEN 'East'
    
    -- Western Conference Teams
    WHEN Team IN ('Dallas Mavericks', 'Denver Nuggets', 'Golden State Warriors', 'Houston Rockets', 
                  'Los Angeles Clippers', 'Los Angeles Lakers', 'Memphis Grizzlies', 'Minnesota Timberwolves', 
                  'New Orleans Pelicans', 'Oklahoma City Thunder', 'Phoenix Suns', 'Portland Trail Blazers', 
                  'Sacramento Kings', 'San Antonio Spurs', 'Utah Jazz')
    THEN 'West'
    
    ELSE Conference -- Retain original value if no match
END
WHERE Conference IS NULL;

UPDATE NBAPOTWODS
SET Conference = CASE
    -- Charlotte Hornets: Always Eastern Conference
    WHEN Team = 'Charlotte Hornets' THEN 'East'

    -- LA Clippers: Always Western Conference
    WHEN Team = 'Los Angeles Clippers' THEN 'West'

    ELSE Conference -- Keep the original conference if already correct
END
WHERE Team IN ('Charlotte Hornets', 'Los Angeles Clippers');

COMMIT TRAN;

SELECT *
FROM NBAPOTWODS


-- ******************************************************
-- Create dim tables
-- ******************************************************
--Drop All the Tables First

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factNBAPOTW]') AND type in (N'U'))
DROP TABLE [dbo].[factNBAPOTW]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dimPlayer]') AND type in (N'U'))
DROP TABLE [dbo].[dimPlayer]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dimTeam]') AND type in (N'U'))
DROP TABLE [dbo].[dimTeam]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dimConference]') AND type in (N'U'))
DROP TABLE [dbo].[dimConference]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimDate') AND type in (N'U'))
DROP TABLE dimDate
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dimPosition]') AND type in (N'U'))
DROP TABLE [dbo].[dimPosition]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dimAge]') AND type in (N'U'))
DROP TABLE [dbo].[dimAge]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dimDraftYear]') AND type in (N'U'))
DROP TABLE [dbo].[dimDraftYear]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dimSeason]') AND type in (N'U'))
DROP TABLE [dbo].[dimSeason]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dimSeasonShort]') AND type in (N'U'))
DROP TABLE [dbo].[dimSeasonShort]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dimPreDraftTeam]') AND type in (N'U'))
DROP TABLE [dbo].[dimPreDraftTeam]
GO
--	dimPlayer

CREATE TABLE dimPlayer(
	PlayerID int IDENTITY(1,1) NOT NULL,
		CONSTRAINT PK_dimPlayer_PlayerID PRIMARY KEY CLUSTERED (PlayerID),
	PlayerDesc varchar(50) NOT NULL,
)
INSERT INTO dimPlayer
	SELECT DISTINCT Player
	FROM NBAPOTWODS
	ORDER BY Player
Go

SELECT *
FROM dimPlayer

-- dimConference

CREATE TABLE dimConference(
	ConferenceID int IDENTITY(1,1) NOT NULL,
		CONSTRAINT PK_dimConference_ConferenceID PRIMARY KEY CLUSTERED (ConferenceID),
	ConferenceDesc varchar(50),
)
INSERT INTO dimConference
	SELECT DISTINCT Conference
	FROM NBAPOTWODS
	ORDER BY Conference
Go

SELECT *
FROM dimConference

--dimTeam

CREATE TABLE dimTeam(
	TeamID int IDENTITY(1,1) NOT NULL,
		CONSTRAINT PK_dimTeam_TeamID PRIMARY KEY CLUSTERED (TeamID),
	TeamDesc varchar(50) NOT NULL,
	ConferenceID INT,
		CONSTRAINT FK_dimConference_dimTeam FOREIGN KEY (ConferenceID)
		REFERENCES dimConference (ConferenceID)
)
Go

INSERT INTO dimTeam
	SELECT DISTINCT Team, 
			Conference =
				CASE
					WHEN Conference = 'East' THEN 1
					WHEN Conference = 'West' THEN 2
				END
	FROM NBAPOTWODS
	ORDER BY Team

SELECT *
FROM dimTeam

--dimDate

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dimDate') AND type in (N'U'))
DROP TABLE dimDate
GO

CREATE TABLE [dbo].[dimDate] (
   [DateID] [int] NOT NULL,
   [TheDate] Date NOT NULL,
   [Day] [tinyint] NOT NULL,
   [DaySuffix] [char](2) NOT NULL,
   [Weekday] [tinyint] NOT NULL,
   [WeekDayName] [varchar](10) NOT NULL,
   [WeekDayName_Short] [char](3) NOT NULL,
   [WeekDayName_FirstLetter] [char](1) NOT NULL,
   [DOWInMonth] [tinyint] NOT NULL,
   [DayOfYear] [smallint] NOT NULL,
   [WeekOfMonth] [tinyint] NOT NULL,
   [WeekOfYear] [tinyint] NOT NULL,
   [Month] [tinyint] NOT NULL,
   [MonthName] [varchar](10) NOT NULL,
   [MonthName_Short] [char](3) NOT NULL,
   [MonthName_FirstLetter] [char](1) NOT NULL,
   [Quarter] [tinyint] NOT NULL,
   [QuarterName] [varchar](6) NOT NULL,
   [Year] [int] NOT NULL,
   [MMYYYY] [char](6) NOT NULL,
   [MonthYear] [char](7) NOT NULL,
   IsWeekend BIT NOT NULL,
   IsHoliday BIT NOT NULL,
   HolidayName VARCHAR(20) NULL,
   SpecialDays VARCHAR(20) NULL,
   [FinancialYear] [int] NULL,
   [FinancialQuater] [int] NULL,
   [FinancialMonth] [int] NULL,
   [FirstDateofYear] DATE NULL,
   [LastDateofYear] DATE NULL,
   [FirstDateofQuater] DATE NULL,
   [LastDateofQuater] DATE NULL,
   [FirstDateofMonth] DATE NULL,
   [LastDateofMonth] DATE NULL,
   [FirstDateofWeek] DATE NULL,
   [LastDateofWeek] DATE NULL,
   CurrentYear SMALLINT NULL,
   CurrentQuater SMALLINT NULL,
   CurrentMonth SMALLINT NULL,
   CurrentWeek SMALLINT NULL,
   CurrentDay SMALLINT NULL,
   PRIMARY KEY CLUSTERED ([DateID] ASC)
   )

SET NOCOUNT ON

TRUNCATE TABLE dimDate

DECLARE @CurrentDate DATE = '1979/10/21'  -- DON'T FORGET TO CHANGE THIS
DECLARE @EndDate DATE = '2020/03/10'

WHILE @CurrentDate < @EndDate
BEGIN
   INSERT INTO [dbo].[dimDate] (
      [DateID],
      [TheDate],
      [Day],
      [DaySuffix],
      [Weekday],
      [WeekDayName],
      [WeekDayName_Short],
      [WeekDayName_FirstLetter],
      [DOWInMonth],
      [DayOfYear],
      [WeekOfMonth],
      [WeekOfYear],
      [Month],
      [MonthName],
      [MonthName_Short],
      [MonthName_FirstLetter],
      [Quarter],
      [QuarterName],
      [Year],
      [MMYYYY],
      [MonthYear],
      [IsWeekend],
      [IsHoliday],
      [FirstDateofYear],
      [LastDateofYear],
      [FirstDateofQuater],
      [LastDateofQuater],
      [FirstDateofMonth],
      [LastDateofMonth],
      [FirstDateofWeek],
      [LastDateofWeek]
      )
   SELECT DateID = YEAR(@CurrentDate) * 10000 + MONTH(@CurrentDate) * 100 + DAY(@CurrentDate),
      TheDATE = @CurrentDate,
      Day = DAY(@CurrentDate),
      [DaySuffix] = CASE 
         WHEN DAY(@CurrentDate) = 1
            OR DAY(@CurrentDate) = 21
            OR DAY(@CurrentDate) = 31
            THEN 'st'
         WHEN DAY(@CurrentDate) = 2
            OR DAY(@CurrentDate) = 22
            THEN 'nd'
         WHEN DAY(@CurrentDate) = 3
            OR DAY(@CurrentDate) = 23
            THEN 'rd'
         ELSE 'th'
         END,
      WEEKDAY = DATEPART(dw, @CurrentDate),
      WeekDayName = DATENAME(dw, @CurrentDate),
      WeekDayName_Short = UPPER(LEFT(DATENAME(dw, @CurrentDate), 3)),
      WeekDayName_FirstLetter = LEFT(DATENAME(dw, @CurrentDate), 1),
      [DOWInMonth] = DAY(@CurrentDate),
      [DayOfYear] = DATENAME(dy, @CurrentDate),
      [WeekOfMonth] = DATEPART(WEEK, @CurrentDate) - DATEPART(WEEK, DATEADD(MM, DATEDIFF(MM, 0, @CurrentDate), 0)) + 1,
      [WeekOfYear] = DATEPART(wk, @CurrentDate),
      [Month] = MONTH(@CurrentDate),
      [MonthName] = DATENAME(mm, @CurrentDate),
      [MonthName_Short] = UPPER(LEFT(DATENAME(mm, @CurrentDate), 3)),
      [MonthName_FirstLetter] = LEFT(DATENAME(mm, @CurrentDate), 1),
      [Quarter] = DATEPART(q, @CurrentDate),
      [QuarterName] = CASE 
         WHEN DATENAME(qq, @CurrentDate) = 1
            THEN 'First'
         WHEN DATENAME(qq, @CurrentDate) = 2
            THEN 'second'
         WHEN DATENAME(qq, @CurrentDate) = 3
            THEN 'third'
         WHEN DATENAME(qq, @CurrentDate) = 4
            THEN 'fourth'
         END,
      [Year] = YEAR(@CurrentDate),
      [MMYYYY] = RIGHT('0' + CAST(MONTH(@CurrentDate) AS VARCHAR(2)), 2) + CAST(YEAR(@CurrentDate) AS VARCHAR(4)),
      [MonthYear] = CAST(YEAR(@CurrentDate) AS VARCHAR(4)) + UPPER(LEFT(DATENAME(mm, @CurrentDate), 3)),
      [IsWeekend] = CASE 
         WHEN DATENAME(dw, @CurrentDate) = 'Sunday'
            OR DATENAME(dw, @CurrentDate) = 'Saturday'
            THEN 1
         ELSE 0
         END,
      [IsHoliday] = 0,
      [FirstDateofYear] = CAST(CAST(YEAR(@CurrentDate) AS VARCHAR(4)) + '-01-01' AS DATE),
      [LastDateofYear] = CAST(CAST(YEAR(@CurrentDate) AS VARCHAR(4)) + '-12-31' AS DATE),
      [FirstDateofQuater] = DATEADD(qq, DATEDIFF(qq, 0, GETDATE()), 0),
      [LastDateofQuater] = DATEADD(dd, - 1, DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) + 1, 0)),
      [FirstDateofMonth] = CAST(CAST(YEAR(@CurrentDate) AS VARCHAR(4)) + '-' + CAST(MONTH(@CurrentDate) AS VARCHAR(2)) + '-01' AS DATE),
      [LastDateofMonth] = EOMONTH(@CurrentDate),
      [FirstDateofWeek] = DATEADD(dd, - (DATEPART(dw, @CurrentDate) - 1), @CurrentDate),
      [LastDateofWeek] = DATEADD(dd, 7 - (DATEPART(dw, @CurrentDate)), @CurrentDate)

   SET @CurrentDate = DATEADD(DD, 1, @CurrentDate)
END

--Update Holiday information
UPDATE dimDate
SET [IsHoliday] = 1,
   [HolidayName] = 'Christmas'
WHERE [Month] = 12
   AND [DAY] = 25

UPDATE dimDate
SET SpecialDays = 'Valentines Day'
WHERE [Month] = 2
   AND [DAY] = 14

--Update current date information
UPDATE dimDate
SET CurrentYear = DATEDIFF(yy, GETDATE(), TheDATE),
   CurrentQuater = DATEDIFF(q, GETDATE(), TheDATE),
   CurrentMonth = DATEDIFF(m, GETDATE(), TheDATE),
   CurrentWeek = DATEDIFF(ww, GETDATE(), TheDATE),
   CurrentDay = DATEDIFF(dd, GETDATE(), TheDATE)


   select *
   from dimDate


--dimPosition


CREATE TABLE dimPosition(
	PositionID int IDENTITY(1,1) NOT NULL,
		CONSTRAINT PK_dimPosition_PositionID PRIMARY KEY CLUSTERED (PositionID),
	PositionDesc varchar(50) NOT NULL,
)
INSERT INTO dimPosition
	SELECT DISTINCT Position
	FROM NBAPOTWODS
	ORDER BY Position

SELECT *
FROM dimPosition

--dimAge

CREATE TABLE dimAge(
	AgeID int IDENTITY(1,1) NOT NULL,
		CONSTRAINT PK_dimAge_AgeID PRIMARY KEY CLUSTERED (AgeID),
	AgeDesc varchar(50) NOT NULL,
)
INSERT INTO dimAge
	SELECT DISTINCT Age
	FROM NBAPOTWODS
	ORDER BY Age

SELECT *
FROM dimAge

--dimDraftYear

CREATE TABLE dimDraftYear(
	DraftYearID int IDENTITY(1,1) NOT NULL,
		CONSTRAINT PK_dimDraftYear_DraftYearID PRIMARY KEY CLUSTERED (DraftYearID),
	DraftYearDesc varchar(50) NOT NULL,
)
INSERT INTO dimDraftYear
	SELECT DISTINCT DraftYear
	FROM NBAPOTWODS
	ORDER BY DraftYear

SELECT *
FROM dimDraftYear

--dimSeason

CREATE TABLE dimSeason(
	SeasonID int IDENTITY(1,1) NOT NULL,
		CONSTRAINT PK_dimSeason_SeasonID PRIMARY KEY CLUSTERED (SeasonID),
	SeasonDesc varchar(50) NOT NULL,
)
INSERT INTO dimSeason
	SELECT DISTINCT Season
	FROM NBAPOTWODS
	ORDER BY Season

SELECT *
FROM dimSeason

--dimSeasonShort

CREATE TABLE dimSeasonShort(
	SeasonShortID int IDENTITY(1,1) NOT NULL,
		CONSTRAINT PK_dimSeasonShort_SeasonShortID PRIMARY KEY CLUSTERED (SeasonShortID),
	SeasonShortDesc varchar(50) NOT NULL,
)
INSERT INTO dimSeasonShort
	SELECT DISTINCT SeasonShort
	FROM NBAPOTWODS
	ORDER BY SeasonShort

SELECT *
FROM dimSeasonShort

--dimPreDraftTeam

CREATE TABLE dimPreDraftTeam(
	PreDraftTeamID int IDENTITY(1,1) NOT NULL,
		CONSTRAINT PK_dimPreDraftTeam_PreDraftTeamID PRIMARY KEY CLUSTERED (PreDraftTeamID),
	PreDraftTeamDesc varchar(50) NOT NULL,
)
INSERT INTO dimPreDraftTeam
	SELECT DISTINCT PreDraftTeam
	FROM NBAPOTWODS
	ORDER BY PreDraftTeam

SELECT *
FROM dimPreDraftTeam


--Create Fact Table
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[factNBAPOTW]') AND type in (N'U'))
DROP TABLE [dbo].[factNBAPOTW]
GO

CREATE TABLE [dbo].[factNBAPOTW](
	NBAPOTWID int IDENTITY(1,1) NOT NULL,
		CONSTRAINT PK_factNBAPOTW_NBAPOTWID PRIMARY KEY CLUSTERED (NBAPOTWID),
	PlayerID int,
		CONSTRAINT FK_dimPlayer_factNBAPOTW FOREIGN KEY (PlayerID)
		REFERENCES dimPlayer (PlayerID),
	ConferenceID int NOT NULL
		CONSTRAINT FK_dimConference_factNBAPOTW FOREIGN KEY (ConferenceID)
		REFERENCES dimConference (ConferenceID),
	TeamID int NOT NULL
		CONSTRAINT FK_dimTeam_factNBAPOTW FOREIGN KEY (TeamID)
		REFERENCES dimTeam (TeamID),
	DateID int NOT NULL
		CONSTRAINT FK_dimDate_factNBAPOTW FOREIGN KEY (DateID)
		REFERENCES dimDate (DateID),
	PositionID int NOT NULL
		CONSTRAINT FK_dimPosition_factNBAPOTW FOREIGN KEY (PositionID)
		REFERENCES dimPosition (PositionID),
	AgeID int NOT NULL
		CONSTRAINT FK_dimAge_factNBAPOTW FOREIGN KEY (AgeID)
		REFERENCES dimAge (AgeID),
	DraftYearID int NOT NULL
		CONSTRAINT FK_dimDraftYear_factNBAPOTW FOREIGN KEY (DraftYearID)
		REFERENCES dimDraftYear (DraftYearID),
	SeasonID int NOT NULL
		CONSTRAINT FK_dimSeason_factNBAPOTW FOREIGN KEY (SeasonID)
		REFERENCES dimSeason (SeasonID),
	SeasonShortID int NOT NULL
		CONSTRAINT FK_dimSeasonShort_factNBAPOTW FOREIGN KEY (SeasonShortID)
		REFERENCES dimSeasonShort (SeasonShortID),
	PreDraftTeamID int NOT NULL
		CONSTRAINT FK_dimPreDraftTeam_factNBAPOTW FOREIGN KEY (PreDraftTeamID)
		REFERENCES dimPreDraftTeam (PreDraftTeamID)
)
GO


INSERT INTO [dbo].[factNBAPOTW] (
    PlayerID,
    ConferenceID,
    TeamID,
    DateID,
    PositionID,
    AgeID,
    DraftYearID,
    SeasonID,
    SeasonShortID,
    PreDraftTeamID
)
SELECT
    dp.PlayerID, -- Player foreign key
    dc.ConferenceID, -- Conference foreign key
    dt.TeamID, -- Team foreign key
    dd.DateID, -- Date foreign key
    dpos.PositionID, -- Position foreign key
    da.AgeID, -- Age foreign key
    ddy.DraftYearID, -- Draft Year foreign key
    ds.SeasonID, -- Season foreign key
    dss.SeasonShortID, -- Season Short foreign key
    ddt.PreDraftTeamID -- Draft Team foreign key
FROM NBAPOTWODS s
LEFT JOIN dimPlayer dp ON s.Player = dp.PlayerDesc
LEFT JOIN dimConference dc ON s.Conference = dc.ConferenceDesc
LEFT JOIN dimTeam dt ON s.Team = dt.TeamDesc
LEFT JOIN dimDate dd ON s.WeekDate = dd.TheDate
LEFT JOIN dimPosition dpos ON s.Position = dpos.PositionDesc
LEFT JOIN dimAge da ON s.Age = da.AgeDesc
LEFT JOIN dimDraftYear ddy ON s.DraftYear = ddy.DraftYearDesc
LEFT JOIN dimSeason ds ON s.Season = ds.SeasonDesc
LEFT JOIN dimSeasonShort dss ON s.SeasonShort = dss.SeasonShortDesc
LEFT JOIN dimPreDraftTeam ddt ON s.PreDraftTeam = ddt.PreDraftTeamDesc;


SELECT *
FROM factNBAPOTW

