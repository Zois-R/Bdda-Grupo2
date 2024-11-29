/************************************************************
 *                                                          *
 *                      BASE DE DATOS APLICADA              *
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
 *   TESTING                                                *
 *                                                          *
 *   Verificamos los reportes.                              *
 *   Verificamos la correcta encriptación de empleados.     *
 *   Validamos los roles y permisos.                        *
 *                                                          *
 ************************************************************/
/*		--		para habilitar los permisos de la API 
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
*/

use COM5600G02;

---------------------------------------------------------------------
--TEST REPORTES  , entrega 5
---------------------------------------------------------------------
-----------------
EXEC ventas.TotalFacturadoPorDiaSemana @mes = 1, @anio = 2019;
go
-----------------
EXEC ventas.reporte_trimestral_facturacion @Trimestre = 1, @Anio = 2019;
go
-----------------
EXEC ventas.reporte_producto_vendido_rango_fecha @FechaIni = '2019-02-15', @FechaFinal = '2019-02-20';
go
-----------------
EXEC ventas.reporte_producto_vendido_rango_fecha_sucursal @FechaIni = '2019-02-15', @FechaFinal = '2019-02-20';
go
-----------------
exec ventas.reporte_productos_mas_vendidos_por_semana 1, 2019;
go
-----------------
exec ventas.reporte_productos_menos_vendidos_mes 1, 2019;
go

exec ventas.reporte_total_acumulado_ventas '2019-02-15', 2;
go

exec ventas.reporte_total_acumulado_ventas_dado_fecha '2019-02-15', 2;
go
--vista de reporte a futuro
select * from ventas.reporte_de_ventas;
go
--xml de reporte a futuro
exec ventas.generar_reporte_ventas_xml;







---------------------------------------------------------------------
-----------------Testeo de ultimo producto vendido
---------------------------------------------------------------------

---hacer una venta en el dia de hoy, y verficiar que este dentro del rango de fecha entre hoy y ayer
---primero me fijo los productos que hay
select * from catalogo.producto order by id desc;   ---!!!!!OJO PRIMERO VER EL PRODUCTO Y LUEGO PONER LOS DATOS

-- Insertamos productos de prueba en la tabla de tipo
DECLARE @productosDetalle ventas.TipoProductosDetalle;
INSERT INTO @productosDetalle (idProducto, cantidad)
VALUES (6515, 2)	   

-- Ahora, llamamos al procedimiento almacenado ventas.generar_venta_con_factura con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '750-67-8425',    -- Número de factura de ejemplo
    @tipoFactura = 'A',             -- Tipo de factura (A o B, dependiendo de la configuración)
    @fecha = '14/11/2024',          -- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago (puede ser un ID válido de la tabla mediosDePago)
    @idPago = 'PAGO123456',         -- ID del pago (número de transacción o similar)
    @idEmpleado = 257020,              -- ID del empleado (debe ser un ID válido de la tabla empleados)
    @idSucursal = 3,                -- ID de la sucursal (debe ser un ID válido de la tabla sucursal)
    @tipoCliente = 'Normal',       -- Tipo de cliente (ejemplo: 'Regular', 'Nuevo', etc.)
    @genero = 'Male',          -- Género del cliente
    @cuil = '20-12345678-7',        -- CUIL del cliente (dato ficticio)
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go

EXEC ventas.reporte_producto_vendido_rango_fecha @FechaIni = '2024-11-14', @FechaFinal = '2024-11-20';
go






--------------------------------------------------------------------------
--TEST DE SEGURIDAD   entrega 5
--------------------------------------------------------------------------

---------------------------------------------------------------------
-- Incriptacion de los datos de la tabla empleados
---------------------------------------------------------------------

--------------mostrar incriptados de la tabla empleados
select * from supermercado.empleado;
go
--------------mostrar los empleados desencriptados 
EXEC supermercado.mostrarEmpleadosDesencriptados 
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.';
go







---------------------------------------------------------------------
---------------------------------logins , usuarios y roles 
---------------------------------------------------------------------

---------------------------------------------------------------------
-- ventas por parte de un cajero
---------------------------------------------------------------------

use COM5600G02;
go

--------primero ejecutamos con cajero
EXECUTE AS LOGIN = 'cajero1';						
SELECT CURRENT_USER;

----ver lo productos que tengo
select * from catalogo.vista_Producto_Resumen;		--elijo el id de un producto

DECLARE @productosDetalle ventas.TipoProductosDetalle;
INSERT INTO @productosDetalle (idProducto, cantidad)
VALUES (6520, 5)								

