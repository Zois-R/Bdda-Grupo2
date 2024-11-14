USE master;
GO


-- Crear el LOGIN 'DBA' en el servidor con una contraseña "ridícula"
CREATE LOGIN DBA  
WITH PASSWORD = 'WhySoSerious?!', 
     CHECK_EXPIRATION = OFF, 
     CHECK_POLICY = OFF;

--- en propiedades, voy a seguridad, y coloco la opcion de SQL SERVER AND WINDOWA AUTHENTICATION MODE

-- Asignar el rol 'sysadmin' al LOGIN 'DBA'
ALTER SERVER ROLE sysadmin ADD MEMBER DBA;



--- login y password
--- se crean a nivel instancia, se guarda en master
--- son credenciales de acceso
CREATE LOGIN FranciscoLUCENA  
	WITH PASSWORD = 'I_am_1nvisible'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, -- Desactiva la expiración de la contraseña, significa que nunca expirará.
	CHECK_POLICY = OFF -- Desactiva la política de contraseñas de Windows para el login en SQL Server 
						-- requisitos de complejidad (longitud mínima, combinación de caracteres, NO poder ser similar a la anterior, etc.).
GO

CREATE LOGIN EduardoLUNA  
	WITH PASSWORD = 'NoOneWillGuessThisOne'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, -- Desactiva la expiración de la contraseña, significa que nunca expirará.
	CHECK_POLICY = OFF -- Desactiva la política de contraseñas de Windows para el login en SQL Server 
						-- requisitos de complejidad (longitud mínima, combinación de caracteres, NO poder ser similar a la anterior, etc.).
GO

CREATE LOGIN MauroLUNA 
	WITH PASSWORD = 'PasswordNotFound'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, -- Desactiva la expiración de la contraseña, significa que nunca expirará.
	CHECK_POLICY = OFF -- Desactiva la política de contraseñas de Windows para el login en SQL Server 
						-- requisitos de complejidad (longitud mínima, combinación de caracteres, NO poder ser similar a la anterior, etc.).
GO
		
CREATE LOGIN EmilceMAIDANA 
	WITH PASSWORD = 'MyDogAteMyPassword'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, -- Desactiva la expiración de la contraseña, significa que nunca expirará.
	CHECK_POLICY = OFF -- Desactiva la política de contraseñas de Windows para el login en SQL Server 
						-- requisitos de complejidad (longitud mínima, combinación de caracteres, NO poder ser similar a la anterior, etc.).
GO
		
CREATE LOGIN GISELAMAIDANA 
	WITH PASSWORD = 'IAmTheChosenOne'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, -- Desactiva la expiración de la contraseña, significa que nunca expirará.
	CHECK_POLICY = OFF -- Desactiva la política de contraseñas de Windows para el login en SQL Server 
						-- requisitos de complejidad (longitud mínima, combinación de caracteres, NO poder ser similar a la anterior, etc.).
GO		

CREATE LOGIN FernandaMAIZARES 
	WITH PASSWORD = 'InsertCoinToContinue'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, -- Desactiva la expiración de la contraseña, significa que nunca expirará.
	CHECK_POLICY = OFF -- Desactiva la política de contraseñas de Windows para el login en SQL Server 
						-- requisitos de complejidad (longitud mínima, combinación de caracteres, NO poder ser similar a la anterior, etc.).
GO
	

use COM5600G02;
go

-- Crear el USUARIO 'DBA' en la base de datos actual
CREATE USER DBA FOR LOGIN DBA;


--- usuario se crea nivel db, da el acceso solo a esa db
--- dentro de la carpeta security estan user, roles y schemas
CREATE USER FranciscoLUCENA -- drop user supervisor
FOR LOGIN FranciscoLUCENA
WITH DEFAULT_SCHEMA = ventas 
go
--- si no le doy un schema default, le asigna dbo
--- si hubiera 2 tablas del mismo nombre en ambos schemas y no especifico el schema al que quiero acceder, 
--- cuando intente acceder a una tabla por medio de un select, va a acceder al de dbo

CREATE USER EduardoLUNA -- drop user supervisor
FOR LOGIN EduardoLUNA
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER MauroLUNA -- drop user supervisor
FOR LOGIN MauroLUNA
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER EmilceMAIDANA -- drop user supervisor
FOR LOGIN EmilceMAIDANA
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER GISELAMAIDANA -- drop user supervisor
FOR LOGIN GISELAMAIDANA
WITH DEFAULT_SCHEMA = ventas 
go


