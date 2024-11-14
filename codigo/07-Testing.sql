--------------------------------------------------------------------------------------------------------------
--TEST STORES DE CREACIÓN
--------------------------------------------------------------------------------------------------------------

/*
CASO DE TESTING : Descripción breve de la prueba (qué estás probando)
VARIABLES DE ENTRADA:
    - @Parametro1: valor de ejemplo
    - @Parametro2: valor de ejemplo
RESULTADO ESPERADO: Resultado esperado de la operación (ej. filas afectadas, mensajes, etc.)
DESCRIPCIÓN: Explicación de lo que debería suceder (detalles sobre la prueba específica y el objetivo)
*/

---------------------------------------------------------------------
--TESTS RELACIONADOS CON LA CREACIÓN DE LA BITÁCORA
---------------------------------------------------------------------

/*
CASO DE TESTING 1: Insertar log con valores válidos
INPUTS:
    - @modulo: 'Autenticación'
    - @texto: 'Inicio de sesión exitoso'
RESULTADO ESPERADO: Resultado esperado de la operación 
DESCRIPCIÓN: Explicación de lo que debería suceder (detalles sobre la prueba específica y el objetivo)
*/
EXEC registros.insertarLog @modulo = 'Autenticación', @texto = 'Inicio de testing exitoso'
USE COM5600G02;
select * from registros.bitacora
/*
CASO DE TESTING 2: Insertar log con el módulo como nulo
INPUTS:
    - @modulo: ''
    - @texto: 'Intento de inicio de sesión fallido'
RESULTADO ESPERADO:  El valor de modulo debe cambiar a N/A en el registro insertado.
*/

EXEC registros.insertarLog @modulo = '', @texto = 'Testing con modulo nulo'


/*
CASO DE TESTING 3: Insertamos log con en el que la variable modulo tiene espacios en blanco 
VARIABLES DE ENTRADA:
    - @modulo1: valor de ejemplo
    - @texto: valor de ejemplo
RESULTADO ESPERADO: Resultado esperado de la operación (ej. filas afectadas, mensajes, etc.)
*/

EXEC registros.insertarLog @modulo = '   ', @texto = 'Testing con modulo nulo'
SELECT * FROM registros.bitácora



/*
CASO DE TESTING 4: Insertar log con longitud de texto mayor a 300
VARIABLES DE ENTRADA:
    - @modulo = 'Seguridad'
    - @texto = 'Texto con límite máximo de longitud... (300 caracteres)'
RESULTADO ESPERADO: El texto se registra correctamente hasta los 300 caracteres
*/
EXEC registros.insertarLog @modulo = 'Seguridad', @texto = 'Al venir al mundo fueron delicadamente mecidas por las manos de la lustral Doniazada, su buena tía, que grabó sus nombres sobre hojas de oro coloreadas de húmedas pedrerías y las cuidó bajo el terciopelo de sus pupilas hasta la adolescencia dura, para esparcirlas después, voluptuosas y libres, sobre el mundo oriental, eternizado por su sonrisa.'


---------------------------------------------------------------------
--TEST INSERCIÓN SUCURSAL
---------------------------------------------------------------------

/*
CASO DE TESTING : Descripción breve de la prueba (qué estás probando)
VARIABLES DE ENTRADA:
    - @Parametro1: valor de ejemplo
    - @Parametro2: valor de ejemplo
RESULTADO ESPERADO: Resultado esperado de la operación (ej. filas afectadas, mensajes, etc.)
DESCRIPCIÓN: Explicación de lo que debería suceder (detalles sobre la prueba específica y el objetivo)
*/

EXECUTE supermercado.insertarSucursal


--TIENE QUE ACTUALIZAR JON LOS CAMBIOS


use COM5600G02;
---------------------------------------------------------------------
--TEST INSERCIÓN EMPLEADO
---------------------------------------------------------------------

/*
CASO DE TESTING : Testeamos que ni el dni ni el email se puedan repetir
VARIABLES DE ENTRADA:
    - @Parametro1: valor de ejemplo
    - @Parametro2: valor de ejemplo
RESULTADO ESPERADO: Que no nos deje insertar un empleado con legajo duplicado

*/

EXEC supermercado.mostrarEmpleadosDesencriptados 
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.',
    @idSucursalGerente = 2,
    @idEmpleado = 257032;
