use COM5600G02 
go

--ingresar el destino del archivo de imformacion complementaria.xlsx
EXEC supermercado.importarSucursal 'C:\importar\Informacion_complementaria.xlsx';
GO
select * from supermercado.sucursal;
GO
select * from registros.bitácora
go

--archivo de imformacion complementaria.xlsx
EXEC supermercado.importarEmpleados 'C:\importar\Informacion_complementaria.xlsx';
GO
select * from supermercado.empleado;
go
select * from registros.bitácora
go

--archivo de imformacion complementaria.xlsx
EXEC catalogo.importarLinea_de_producto 'C:\importar\Informacion_complementaria.xlsx';
GO
select * from catalogo.linea_de_producto;
go
select * from registros.bitácora
go

--no cambiar nada aca ejecutar como esta
EXEC catalogo.insertarLinea_de_producto 'Accesorios, Electronic_accessories';
go
EXEC catalogo.insertarLinea_de_producto 'Importados, productos_importados';
GO
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
select * from catalogo.producto where nombre like 'copos%';
go
select * from catalogo.producto where nombre like '%Alcohol%';
go
select * from catalogo.producto where id_linea = 38;
go
select * from catalogo.producto where precio is null;
go
select * from registros.bitácora
go

--archivo de imformacion complementaria.xlsx
EXEC ventas.importarMedios_de_Pago 'C:\importar\informacion_complementaria.xlsx';
GO
select * from ventas.mediosDePago
go

--archivo de ventas registradas.csv
EXEC ventas.importarVentas_registradas 'C:\importar\ventas_registradas.csv';
go
select * from ventas.ventas_registradas;
go

-------------------------revisar los datos 
select * from ventas.ventasProductosNoRegistrados;