CREATE USER FernandaMAIZARES -- drop user supervisor
FOR LOGIN FernandaMAIZARES
WITH DEFAULT_SCHEMA = ventas 
go


--- los roles de base de datos se asignan a usuarios
-- Crear el rol 'supervisor' en la base de datos y asignar la propiedad al usuario 'DBA' (usuario de la db del tp)

CREATE ROLE supervisor AUTHORIZATION DBA;
go
-- tiene el permiso para realizar ciertas tareas administrativas en ese rol, como:

-- Añadir o quitar miembros del rol.
-- Cambiar los permisos asignados al rol.
-- Cambiar la propiedad del rol.

	

GRANT SELECT ON ventas.vista_factura_detalle TO supervisor;
go

SELECT * FROM ventas.vista_factura_detalle;
go



GRANT EXECUTE ON ventas.insertarNotaDeCredito TO supervisor;
go

GRANT SELECT ON ventas.notasDeCredito TO supervisor;
go

select * from ventas.notasDeCredito
go
select * from catalogo.producto
go

EXEC ventas.insertarNotaDeCredito
    @idFactura = 1,
    @idProducto = 5495,
    @razon = 'devProd';--- 'devPago', 'devProd'
go



ALTER TABLE supermercado.empleado
ADD usuario VARCHAR(50);
GO


CREATE OR ALTER PROCEDURE supermercado.sp_insertarUsuario
    @legajo INT,
    @usuario VARCHAR(50)
AS
BEGIN
    -- Verificar si el empleado existe
    IF NOT EXISTS (SELECT 1 FROM supermercado.empleado WHERE legajo = @legajo AND activo = 1)
    BEGIN
        PRINT 'Empleado no encontrado o inactivo';
        RETURN;
    END

    -- Insertar el nombre de usuario en el campo 'usuario'
    UPDATE supermercado.empleado
    SET usuario = @usuario
    WHERE legajo = @legajo;

    PRINT 'Nombre de usuario insertado exitosamente';
END;
GO


/*
sp_addrolemember es un procedimiento almacenado en SQL Server que se usa para agregar 
un usuario o grupo de usuarios a un rol específico dentro de la base de datos. 
Cuando se ejecuta, concede permisos y privilegios a un usuario basados en el rol especificado. 
Esto es especialmente útil para asignar permisos de seguridad 
sin tener que configurarlos manualmente para cada usuario.

Ejemplo de uso de sp_addrolemember:

EXEC sp_addrolemember 'nombre_rol', 'nombre_usuario';
'nombre_rol': Es el rol al cual se desea agregar el usuario (por ejemplo, cajero, supervisor, db_datareader, etc.).
'nombre_usuario': Es el nombre del usuario que se quiere añadir a ese rol.
*/


CREATE OR ALTER PROCEDURE supermercado.sp_asignarRol
    @legajo INT,
    @usuario VARCHAR(50)
AS
BEGIN
    -- Verificar si el empleado existe
    IF NOT EXISTS (SELECT 1 FROM supermercado.empleado WHERE legajo = @legajo AND activo = 1)
    BEGIN
        PRINT 'Empleado no encontrado o inactivo';
        RETURN;
    END

    -- Variable para almacenar el cargo del empleado
    DECLARE @cargo VARCHAR(20);

    -- Obtener el cargo del empleado
    SELECT @cargo = cargo
    FROM supermercado.empleado
    WHERE legajo = @legajo;

    -- Verificar y asignar el rol según el cargo
    IF @cargo = 'Cajero'
    BEGIN
        -- Asignar rol 'cajero' al usuario
        EXEC sp_addrolemember 'cajero', @usuario;
        PRINT 'Rol cajero asignado';
    END
    ELSE IF @cargo = 'Supervisor'
    BEGIN
        -- Asignar rol 'supervisor' al usuario
        EXEC sp_addrolemember 'supervisor', @usuario;
        PRINT 'Rol supervisor asignado';
    END
    ELSE IF @cargo = 'Gerente de sucursal'
    BEGIN
        -- Asignar rol 'gerente' al usuario
        EXEC sp_addrolemember 'gerente', @usuario;
        PRINT 'Rol gerente asignado';
    END
    ELSE
    BEGIN
        PRINT 'Cargo no válido para asignación de rol';
        RETURN;
    END

    -- Actualizar el campo 'usuario' en la tabla 'empleado' con el nombre de usuario
    UPDATE supermercado.empleado
    SET usuario = @usuario
    WHERE legajo = @legajo;

    PRINT 'Usuario asignado exitosamente';
END;
GO



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