------------------------------
select * from supermercado.empleado
EXEC supermercado.insertarEmpleado
    @legajo = 258490,                     
    @nombre = 'Juan',                  
    @apellido = 'Perez',               
    @dni = '909447164',                 
    @direccion = 'Calle Falsa 123',    
    @email_personal = 'gguanperez@gmail.com',  
    @email_empresa = 'gguan.perez@superA.com', 
    @cargo = 'Cajero',                   
    @idSucursal = 2,                    
    @turno = 'TM',                  
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.';    


---------------------------------------------------------------------
--TEST INSERCIÓN LINEA DE PRODUCTO
---------------------------------------------------------------------
/*
CASO DE TESTING : Testeamos que no se repita la categoría de la linea del producto
VARIABLES DE ENTRADA:
    - @nombre: 'Almacen'
    - @categoría: 'aceite_vinagre_y_sal'
RESULTADO ESPERADO: Que no nos deje insertar una categoría repetda
*/

EXEC catalogo.insertarLinea_de_producto @nombre = 'Almacen',@categoría = 'aceite_vinagre_y_sal'


---------------------------------------------------------------------
--TEST INSERCIÓN CLIENTE
---------------------------------------------------------------------

/*
CASO DE TESTING : Testeamos que que no haya duplicados en cliente
RESULTADO ESPERADO: Que no nos deje insertar un cliente repetido
*/

declare @idCliente int;
declare @clienteExistente BIT;

EXEC ventas.insertar_cliente 
    @cuil = '20-12345678-9', 
    @tipoCliente = 'Particular', 
    @genero = 'Masculino', 
    @idCliente = @idCliente OUTPUT, 
    @clienteExistente = @clienteExistente OUTPUT;

IF @clienteExistente = 1
	PRINT( 'No se acepta duplicado')
	
SELECT * FROM ventas.cliente



---------------------------------------------------------------------
--TEST INSERCIÓN PRODUCTO
---------------------------------------------------------------------

---insercion  (nombreProducto, precio decimal, id  lal linea )
catalogo.insertarProducto 'Samsumg Galaxy A03',150.00,150;
select * from catalogo.producto order by id desc ;
---insersion pero no existe linea de producto
catalogo.insertarProducto 'Samsumg Galaxy A04',160.00,160;
---no admite duplicados
catalogo.insertarProducto 'Samsumg Galaxy A03',150.00,150;
---modificacion (no esta hecho)

---borrado (no esta hecho)




---------------------------------------------------------------------
--TEST INSERCIÓN MEDIO DE PAGO
---------------------------------------------------------------------

---insercion 
EXEC ventas.insertarMedioDePago 'Debit Card';
select * from ventas.mediosDePago order by id desc ;
---no admite duplicados
EXEC ventas.insertarMedioDePago 'Cash';
---modificacion (no tiene)

---borrado (lógico)
EXEC ventas.borrado_logico_mediosDePago @id = 1,@modulo = 'mediosDePago'



---------------------------------------------------------------------
--TEST GENERAR VENTA CON FACTURA
---------------------------------------------------------------------
select * from ventas.detalleVenta

--- testing
-- Primero, declaramos la tabla de tipo TipoProductosDetalle con los productos a insertar
DECLARE @productosDetalle ventas.TipoProductosDetalle;

-- Insertamos productos de prueba en la tabla de tipo
INSERT INTO @productosDetalle (idProducto, idLineaProducto, precio, cantidad)
VALUES
    (1, 101, 100.00, 5555),  -- Producto 1, Línea 101, Precio 100.00, Cantidad 2
    (2, 102, 50.00, 5555),   -- Producto 2, Línea 102, Precio 50.00, Cantidad 3
    (3, 103, 30.00, 3444);   -- Producto 3, Línea 103, Precio 30.00, Cantidad 5

-- Ahora, llamamos al procedimiento almacenado ventas.generar_venta_con_factura con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '750-67-8428',    -- Número de factura de ejemplo
    @tipoFactura = 'A',             -- Tipo de factura (A o B, dependiendo de la configuración)
    @fecha = '1/5/2019',          -- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago (puede ser un ID válido de la tabla mediosDePago)
    @idPago = 'PAGO123456',         -- ID del pago (número de transacción o similar)
    @idEmpleado = 257020,              -- ID del empleado (debe ser un ID válido de la tabla empleados)
    @idSucursal = 3,                -- ID de la sucursal (debe ser un ID válido de la tabla sucursal)
    @tipoCliente = 'Normal',       -- Tipo de cliente (ejemplo: 'Regular', 'Nuevo', etc.)
    @genero = 'Male',          -- Género del cliente
    @cuil = '20-12345678-9',        -- CUIL del cliente (dato ficticio)
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go