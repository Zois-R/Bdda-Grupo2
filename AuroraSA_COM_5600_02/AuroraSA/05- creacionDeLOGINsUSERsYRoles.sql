/************************************************************
 *                                                          *
 *                      BASE DE DATOS APLICADA             *
 *                                                          *
 *   INTEGRANTES:                                           *
 *      - Edilberto Guzman                                  *
 *      - Zois Andres Uziel Ruggiero Bellone                *
 *      - Karen Anabella Bursa                              *
 *      - Jonathan Ivan Aranda Robles                       *
 *                                                          *
 *   NRO. DE ENTREGA: 5                                     *
 *   FECHA DE ENTREGA: 15/11/2024                           *
 *                                                          *
 *   CONSIGNA:                                              *
 *   Cuando un cliente reclama la devolución de un producto *
 *   se genera una nota de crédito por el valor del         *
 *   producto o un producto del mismo tipo. En el caso de   *
 *   que el cliente solicite la nota de crédito, solo los   *
 *   Supervisores tienen el permiso para generarla. Tener   *
 *   en cuenta que la nota de crédito debe estar asociada a *
 *   una Factura con estado pagada. Asigne los roles        *
 *   correspondientes para poder cumplir con este           *
 *   requisito.                                             *
 *                                                          *
 *   Por otra parte, se requiere que los datos de los       *
 *   empleados se encuentren encriptados, dado que los      *
 *   mismos contienen información personal.                 *
 *                                                          *
 *   La información de las ventas es de vital importancia   *
 *   para el negocio, por ello se requiere que se           *
 *   establezcan políticas de respaldo tanto en las ventas  *
 *   diarias generadas como en los reportes generados.      *
 *                                                          *
 *   Plantee una política de respaldo adecuada para cumplir *
 *   con este requisito y justifique la misma.              *
 *                                                          *
 *   LO QUE HICIMOS EN ESTE SCRIPT:                         *
 *   Creamos los login de cajeros, supervisores y gerentes. *
 *   Creamos los roles y les otorgamos los permisos         *
 *   correspondientes, los cuales eran pedidos en la        *
 *   consigna utilizando nuestro criterio para que tenga    *
 *   sentido y para el correcto funcionamiento de la BDD.   *
 *                                                          *
 ************************************************************/


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


GRANT EXECUTE ON TYPE::ventas.TipoProductosDetalle TO cajero;
GO

GRANT SELECT ON catalogo.vista_Producto_Resumen  TO cajero;
go

GRANT EXECUTE ON ventas.generar_venta_con_factura TO cajero;
go

GRANT EXECUTE ON ventas.mostrar_ventas_por_cajero TO cajero;
go

GRANT EXECUTE ON ventas.borrado_logico_factura TO cajero;
go

GRANT EXECUTE ON ventas.borrado_logico_detalle_de_venta TO cajero;
go



CREATE ROLE supervisor AUTHORIZATION DBA;
go

GRANT EXECUTE ON ventas.insertarNotaDeCredito TO supervisor;
go

GRANT SELECT ON ventas.vista_de_notas_de_credito TO supervisor;
go

GRANT EXECUTE ON ventas.mostrar_factura_segun_supervisor TO supervisor;
go








CREATE ROLE gerente AUTHORIZATION DBA;
go

GRANT EXECUTE ON ventas.TotalFacturadoPorDiaSemana TO gerente;
go

GRANT EXECUTE ON ventas.reporte_trimestral_facturacion TO gerente;
go

GRANT EXECUTE ON ventas.reporte_producto_vendido_rango_fecha TO gerente;
go

GRANT EXECUTE ON ventas.reporte_producto_vendido_rango_fecha_sucursal TO gerente;
go

GRANT EXECUTE ON ventas.reporte_productos_mas_vendidos_por_semana TO gerente;
go

GRANT EXECUTE ON ventas.reporte_productos_menos_vendidos_mes TO gerente;
go

GRANT EXECUTE ON ventas.reporte_total_acumulado_ventas TO gerente;
go

GRANT EXECUTE ON supermercado.mostrarEmpleadosDesencriptados TO gerente;
go

GRANT EXECUTE ON ventas.generar_reporte_ventas_xml TO gerente;
go

GRANT SELECT ON ventas.reporte_de_ventas TO gerente;
go

GRANT SELECT ON ventas.vista_de_notas_de_credito TO gerente;
go

GRANT SELECT ON ventas.vista_de_registros_de_ventas TO gerente;
go






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


--Asignamos los usuarios a los roles

ALTER ROLE cajero ADD MEMBER cajero1;
go
ALTER ROLE cajero ADD MEMBER cajero2;
go
ALTER ROLE cajero ADD MEMBER cajero3;
go
ALTER ROLE cajero ADD MEMBER cajero4;
go
ALTER ROLE cajero ADD MEMBER cajero5;
go
ALTER ROLE cajero ADD MEMBER cajero6;
go
ALTER ROLE supervisor ADD MEMBER supervisor1;
go
ALTER ROLE supervisor ADD MEMBER supervisor2;
go
ALTER ROLE supervisor ADD MEMBER supervisor3;
go
ALTER ROLE supervisor ADD MEMBER supervisor4;
go
ALTER ROLE supervisor ADD MEMBER supervisor5;
go
ALTER ROLE supervisor ADD MEMBER supervisor6;
go
ALTER ROLE gerente ADD MEMBER gerente1;
go
ALTER ROLE gerente ADD MEMBER gerente2;
go
ALTER ROLE gerente ADD MEMBER gerente3;
go
