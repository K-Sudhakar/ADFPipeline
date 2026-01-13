# Azure Data Factory Metadata-Driven Backup & Restore (SQL Server ⇄ Parquet)

This guide outlines how to configure **two ADF pipelines**—one for **backup to Parquet** and one for **restore from Parquet**—using a **parameterized connection string** and a **metadata-driven table list**.

## 1) Linked Service (SQL Server) with Parameterized Connection String

1. Create a **Linked Service** for SQL Server (on-prem) using a **Self-hosted Integration Runtime**.
2. Add a parameter to the linked service named `SqlConnectionString`.
3. Set the connection string field to `@{linkedService().SqlConnectionString}`.
4. At runtime, pass the connection string from the pipeline (or from a global parameter).

**Example (Linked Service JSON snippet):**
```json
{
  "name": "LS_OnPremSql",
  "properties": {
    "type": "SqlServer",
    "parameters": {
      "SqlConnectionString": {
        "type": "String"
      }
    },
    "typeProperties": {
      "connectionString": "@{linkedService().SqlConnectionString}"
    },
    "connectVia": {
      "referenceName": "SelfHostedIR",
      "type": "IntegrationRuntimeReference"
    }
  }
}
```

## 2) Metadata-Driven Table Configuration

Use a **control table** in SQL Server (or a config file in Blob) to drive which tables are backed up and restored. A control table keeps the configuration near the source system.

**Example control table:**
```sql
CREATE TABLE dbo.AdfBackupConfig (
  TableSchema   sysname NOT NULL,
  TableName     sysname NOT NULL,
  BackupEnabled bit     NOT NULL,
  RestoreEnabled bit    NOT NULL,
  TargetFolder  nvarchar(256) NOT NULL
);
```

**Sample rows:**
```sql
INSERT INTO dbo.AdfBackupConfig
(TableSchema, TableName, BackupEnabled, RestoreEnabled, TargetFolder)
VALUES
('dbo', 'Customers', 1, 1, 'sql-backup/customers'),
('dbo', 'Orders',    1, 0, 'sql-backup/orders');
```

## 3) Datasets

### 3.1 SQL Server Dataset

* Parameterize `schemaName` and `tableName`.
* Use a dataset referencing `LS_OnPremSql`.

**Example dataset parameters:**
```json
"parameters": {
  "schemaName": { "type": "String" },
  "tableName":  { "type": "String" }
}
```

**Table reference:**
```json
"tableName": "@{dataset().schemaName}.@{dataset().tableName}"
```

### 3.2 Parquet Dataset (Azure Blob)

* Use a **Delimited/Parquet** dataset pointing to Blob.
* Parameterize `folderPath` and `fileName`.

Example: `folderPath = @dataset().folderPath`, `fileName = @dataset().fileName`.

## 4) Backup Pipeline (SQL Server → Parquet on Blob)

**Pipeline parameters:**
* `SqlConnectionString` (string)

**Activities:**

1. **Lookup** (or **Script**) activity to read config:
   ```sql
   SELECT TableSchema, TableName, TargetFolder
   FROM dbo.AdfBackupConfig
   WHERE BackupEnabled = 1;
   ```
2. **ForEach** over the lookup output.
3. **Copy Data** activity inside the ForEach:
   * **Source**: SQL Server dataset with parameters:
     * `schemaName = @item().TableSchema`
     * `tableName  = @item().TableName`
   * **Sink**: Parquet dataset:
     * `folderPath = @item().TargetFolder`
     * `fileName = @{concat(item().TableSchema, '_', item().TableName, '.parquet')}`
   * **Format**: Parquet (sink).

**Pipeline parameter usage:**
* In pipeline, pass `SqlConnectionString` to the linked service reference:
  `@{pipeline().parameters.SqlConnectionString}`.

## 5) Restore Pipeline (Parquet on Blob → SQL Server)

**Pipeline parameters:**
* `SqlConnectionString` (string)

**Activities:**

1. **Lookup** (or **Script**) activity to read config:
   ```sql
   SELECT TableSchema, TableName, TargetFolder
   FROM dbo.AdfBackupConfig
   WHERE RestoreEnabled = 1;
   ```
2. **ForEach** over the lookup output.
3. **Copy Data** activity inside the ForEach:
   * **Source**: Parquet dataset:
     * `folderPath = @item().TargetFolder`
     * `fileName = @{concat(item().TableSchema, '_', item().TableName, '.parquet')}`
   * **Sink**: SQL Server dataset:
     * `schemaName = @item().TableSchema`
     * `tableName  = @item().TableName`
   * **Write behavior**: choose **Upsert** or **Truncate + Insert** based on requirements.

## 6) End-to-End Flow Summary

1. **Store table list** in `dbo.AdfBackupConfig` (or Blob config file).
2. **Backup pipeline** uses Lookup → ForEach → Copy to Parquet.
3. **Restore pipeline** uses Lookup → ForEach → Copy to SQL Server.
4. Both pipelines pass **parameterized connection string** to the SQL linked service.

## 7) Operational Tips

* Consider **schema drift**: ensure columns in Parquet match SQL table schema.
* Add **validation** activities (e.g., row count checks) after copy.
* Secure the connection string via **Key Vault** and pass it as a parameter.
