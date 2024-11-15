--------------------------------------------------------------------------------------------------------
-- CREACION DE LOGINs
--------------------------------------------------------------------------------------------------------


USE master;
GO


CREATE LOGIN DBA  
WITH PASSWORD = 'WhySoSerious?!', 
     CHECK_EXPIRATION = OFF, 
     CHECK_POLICY = OFF;

--- en propiedades, voy a seguridad, y coloco la opcion de SQL SERVER AND WINDOWA AUTHENTICATION MODE


ALTER SERVER ROLE sysadmin ADD MEMBER DBA;


--------------------------------
-- LOGINs DE CAJEROS
--------------------------------
--- login y password
--- se crean a nivel instancia, se guarda en master
--- son credenciales de acceso


CREATE LOGIN cajero1  
	WITH PASSWORD = 'CaracolRapido999'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO

CREATE LOGIN cajero2  
	WITH PASSWORD = 'TortugaTurbo27'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF
GO

CREATE LOGIN cajero3 
	WITH PASSWORD = 'CorchoLoco99'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO
		
CREATE LOGIN cajero4 
	WITH PASSWORD = 'chinchudo91'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO
		
CREATE LOGIN cajero5 
	WITH PASSWORD = 'soyUnRobot?'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF,
	CHECK_POLICY = OFF 
GO		

CREATE LOGIN cajero6 
	WITH PASSWORD = 'vacaNinja47'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF
GO
	

--------------------------------
-- LOGINs DE SUPERVISORES
--------------------------------


CREATE LOGIN supervisor1  
	WITH PASSWORD = 'I_am_1nvisible'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO

CREATE LOGIN supervisor2 
	WITH PASSWORD = 'NoOneWillGuessThisOne'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO

CREATE LOGIN supervisor3
	WITH PASSWORD = 'PasswordNotFound'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO
		
CREATE LOGIN supervisor4
	WITH PASSWORD = 'MyDogAteMyPassword'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO
		
CREATE LOGIN supervisor5
	WITH PASSWORD = 'IAmTheChosenOne'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO		

CREATE LOGIN supervisor6
	WITH PASSWORD = 'InsertCoinToContinue'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO



--------------------------------
-- LOGINs DE GERENTE
--------------------------------

CREATE LOGIN gerente1   
	WITH PASSWORD = 'IAmNotARobot123'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO


CREATE LOGIN gerente2  
	WITH PASSWORD = 'ItsaTrap123!'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO


CREATE LOGIN gerente3   
	WITH PASSWORD = 'NoMorePasswords!'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, 
	CHECK_POLICY = OFF 
GO





--------------------------------------------------------------------------------------------------------
-- CREACION DE USERs
--------------------------------------------------------------------------------------------------------

-- Crear el USUARIO 'DBA' en la base de datos actual

use COM5600G02;
go

CREATE USER DBA FOR LOGIN DBA;
go
--------------------------------
-- USERs DE CAJEROS
--------------------------------

--- usuario se crea nivel db, da el acceso solo a esa db
--- dentro de la carpeta security estan user, roles y schemas
CREATE USER cajero1 
FOR LOGIN cajero1
WITH DEFAULT_SCHEMA = ventas 
go
--- si no le doy un schema default, le asigna dbo
--- si hubiera 2 tablas del mismo nombre en ambos schemas y no especifico el schema al que quiero acceder, 
--- cuando intente acceder a una tabla por medio de un select, va a acceder al de dbo

CREATE USER cajero2 
FOR LOGIN cajero2
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER cajero3
FOR LOGIN cajero3
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER cajero4 
FOR LOGIN cajero4
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER cajero5
FOR LOGIN cajero5
WITH DEFAULT_SCHEMA = ventas 
go

CREATE USER cajero6
FOR LOGIN cajero6
WITH DEFAULT_SCHEMA = ventas 
go



--------------------------------
-- USERs DE SUPERVISORES
--------------------------------

CREATE USER supervisor1 
FOR LOGIN supervisor1 
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER supervisor2 
FOR LOGIN supervisor2
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER supervisor3 
FOR LOGIN supervisor3
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER supervisor4 
FOR LOGIN supervisor4
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER supervisor5 
FOR LOGIN supervisor5
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER supervisor6 
FOR LOGIN supervisor6
WITH DEFAULT_SCHEMA = ventas 
go



--------------------------------
-- USERs DE GERENTE
--------------------------------

CREATE USER gerente1 
FOR LOGIN gerente1
WITH DEFAULT_SCHEMA = ventas 
go

CREATE USER gerente2
FOR LOGIN gerente2
WITH DEFAULT_SCHEMA = ventas 
go

CREATE USER gerente3 
FOR LOGIN gerente3
WITH DEFAULT_SCHEMA = ventas 
go





--------------------------------------------------------------------------------------------------------
-- CREACION DE ROLES Y OTORGAMIENTO DE PERMISOS
--------------------------------------------------------------------------------------------------------

CREATE ROLE cajero AUTHORIZATION DBA;
go


GRANT EXECUTE ON ventas.vista_de_registros_de_ventas TO cajero;
go
--SELECT * FROM ventas.vista_de_registros_de_ventas;

GRANT EXECUTE ON ventas.generar_venta_con_factura TO cajero;
go