USE master;
GO

 
CREATE LOGIN OscarORTIZ  
	WITH PASSWORD = 'IAmNotARobot123'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, -- Desactiva la expiración de la contraseña, significa que nunca expirará.
	CHECK_POLICY = OFF -- Desactiva la política de contraseñas de Windows para el login en SQL Server 
						-- requisitos de complejidad (longitud mínima, combinación de caracteres, NO poder ser similar a la anterior, etc.).
GO


CREATE LOGIN DeboraPACHTMAN  
	WITH PASSWORD = 'ItsaTrap123!'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, -- Desactiva la expiración de la contraseña, significa que nunca expirará.
	CHECK_POLICY = OFF -- Desactiva la política de contraseñas de Windows para el login en SQL Server 
						-- requisitos de complejidad (longitud mínima, combinación de caracteres, NO poder ser similar a la anterior, etc.).
GO


CREATE LOGIN RominaPADILLA  
	WITH PASSWORD = 'NoMorePasswords!'
	, DEFAULT_DATABASE = COM5600G02,
	CHECK_EXPIRATION = OFF, -- Desactiva la expiración de la contraseña, significa que nunca expirará.
	CHECK_POLICY = OFF -- Desactiva la política de contraseñas de Windows para el login en SQL Server 
						-- requisitos de complejidad (longitud mínima, combinación de caracteres, NO poder ser similar a la anterior, etc.).
GO


use COM5600G02;
go
--- usuario se crea nivel db, da el acceso solo a esa db
--- dentro de la carpeta security estan user, roles y schemas
CREATE USER OscarORTIZ -- drop user supervisor
FOR LOGIN OscarORTIZ
WITH DEFAULT_SCHEMA = ventas 
go

CREATE USER DeboraPACHTMAN -- drop user supervisor
FOR LOGIN DeboraPACHTMAN
WITH DEFAULT_SCHEMA = ventas 
go

CREATE USER RominaPADILLA  -- drop user supervisor
FOR LOGIN RominaPADILLA 
WITH DEFAULT_SCHEMA = ventas 
go


CREATE ROLE gerente AUTHORIZATION DBA;
go
-- tiene el permiso para realizar ciertas tareas administrativas en ese rol, como:

-- Añadir o quitar miembros del rol.
-- Cambiar los permisos asignados al rol.
-- Cambiar la propiedad del rol.




-- select * from ventas.factura


GRANT EXECUTE ON ventas.TotalFacturadoPorDiaSemana TO gerente;
go

EXEC ventas.TotalFacturadoPorDiaSemana @mes = 1, @anio = 2019;
go




GRANT EXECUTE ON ventas.reporte_trimestral_facturacion TO gerente;
go
 
EXEC ventas.reporte_trimestral_facturacion @Trimestre = 1, @Anio = 2019;
go





GRANT EXECUTE ON ventas.reporte_producto_vendido_rango_fecha TO gerente;
go

EXEC ventas.reporte_producto_vendido_rango_fecha @FechaIni = '2019-02-15', @FechaFinal = '2019-02-20';
go






GRANT EXECUTE ON ventas.reporte_producto_vendido_rango_fecha_sucursal TO gerente;
go

EXEC ventas.reporte_producto_vendido_rango_fecha_sucursal @FechaIni = '2019-02-15', @FechaFinal = '2019-02-20';
go







GRANT EXECUTE ON ventas.reporte_productos_mas_vendidos_por_semana TO gerente;
go

exec ventas.reporte_productos_mas_vendidos_por_semana 1, 2019;
go




GRANT EXECUTE ON ventas.reporte_productos_menos_vendidos_mes TO gerente;
go

exec ventas.reporte_productos_menos_vendidos_mes 1, 2019;
go






GRANT EXECUTE ON ventas.reporte_total_acumulado_ventas TO gerente;
go

exec ventas.reporte_total_acumulado_ventas '2019-02-15', 2;
go






GRANT EXECUTE ON supermercado.mostrarEmpleadosDesencriptados TO gerente;
go

EXEC supermercado.mostrarEmpleadosDesencriptados 
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.', 
    @idSucursalGerente = 1, 
    @idEmpleado = 257034;
go






GRANT SELECT ON ventas.reporte_de_ventas TO gerente;
go
	
SELECT * FROM ventas.reporte_de_ventas
go




ALTER ROLE gerente ADD MEMBER OscarORTIZ;
go
ALTER ROLE gerente ADD MEMBER DeboraPACHTMAN;
go
ALTER ROLE gerente ADD MEMBER RominaPADILLA;
go

