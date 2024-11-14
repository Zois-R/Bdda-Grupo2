use COM5600G02 
go

-- insertar registro en tabla de la empresa
EXEC supermercado.insertarComercio 
    @cuit = '20-12345678-9',
    @nombre_comercio = 'Aurora',
    @razon_social = 'Aurora S.A.',
    @email = 'contacto@aurora.com.ar';
go

--ingresar el destino del archivo de imformacion complementaria.xlsx
EXEC supermercado.importarSucursal 'C:\importar\Informacion_complementaria.xlsx';
GO
select * from supermercado.sucursal;
GO
select * from registros.bitácora
go

--archivo de imformacion complementaria.xlsx
EXEC supermercado.importarEmpleados 'C:\importar\Informacion_complementaria.xlsx', 'La vida es como la RAM, todo es temporal y nada se queda.';
GO
select * from supermercado.empleado;
go
select * from registros.bitácora
go


--archivo de imformacion complementaria.xlsx
EXEC catalogo.importarLinea_de_producto 'C:\importar\Informacion_complementaria.xlsx';
GO
EXEC catalogo.insertarLinea_de_producto 'Importados', 'productos_importados';
GO
EXEC catalogo.insertarLinea_de_producto 'Accesorios', 'Electronic_accessories';
go
select * from catalogo.linea_de_producto;
go
select * from registros.bitácora
go



--archivo de catalogo.csv
exec catalogo.importarCatalogo 'C:\importar\catalogo.csv';
GO
--archivo de productos importados.xlsx
exec catalogo.importarProductosImportados 'C:\importar\Productos_importados.xlsx';
GO
--archivo de electronico acesories.xlsx
exec catalogo.importarAccesorios 'C:\importar\Electronic accessories.xlsx';
GO

select * from catalogo.producto
go
select * from registros.bitácora
go

--archivo de imformacion complementaria.xlsx
EXEC ventas.importarMedios_de_Pago 'C:\importar\informacion_complementaria.xlsx';
GO
select * from ventas.mediosDePago
go
select * from registros.bitácora
go

--archivo de ventas registradas.csv
EXEC ventas.importarVentas_registradas 'C:\importar\ventas_registradas.csv';
go
select * from ventas.factura --- 750-67-8428    815,816
go
select * from ventas.detalleVenta
WHERE idFactura IN (815,816)
go
select * from ventas.registro_de_ventas
WHERE idFactura IN (815,816);
go
select * from ventas.cliente
go
select * from registros.bitácora
go


--archivo de clientes.csv
EXEC ventas.importar_clientes 'C:\importar\DatosClientes.csv';
go
select * from ventas.cliente
go
select * from registros.bitácora
go

--- testing
-- Primero, declaramos la tabla de tipo `TipoProductosDetalle` con los productos a insertar
DECLARE @productosDetalle ventas.TipoProductosDetalle;

-- Insertamos productos de prueba en la tabla de tipo
INSERT INTO @productosDetalle (idProducto, idLineaProducto, precio, cantidad)
VALUES
    (1, 101, 100.00, 2),  -- Producto 1, Línea 101, Precio 100.00, Cantidad 2
    (2, 102, 50.00, 3),   -- Producto 2, Línea 102, Precio 50.00, Cantidad 3
    (3, 103, 30.00, 5);   -- Producto 3, Línea 103, Precio 30.00, Cantidad 5

-- Ahora, llamamos al procedimiento almacenado `ventas.generar_venta_con_factura` con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '12345678901',    -- Número de factura de ejemplo
    @tipoFactura = 'A',             -- Tipo de factura (A o B, dependiendo de la configuración)
    @fecha = '2024-11-13',          -- Fecha de la venta
    @hora = '14:30:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago (puede ser un ID válido de la tabla mediosDePago)
    @idPago = 'PAGO123456',         -- ID del pago (número de transacción o similar)
    @idEmpleado = 257020,              -- ID del empleado (debe ser un ID válido de la tabla empleados)
    @idSucursal = 3,                -- ID de la sucursal (debe ser un ID válido de la tabla sucursal)
    @tipoCliente = 'Normal',       -- Tipo de cliente (ejemplo: 'Regular', 'Nuevo', etc.)
    @genero = 'Male',          -- Género del cliente
    @cuil = '20-12345678-9',        -- CUIL del cliente (dato ficticio)
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go








-------------------------revisar los datos 
select * from ventas.ventasProductosNoRegistrados;
go

----esta tabla ayuda porque despues de cambiar los caracteres  raros en nombre de producto
----no coincidieron productos que venian con esos caracteres raros en sus nombres en ventas registradas
----estos tipos de problema por futuros nombres de producto que se escriban incorrectamente 
---- son los que justifican que se deje esta tabla como auxiliar de registros extraños entre otras anormalidades posibles



/*
select * 
from catalogo.producto 
where nombre like '%Ã³%';-- 6530, 6535
go
UPDATE catalogo.producto
SET nombre = REPLACE(nombre, 'Ã³', 'ó')
WHERE nombre LIKE '%Ã³%';
go

SELECT *
FROM catalogo.producto
WHERE nombre LIKE N'%Ãº%';--- 5688
go
UPDATE catalogo.producto
SET nombre = REPLACE(nombre, N'Ãº', 'u')
WHERE nombre LIKE N'%Ãº%';
go

SELECT *
FROM catalogo.producto
WHERE nombre LIKE N'%Ã¡%';--- 1196
go
UPDATE catalogo.producto
SET nombre = REPLACE(nombre, N'Ã¡', 'á')
WHERE nombre LIKE N'%Ã¡%';
go

SELECT *
FROM catalogo.producto
WHERE nombre LIKE N'%Ã±%';--- 5157
go
UPDATE catalogo.producto
SET nombre = REPLACE(nombre, N'Ã±', 'ñ')
WHERE nombre LIKE N'%Ã±%';
go

SELECT *
FROM catalogo.producto
WHERE nombre LIKE N'%単%';-- 6531, 6532, 6533, 6534
go
UPDATE catalogo.producto
SET nombre = REPLACE(nombre, N'単', 'ñ')
WHERE nombre LIKE N'%単%';
go
*/