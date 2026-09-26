/* Execute this script only when a new local database is authorized. */
USE master;
GO

IF DB_ID(N'SubastasVehiculosDB') IS NULL
BEGIN
    CREATE DATABASE SubastasVehiculosDB;
    PRINT 'Database SubastasVehiculosDB created.';
END
ELSE
BEGIN
    PRINT 'Database SubastasVehiculosDB already exists. No changes made.';
END
GO