-- Ahora, llamamos al procedimiento almacenado ventas.generar_venta_con_factura con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '750-67-2026',    -- Número de factura 
    @tipoFactura = 'A',             -- Tipo de factura
    @fecha = '14/11/2024',          -- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago 
    @idPago = 'PAGO123456',         -- ID del pago
    @idEmpleado = 257020,           -- ID del empleado
    @idSucursal = 3,                -- ID de la sucursal 
    @tipoCliente = 'Normal',		-- Tipo de cliente 
    @genero = 'Male',				-- Género del cliente
    @cuil = '20-12345678-7',        -- CUIL del cliente 
    @productosDetalle = @productosDetalle; 
GO

--muestra todas las ventas de ese cajero
exec ventas.mostrar_ventas_por_cajero 257020;
GO
--borrado logico de venta en caso de arrepentimiento del cliente
exec ventas.borrado_logico_factura 1001;
GO
--si no muestra la venta es que la venta fue cancelada
exec ventas.mostrar_ventas_por_cajero 257020;
GO
REVERT;		



-----------Luego lo probamos con un supervisor , el supervisor no tiene permisos de rol de cajero
EXECUTE AS LOGIN = 'supervisor1';						
SELECT CURRENT_USER;

DECLARE @productosDetalle ventas.TipoProductosDetalle;
INSERT INTO @productosDetalle (idProducto, cantidad)
VALUES (6528, 1)   

-- Ahora, llamamos al procedimiento almacenado ventas.generar_venta_con_factura con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '750-67-8426',    
    @tipoFactura = 'A',             
    @fecha = '14/11/2024',          
    @hora = '13:08:00',            
    @idMedioDePago = 1,             
    @idPago = 'PAGO123456',         
    @idEmpleado = 257020,              
    @idSucursal = 3,               
    @tipoCliente = 'Normal',       
    @genero = 'Male',          
    @cuil = '20-12345678-7',       
    @productosDetalle = @productosDetalle; 
go

exec ventas.mostrar_ventas_por_cajero @legajoEmpleado = 257020;
GO
exec ventas.borrado_logico_factura @id = 1001;
GO
REVERT;		





---------------------------------------------------------------------
-- notas de credito de un supervisor
-- demuestra que solo el supervisor puede hacer las notas de credito 
---------------------------------------------------------------------

-----supervisor
EXECUTE AS LOGIN = 'supervisor1';						
GO
SELECT CURRENT_USER;										
GO
exec ventas.mostrar_factura_segun_supervisor @legajoSupervisor = 257028;
GO
exec ventas.insertarNotaDeCredito @idFactura = 796, @idProducto = 31, @razon = 'devProd';		
GO
select * from ventas.vista_de_notas_de_credito;
GO
REVERT;														



-----este es un gerente , no puede hacer notas de credito, pero puede ver que notas de creditos hay
EXECUTE AS LOGIN = 'gerente1';
GO
SELECT CURRENT_USER;				
GO
exec ventas.mostrar_factura_segun_supervisor @legajoSupervisor = 257028;
GO
exec ventas.insertarNotaDeCredito  @idFactura =  1000, @idProducto = 5196,  @razon = 'devProd';	
GO
select * from ventas.vista_de_notas_de_credito;
GO
REVERT;			




---------------------------------------------------------------------
-- reportes por parte del gerente
---------------------------------------------------------------------

-----este es un gerente
EXECUTE AS LOGIN = 'gerente1';
GO
SELECT CURRENT_USER;
GO
exec ventas.reporte_productos_menos_vendidos_mes 1, 2019;
GO
REVERT;					

-----este es un supervisor
EXECUTE AS LOGIN = 'supervisor1';
GO
SELECT CURRENT_USER;				
GO
exec ventas.reporte_productos_menos_vendidos_mes 1, 2019;
GO
REVERT;		









---------------- ver roles de la DB y usuarios asignados
use COM5600G02;
SELECT    roles.principal_id                            AS RolePrincipalID
    ,    roles.name                                    AS RolePrincipalName
    ,    database_role_members.member_principal_id    AS MemberPrincipalID
    ,    members.name                                AS MemberPrincipalName
FROM sys.database_role_members AS database_role_members  
JOIN sys.database_principals AS roles  
    ON database_role_members.role_principal_id = roles.principal_id  
JOIN sys.database_principals AS members  
    ON database_role_members.member_principal_id = members.principal_id;  
GO

-------- ver permisos dados a los roles 
SELECT
    perms.state_desc AS State,
    permission_name AS [Permission],
    obj.name AS [on Object],
    dp.name AS [to User Name]
FROM sys.database_permissions AS perms
JOIN sys.database_principals AS dp
    ON perms.grantee_principal_id = dp.principal_id
JOIN sys.objects AS obj
    ON perms.major_id = obj.object_id;



-----------la prueba de back-up esta en otro archivo


