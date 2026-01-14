IF OBJECT_ID('dbo.AdfBackupConfig', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AdfBackupConfig
    (
        ConfigId uniqueidentifier NOT NULL CONSTRAINT DF_AdfBackupConfig_ConfigId DEFAULT NEWID(),
        TableSchema sysname NOT NULL,
        TableName sysname NOT NULL,
        TargetFolder nvarchar(400) NOT NULL,
        BackupEnabled bit NOT NULL CONSTRAINT DF_AdfBackupConfig_BackupEnabled DEFAULT (1),
        DeleteEnabled bit NOT NULL CONSTRAINT DF_AdfBackupConfig_DeleteEnabled DEFAULT (0),
        RestoreEnabled bit NOT NULL CONSTRAINT DF_AdfBackupConfig_RestoreEnabled DEFAULT (0),
        FilterColumn sysname NULL,
        UseDateRange bit NOT NULL CONSTRAINT DF_AdfBackupConfig_UseDateRange DEFAULT (0),
        AllowFullDelete bit NOT NULL CONSTRAINT DF_AdfBackupConfig_AllowFullDelete DEFAULT (0),
        BackupMode nvarchar(20) NULL,
        RestoreMode nvarchar(20) NULL,
        IsSequential bit NULL,
        BatchSize int NULL,
        Enabled bit NULL,
        CONSTRAINT PK_AdfBackupConfig PRIMARY KEY CLUSTERED (ConfigId)
    );

    CREATE UNIQUE INDEX UX_AdfBackupConfig_Table ON dbo.AdfBackupConfig (TableSchema, TableName);
END
ELSE
BEGIN
    IF COL_LENGTH('dbo.AdfBackupConfig', 'ConfigId') IS NULL
    BEGIN
        ALTER TABLE dbo.AdfBackupConfig
        ADD ConfigId uniqueidentifier NOT NULL CONSTRAINT DF_AdfBackupConfig_ConfigId DEFAULT NEWID();
    END

    IF COL_LENGTH('dbo.AdfBackupConfig', 'DeleteEnabled') IS NULL
    BEGIN
        ALTER TABLE dbo.AdfBackupConfig
        ADD DeleteEnabled bit NOT NULL CONSTRAINT DF_AdfBackupConfig_DeleteEnabled DEFAULT (0);
    END

    IF COL_LENGTH('dbo.AdfBackupConfig', 'FilterColumn') IS NULL
    BEGIN
        ALTER TABLE dbo.AdfBackupConfig
        ADD FilterColumn sysname NULL;
    END

    IF COL_LENGTH('dbo.AdfBackupConfig', 'UseDateRange') IS NULL
    BEGIN
        ALTER TABLE dbo.AdfBackupConfig
        ADD UseDateRange bit NOT NULL CONSTRAINT DF_AdfBackupConfig_UseDateRange DEFAULT (0);
    END

    IF COL_LENGTH('dbo.AdfBackupConfig', 'AllowFullDelete') IS NULL
    BEGIN
        ALTER TABLE dbo.AdfBackupConfig
        ADD AllowFullDelete bit NOT NULL CONSTRAINT DF_AdfBackupConfig_AllowFullDelete DEFAULT (0);
    END

    IF COL_LENGTH('dbo.AdfBackupConfig', 'BackupMode') IS NULL
    BEGIN
        ALTER TABLE dbo.AdfBackupConfig
        ADD BackupMode nvarchar(20) NULL;
    END

    IF COL_LENGTH('dbo.AdfBackupConfig', 'RestoreMode') IS NULL
    BEGIN
        ALTER TABLE dbo.AdfBackupConfig
        ADD RestoreMode nvarchar(20) NULL;
    END

    IF COL_LENGTH('dbo.AdfBackupConfig', 'IsSequential') IS NULL
    BEGIN
        ALTER TABLE dbo.AdfBackupConfig
        ADD IsSequential bit NULL;
    END

    IF COL_LENGTH('dbo.AdfBackupConfig', 'BatchSize') IS NULL
    BEGIN
        ALTER TABLE dbo.AdfBackupConfig
        ADD BatchSize int NULL;
    END

    IF COL_LENGTH('dbo.AdfBackupConfig', 'Enabled') IS NULL
    BEGIN
        ALTER TABLE dbo.AdfBackupConfig
        ADD Enabled bit NULL;
    END

    IF NOT EXISTS (
        SELECT 1
        FROM sys.key_constraints
        WHERE [type] = 'PK'
          AND [name] = 'PK_AdfBackupConfig'
          AND [parent_object_id] = OBJECT_ID('dbo.AdfBackupConfig')
    )
    BEGIN
        ALTER TABLE dbo.AdfBackupConfig
        ADD CONSTRAINT PK_AdfBackupConfig PRIMARY KEY CLUSTERED (ConfigId);
    END

    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE [name] = 'UX_AdfBackupConfig_Table'
          AND [object_id] = OBJECT_ID('dbo.AdfBackupConfig')
    )
    BEGIN
        CREATE UNIQUE INDEX UX_AdfBackupConfig_Table ON dbo.AdfBackupConfig (TableSchema, TableName);
    END
END
GO

IF OBJECT_ID('dbo.AdfOrchestrationRunLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AdfOrchestrationRunLog
    (
        RunId uniqueidentifier NOT NULL,
        OrchestrationName nvarchar(200) NOT NULL,
        PipelineName nvarchar(200) NOT NULL,
        StepName nvarchar(50) NOT NULL,
        TableSchema sysname NULL,
        TableName sysname NULL,
        Status nvarchar(50) NOT NULL,
        StartTimeUtc datetime2(7) NULL,
        EndTimeUtc datetime2(7) NULL,
        RangeStartUtc datetime2(7) NULL,
        RangeEndUtc datetime2(7) NULL,
        RowsRead bigint NULL,
        RowsCopied bigint NULL,
        RowsDeleted bigint NULL,
        OutputFile nvarchar(400) NULL,
        ErrorCode nvarchar(200) NULL,
        ErrorMessage nvarchar(max) NULL,
        CorrelationId nvarchar(200) NULL,
        InsertedAtUtc datetime2(7) NOT NULL CONSTRAINT DF_AdfOrchestrationRunLog_InsertedAtUtc DEFAULT SYSUTCDATETIME()
    );

    CREATE INDEX IX_AdfOrchestrationRunLog_Run ON dbo.AdfOrchestrationRunLog (RunId, PipelineName, StepName, Status);
END
GO
