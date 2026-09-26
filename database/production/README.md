# Scripts para `db_WebDevUMG`

No se ha ejecutado ningun script en la base compartida.

1. Configurar el backend con `DB_DATABASE=db_WebDevUMG` y `DB_TABLE_PREFIX=Keily_Subasta_` en el entorno de produccion.
2. Ejecutar primero `01-preflight-readonly.sql` y revisar los resultados.
3. Solo despues de autorizacion, ejecutar `02-create-tables.sql`, `03-create-indexes.sql`, `04-create-procedures.sql` y `05-seed-demo.sql`, en ese orden.

Los scripts se limitan a objetos `dbo.Keily_Subasta_*`; no contienen `DROP`, `ALTER`, `DELETE`, `UPDATE` ni `TRUNCATE`.
