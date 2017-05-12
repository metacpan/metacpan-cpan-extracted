USE master
go
IF db_id('udtref') IS NOT NULL
   DROP DATABASE udtref
go
CREATE DATABASE udtref
go
USE udtref
go
CREATE ASSEMBLY OlleComplexInteger FROM 'c:\test\udttest\ComplexInteger.dll'
CREATE TYPE OlleComplexInteger EXTERNAL NAME OlleComplexInteger.[OlleDBtest.OlleComplexInteger]
go
CREATE ASSEMBLY OllePoint FROM 'c:\test\udttest\Point.dll'
CREATE TYPE OllePoint EXTERNAL NAME OllePoint.[OlleDBtest.OllePoint]
go
CREATE ASSEMBLY OlleString FROM 'c:\test\udttest\Utf8string.dll'
CREATE TYPE OlleString EXTERNAL NAME OlleString.[OlleDBtest.OlleString]
go
-- This fails on SQL 2005, since this is a large UDT.
CREATE ASSEMBLY OlleStringMax FROM 'c:\test\udttest\Utf8stringmax.dll'
CREATE TYPE OlleStringMax EXTERNAL NAME OlleStringMax.[OlleDBtest.OlleString]
go
SELECT * FROM sys.assemblies
SELECT * FROM sys.assembly_files
SELECT * FROM sys.assembly_types
