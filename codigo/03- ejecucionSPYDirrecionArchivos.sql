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
select * from ventas.factura 
go
select * from ventas.detalleVenta
go
select * from ventas.registro_de_ventas
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