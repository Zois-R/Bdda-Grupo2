/************************************************************
 *                                                            *
 *                      BASE DE DATOS APLICADA                *
 *                                                            *
 *   INTEGRANTES:                                             *
 *      - Edilberto Guzman                                    *
 *      - Zois Andres Uziel Ruggiero Bellone                  *
 *      - Karen Anabella Bursa                                *
 *      - Jonathan Ivan Aranda Robles                         *
 *                                                            *
 *   NRO. DE ENTREGA: 4                                       *
 *   FECHA DE ENTREGA: 15/11/2024                             *
 *                                                            *
 *   CONSIGNA:                                                *
 *   Se requiere que importe toda la información antes        *
 *   mencionada a la base de datos:                           *
 *   • Genere los objetos necesarios (store procedures,       *
 *     funciones, etc.) para importar los archivos antes      *
 *     mencionados. Tenga en cuenta que cada mes se           *
 *     recibirán archivos de novedades con la misma           *
 *     estructura, pero datos nuevos para agregar a cada      *
 *     maestro.                                               *
 *   • Considere este comportamiento al generar el código.    *
 *     Debe admitir la importación de novedades               *
 *     periódicamente.                                        *
 *   • Cada maestro debe importarse con un SP distinto. No    *
 *     se aceptarán scripts que realicen tareas por fuera     *
 *     de un SP.                                              *
 *   • La estructura/esquema de las tablas a generar será     *
 *     decisión suya. Puede que deba realizar procesos de     *
 *     transformación sobre los maestros recibidos para       *
 *     adaptarlos a la estructura requerida.                  *
 *                                                            *
 *   • Los archivos CSV/JSON no deben modificarse. En caso de *
 *     que haya datos mal cargados, incompletos, erróneos,    *
 *     etc., deberá contemplarlo y realizar las correcciones  *
 *     en el fuente SQL. (Sería una excepción si el archivo   *
 *     está malformado y no es posible interpretarlo como     *
 *     JSON o CSV).                                           *
 *                                                            *
 *   LO QUE HICIMOS EN ESTE SCRIPT:                           *
 *   Ejecutamos los SP para la importación de los archivos    *
 *	 y con un sp creamos la tabla comercio                    *
 *   la cual va a tener el cuit del comercio, el cual vamos   *
 *	 a usar en la factura o nota de crédito.                  *       
 *                                                            *
 *************************************************************/

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


--archivo de imformacion complementaria.xlsx
EXEC supermercado.importarEmpleados 'C:\importar\Informacion_complementaria.xlsx', 'La vida es como la RAM, todo es temporal y nada se queda.';
GO


--archivo de imformacion complementaria.xlsx
EXEC catalogo.importarLinea_de_producto 'C:\importar\Informacion_complementaria.xlsx';
GO
EXEC catalogo.insertarLinea_de_producto 'Importados', 'productos_importados';
GO
EXEC catalogo.insertarLinea_de_producto 'Accesorios', 'Electronic_accessories';
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


--archivo de imformacion complementaria.xlsx
EXEC ventas.importarMedios_de_Pago 'C:\importar\informacion_complementaria.xlsx';
GO

--archivo de ventas registradas.csv
EXEC ventas.importarVentas_registradas 'C:\importar\ventas_registradas.csv';
go





