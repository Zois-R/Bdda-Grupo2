/*
Para llamar a la API desde SQL necesitamos habilitar permisos para que se pueda 
trabajar con instancias de OLE (Ole Automation Procedures)
Tenemos que ejecutar procedures para habilitarlos una sola vez
Al comienzo de la creación de tablas
*/

EXEC sp_configure 'show advanced options',1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures',1;
RECONFIGURE;



exec obtenerPrecioDolar
CREATE OR ALTER PROCEDURE obtenerPrecioDolar
AS
BEGIN
DECLARE @WinHttpObject Int;
DECLARE @ResponseJsonText  Varchar(8000);

Exec sp_OACreate 'WinHttp.WinHttpRequest.5.1', @WinHttpObject OUT;

Exec sp_OAMethod @WinHttpObject, 'open', NULL, 'get', 'https://dolarapi.com/v1/dolares/blue'

Exec sp_OAMethod @WinHttpObject, 'send'

Exec sp_OAMethod @WinHttpObject, 'responseText', @ResponseJsonText OUTPUT

Exec sp_OADestroy @WinHttpObject

IF ISJSON(@ResponseJsonText)=1
BEGIN
	select * from OPENJSON( @ResponseJsonText );
END
END;





