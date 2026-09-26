/* Read-only inspection. Do not run any creation script until results are reviewed. */
USE db_WebDevUMG;
GO
SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME LIKE 'Keily_Subasta_%' ORDER BY TABLE_SCHEMA, TABLE_NAME;
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE 'Keily_Subasta_%' ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;
SELECT s.name AS SchemaName, t.name AS TableName, c.name AS ColumnName FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.columns c ON c.object_id=t.object_id WHERE t.name LIKE 'Keily_Subasta_%' ORDER BY s.name, t.name, c.column_id;
SELECT s.name AS SchemaName, t.name AS TableName, i.name AS IndexName FROM sys.indexes i JOIN sys.tables t ON t.object_id=i.object_id JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.name LIKE 'Keily_Subasta_%' AND i.name IS NOT NULL ORDER BY s.name, t.name, i.name;
SELECT fk.name AS ForeignKeyName, OBJECT_SCHEMA_NAME(fk.parent_object_id) AS SchemaName, OBJECT_NAME(fk.parent_object_id) AS TableName FROM sys.foreign_keys fk WHERE OBJECT_NAME(fk.parent_object_id) LIKE 'Keily_Subasta_%' ORDER BY fk.name;
SELECT SCHEMA_NAME(schema_id) AS SchemaName, name FROM sys.procedures WHERE name LIKE 'Keily_Subasta_%' ORDER BY SchemaName, name;
GO
