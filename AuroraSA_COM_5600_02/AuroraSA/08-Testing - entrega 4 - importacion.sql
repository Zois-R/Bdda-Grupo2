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
 *   NRO. DE ENTREGA: 4                                     *
 *   FECHA DE ENTREGA: 15/11/2024                           *
 *                                                          *
 *   TESTING                                                *
 *                                                          *
 *   LO QUE HICIMOS EN ESTE SCRIPT:                         *
 *                                                          *
 *   ingresamos nuevos archivos maestros y verificamos si   *
 *   actualizan y insertan los nuevos datos a nuestras      *
 *   tablas de la base de dato                              *
 *                                                          *
 ************************************************************/

use COM5600G02;

---------------------------------------------------------------------
--TEST DE INSERCION DE NUEVOS REGISTROS DE ARCHIVOS
---------------------------------------------------------------------
-- se espera que que importe los clientes 
EXEC ventas.importar_clientes 'C:\importar\nuevosDatos\DatosClientes.csv';
go
select * from ventas.cliente
go
select * from registros.bitácora
go

--nuevas sucursales
EXEC supermercado.importarSucursal 'C:\importar\nuevosDatos\Informacion_complementaria_nuevo.xlsx';
GO
select * from supermercado.sucursal;
GO

--nuevos empleados
EXEC supermercado.importarEmpleados 'C:\importar\nuevosDatos\Informacion_complementaria_nuevo.xlsx', 'La vida es como la RAM, todo es temporal y nada se queda.';
GO
select * from supermercado.empleado;
GO
EXEC supermercado.mostrarEmpleadosDesencriptados 
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.'
GO

--nuevas lines de producto
EXEC catalogo.importarLinea_de_producto 'C:\importar\nuevosDatos\Informacion_complementaria_nuevo.xlsx';
GO
select * from catalogo.linea_de_producto order by id desc;
GO

--nuevos productos en el catologo
exec catalogo.importarCatalogo 'C:\importar\nuevosDatos\catalogo_nuevo.csv';
GO
select * from catalogo.producto order by id desc;
GO
--nuevo productos electronicos
exec catalogo.importarAccesorios 'C:\importar\nuevosDatos\Electronic accessories_nuevo.xlsx';
GO
select * from catalogo.producto order by id desc;
GO

--nuevo productos importados
exec catalogo.importarProductosImportados 'C:\importar\nuevosDatos\Productos_importados_nuevo.xlsx';
GO
select * from catalogo.producto order by id desc;
GO

--nuevas ventas registradas
EXEC ventas.importarVentas_registradas 'C:\importar\nuevosDatos\Ventas_registradas_nuevo.csv';
go

select * from ventas.factura order by id desc;
select * from ventas.detalleVenta order by id desc;
select * from catalogo.producto order by id desc;
select * from ventas.vista_de_registros_de_ventas;

---------------------------------------------------------------------
--TEST DE ACTUALIZACION TABLAS SEGUN ARCHIVO
---------------------------------------------------------------------

--actualiza numero de telefono de nuestra sucursal insertada
EXEC supermercado.importarSucursal 'C:\importar\nuevosDatos\Informacion_complementaria_actualizacion.xlsx';
GO
select * from supermercado.sucursal;
GO

--se actualiza la dirrecion de los empleados
EXEC supermercado.importarEmpleados 'C:\importar\nuevosDatos\Informacion_complementaria_actualizacion.xlsx', 'La vida es como la RAM, todo es temporal y nada se queda.';
GO
select * from supermercado.empleado;
GO
EXEC supermercado.mostrarEmpleadosDesencriptados 
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.'
GO

--se actualiza el precio de 2 productos
exec catalogo.importarCatalogo 'C:\importar\nuevosDatos\catalogo_actualizacion.csv';
GO
select * from catalogo.producto order by id desc;
GO
-- se actualiza el precio del producto del xbox series X
exec catalogo.importarAccesorios 'C:\importar\nuevosDatos\Electronic accessories_actualizacion.xlsx';
GO
select * from catalogo.producto order by id desc;
GO

--se actualiza el precio del producto del Queso Fior di Latte
exec catalogo.importarProductosImportados 'C:\importar\nuevosDatos\Productos_importados_actualizacion.xlsx';
GO
select * from catalogo.producto order by id desc;
GO