---poner prueba aqui o en otro scritp de testing





CREATE ROLE supervisor AUTHORIZATION DBA;
go


GRANT SELECT ON ventas.vista_de_registros_de_ventas TO supervisor;
go

-- select * from ventas.notasDeCredito

-- select * from catalogo.producto

--EXEC ventas.insertarNotaDeCredito @idFactura = 1, @idProducto = 5495, @razon = 'devProd';--- 'devPago', 'devProd'
--go


GRANT EXECUTE ON ventas.insertarNotaDeCredito TO supervisor;
go

GRANT SELECT ON ventas.vista_de_notas_de_credito TO supervisor;
go









CREATE ROLE gerente AUTHORIZATION DBA;
go


-- select * from ventas.factura


GRANT EXECUTE ON ventas.TotalFacturadoPorDiaSemana TO gerente;
go
/*
EXEC ventas.TotalFacturadoPorDiaSemana @mes = 1, @anio = 2019;
go
*/



GRANT EXECUTE ON ventas.reporte_trimestral_facturacion TO gerente;
go
 /*
EXEC ventas.reporte_trimestral_facturacion @Trimestre = 1, @Anio = 2019;
go

*/



GRANT EXECUTE ON ventas.reporte_producto_vendido_rango_fecha TO gerente;
go
/*
EXEC ventas.reporte_producto_vendido_rango_fecha @FechaIni = '2019-02-15', @FechaFinal = '2019-02-20';
go
*/





GRANT EXECUTE ON ventas.reporte_producto_vendido_rango_fecha_sucursal TO gerente;
go
/*
EXEC ventas.reporte_producto_vendido_rango_fecha_sucursal @FechaIni = '2019-02-15', @FechaFinal = '2019-02-20';
go
*/






GRANT EXECUTE ON ventas.reporte_productos_mas_vendidos_por_semana TO gerente;
go
/*
exec ventas.reporte_productos_mas_vendidos_por_semana 1, 2019;
go
*/



GRANT EXECUTE ON ventas.reporte_productos_menos_vendidos_mes TO gerente;
go
/*
exec ventas.reporte_productos_menos_vendidos_mes 1, 2019;
go

*/




GRANT EXECUTE ON ventas.reporte_total_acumulado_ventas TO gerente;
go
/*
exec ventas.reporte_total_acumulado_ventas '2019-02-15', 2;
go
*/





GRANT EXECUTE ON supermercado.mostrarEmpleadosDesencriptados TO gerente;
go
/*
EXEC supermercado.mostrarEmpleadosDesencriptados 
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.', 
    @idSucursalGerente = 1, 
    @idEmpleado = 257034;
go


*/



GRANT SELECT ON ventas.reporte_de_ventas TO gerente;
go
	/*
SELECT * FROM ventas.reporte_de_ventas
go
*/

GRANT SELECT ON ventas.vista_de_notas_de_credito TO gerente;
go



GRANT SELECT ON ventas.vista_de_registros_de_ventas TO gerente;
go









ALTER TABLE supermercado.empleado
ADD usuario VARCHAR(50);
GO


exec supermercado.insertarUsuario 257020, cajero1
go
exec supermercado.insertarUsuario 257021, cajero2
go
exec supermercado.insertarUsuario 257022, cajero3
go
exec supermercado.insertarUsuario 257023, cajero4
go
exec supermercado.insertarUsuario 257024, cajero5
go
exec supermercado.insertarUsuario 257025, cajero6
go
exec supermercado.insertarUsuario 257026, supervisor1
go
exec supermercado.insertarUsuario 257027, supervisor2
go
exec supermercado.insertarUsuario 257028, supervisor3
go
exec supermercado.insertarUsuario 257029, supervisor4
go
exec supermercado.insertarUsuario 257030, supervisor5
go
exec supermercado.insertarUsuario 257031, supervisor6
go
exec supermercado.insertarUsuario 257032, gerente1
go
exec supermercado.insertarUsuario 257033, gerente2
go
exec supermercado.insertarUsuario 257034, gerente3
go

--select * from supermercado.empleado



exec supermercado.asignarRol 257020
go
exec supermercado.asignarRol 257021
go
exec supermercado.asignarRol 257022
go
exec supermercado.asignarRol 257023
go
exec supermercado.asignarRol 257024
go
exec supermercado.asignarRol 257025
go
exec supermercado.asignarRol 257026
go
exec supermercado.asignarRol 257027
go
exec supermercado.asignarRol 257028
go
exec supermercado.asignarRol 257029
go
exec supermercado.asignarRol 257030
go
exec supermercado.asignarRol 257031
go
exec supermercado.asignarRol 257032
go
exec supermercado.asignarRol 257033
go
exec supermercado.asignarRol 257034
go





/*
ALTER ROLE supervisor ADD MEMBER FranciscoLUCENA;
go
ALTER ROLE supervisor ADD MEMBER EduardoLUNA;
go
ALTER ROLE supervisor ADD MEMBER MauroLUNA;
go
ALTER ROLE supervisor ADD MEMBER EmilceMAIDANA;
go
ALTER ROLE supervisor ADD MEMBER GISELAMAIDANA;
go
ALTER ROLE supervisor ADD MEMBER FernandaMAIZARES;
go
*/
