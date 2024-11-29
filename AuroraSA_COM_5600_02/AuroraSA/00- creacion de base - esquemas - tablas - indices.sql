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
 *   NRO. DE ENTREGA: 3                                     *
 *   FECHA DE ENTREGA: 15/11/2024                           *
 *															*
 *   CONSIGNA:
 *   Cree la base de datos, entidades y relaciones.         *
 *   Incluya restricciones y claves. Deberá entregar un     *
 *   archivo .sql con el script completo de creación        *
 *   (debe funcionar si se lo ejecuta “tal cual” es         *
 *   entregado). Incluya comentarios para indicar qué hace  *
 *   cada módulo de código.                                 *
 *                                                          *
 *   Genere esquemas para organizar de forma lógica los     *
 *   componentes del sistema y aplique esto en la creación  *
 *   de objetos. NO use el esquema “dbo”.                   *
 *															*
 *	 LO QUE HICIMOS EN ESTE SCRIPT:							*
 *   Creamos la base de datos, los 4					    *
 *   esquemas para una correcta organización, junto con las *
 *   tablas con sus correspondientes constraints y los      *
 *   índices.                                               *
 *                                                          *
 ************************************************************/




use master -- drop database COM5600G02
go

IF NOT EXISTS ( SELECT name FROM master.dbo.sysdatabases WHERE name = 'COM5600G02')
BEGIN
	CREATE DATABASE COM5600G02
	COLLATE Latin1_General_CI_AI; -- "case-insensitive" (insensible a mayúsculas y minúsculas) y "accent-insensitive" (insensible a acentos)
END
go
use COM5600G02 
go

----------------CREAMOS LOS ESQUEMAS --------------------

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'registros')
BEGIN
	EXEC('CREATE SCHEMA registros')
END
go
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'supermercado')
BEGIN
	EXEC('CREATE SCHEMA supermercado')
END
go
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'catalogo')
BEGIN
	EXEC('CREATE SCHEMA catalogo')
END
go
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'ventas')
BEGIN
	EXEC('CREATE SCHEMA ventas')
END
go


--------------------------------------------------------------------------------------------------------
-----------------------------------------  ESQUEMA REGISTROS -------------------------------------------
--------------------------------------------------------------------------------------------------------

-- Esta tabla se emplea como bitácora (log) de las operaciones de inserción, borrado y modificación

if not exists (SELECT * FROM sys.tables WHERE name = 'bitácora' AND schema_id = SCHEMA_ID('registros'))
begin

create table registros.bitácora(
		id		int identity(1,1),
		txt		varchar(300) not null,
		modulo  varchar(60),
		fyH		datetime default getdate(),
		constraint pk_registro primary key clustered (id),
		constraint chk_txt_not_empty check (len(txt) > 0)
);

end

go



 --------------------------------------------------------------------------------------------------------
-----------------------------------------  ESQUEMA SUPERMERCADO -----------------------------------------
 --------------------------------------------------------------------------------------------------------

 if not exists (SELECT * FROM sys.tables WHERE name = 'Comercio' AND schema_id = SCHEMA_ID('supermercado'))
begin
CREATE TABLE supermercado.Comercio (
		cuit VARCHAR(20), 
		nombre_comercio varchar(30) not null,           
		razon_social  varchar(30) not null,                 
		email varchar(60)
		constraint pk_comercio primary key clustered (cuit),
		CONSTRAINT chk_cuit
			CHECK (cuit LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]')
); 
end


   
 
go

if not exists (SELECT * FROM sys.tables WHERE name = 'sucursal' AND schema_id = SCHEMA_ID('supermercado'))
begin
create table supermercado.sucursal 
	(
		id			int identity(1,1),
		idComercio  varchar(20),
		ciudad		varchar(40),
		localidad   varchar(40),
		direccion	varchar(150),
		horario		varchar(100),
		telefono	VARCHAR(15),
		activo		bit default 1,-- para el borrado logico
		constraint pk_sucursal primary key clustered (id),
		constraint fk_empresa foreign key (idComercio) references supermercado.Comercio(cuit),
		constraint chk_telefono_format check (
	        telefono LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' OR			
		    telefono LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
		)
	);
end

go


/*
si no establecemos el tamaño de los campos de la tabla a encriptar con 256 bytes
se produce un error debido a que la longitud de los campos de la tabla empleados 
es menor al proceso de encriptación EncryptByPassPhrase que genera una longitud de salida mayor 
al tamaño original de los campos a importar.  
ejemplo error:
Los datos binarios o de la cadena se truncan en la columna "email_empresa" 
de la tabla "COM5600G02.supermercado.empleado". Valor truncado: "".
por eso el tamaño es varbinary(256).
*/

if not exists (SELECT * FROM sys.tables WHERE name = 'empleado' AND schema_id = SCHEMA_ID('supermercado'))
begin
create table supermercado.empleado
	(
		legajo			int,
		nombre          VARBINARY(256),     -- Cambiado a VARBINARY para encriptación
		apellido        VARBINARY(256),     
		dni             VARBINARY(256),     
		direccion       VARBINARY(256),     
		email_personal  VARBINARY(256),     
		email_empresa	VARBINARY(256),     
		cargo			varchar(25),
		idSucursal		int,
		turno			varchar(20), 
		usuario			varchar(50) default '',
		activo			bit default 1,-- para el borrado logico
		constraint pk_empleado primary key clustered (legajo),
		constraint fk_sucursal foreign key (idSucursal) references supermercado.sucursal(id)
	);
end

go

                                       




 --------------------------------------------------------------------------------------------------------
-----------------------------------------  ESQUEMA CATALOGO ---------------------------------------------
 --------------------------------------------------------------------------------------------------------

if not exists (SELECT * FROM sys.tables WHERE name = 'linea_de_producto' AND schema_id = SCHEMA_ID('catalogo'))
begin
create table catalogo.linea_de_producto
	(
		id			int identity(1,1) primary key,
		nombre		varchar(20) not null,
		categoria	varchar(50) not null,
		activo		bit default 1,-- para el borrado logico
	);
end



GO

if not exists (SELECT * FROM sys.tables WHERE name = 'producto' AND schema_id = SCHEMA_ID('catalogo'))
begin
create table catalogo.producto   
	(
		id				int identity(1,1),
		nombre			nvarchar(200) not null,
		Precio			DECIMAL(10, 2) check( Precio>0 ),
		id_linea		int,
		activo			bit default 1,
		constraint pk_producto primary key clustered (id),
		constraint fk_Linea_de_producto foreign key (id_linea) 
			references catalogo.linea_de_producto(id)
	);
end

go

if not exists (SELECT * FROM sys.tables WHERE name = 'producto ' AND schema_id = SCHEMA_ID('catalogo'))
begin
create table catalogo.producto   
	(
		id				int identity(1,1),
		nombre			nvarchar(200) not null,
		Precio			DECIMAL(10, 2) check( Precio>0 ),
		id_linea		int,
		activo			bit default 1,
		constraint pk_producto primary key clustered (id),
		constraint fk_Linea_de_producto foreign key (id_linea) 
			references catalogo.linea_de_producto(id)
	);
end


go



 --------------------------------------------------------------------------------------------------------
-----------------------------------------  ESQUEMA VENTAS ---------------------------------------------
 --------------------------------------------------------------------------------------------------------
if not exists (SELECT * FROM sys.tables WHERE name = 'mediosDePago' AND schema_id = SCHEMA_ID('ventas'))
begin
create table ventas.mediosDePago
	(
		id		int identity(1,1),
		nombre	varchar(15) not null,
		activo	bit default 1,
		constraint pk_medios primary key clustered (id)
	);
end

go

if not exists (SELECT * FROM sys.tables WHERE name = 'factura' AND schema_id = SCHEMA_ID('ventas'))
begin
create table ventas.factura
	(
		id				int identity(1,1),
		nroFactura		char(11),
		tipo_Factura	char(1),
		fecha			date,
		hora			time,
		idMedio_de_pago	int,
		idPago			varchar(50),
		estadoDePago    char(17) default 'pagada',
		total			decimal(12,2),
		totalConIva		decimal(12,2),
		activo			bit default 1,
		CONSTRAINT pk_Fact PRIMARY KEY CLUSTERED (id),
		constraint fk_medioDePago foreign key (idMedio_de_pago) references ventas.mediosDePago(id),
		constraint chk_nroFactura 
			check (nroFactura LIKE '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	);
end



go

if not exists (SELECT * FROM sys.tables WHERE name = 'detalleVenta' AND schema_id = SCHEMA_ID('ventas'))
begin
create table ventas.detalleVenta
	(
		id				int identity(1,1),
		idFactura		int,
		idProducto		int,
		precio			decimal(10,2) check(precio>0) ,
		cant			smallint not null check(cant>0),
		subtotal		decimal(12,2),
		activo			bit default 1,
		constraint pk_detalleVenta primary key clustered (id),
		constraint fk_factura1 foreign key (idFactura) references ventas.factura(id),
		constraint fk_producto2 foreign key (idProducto) references catalogo.producto(id)
	);
end


go

if not exists (SELECT * FROM sys.tables WHERE name = 'cliente' AND schema_id = SCHEMA_ID('ventas'))
begin
CREATE TABLE ventas.cliente 
	(
		id INT IDENTITY(1,1),
		cuil VARCHAR(20),
		tipo_cliente VARCHAR(10),
		genero VARCHAR(10),
		usuario VARCHAR(50) default null,
		constraint pk_cliente primary key clustered (id),
		CONSTRAINT chk_cuil 
			CHECK (cuil LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]')
	);
end


go

if not exists (SELECT * FROM sys.tables WHERE name = 'registro_de_ventas' AND schema_id = SCHEMA_ID('ventas'))
begin
create table ventas.registro_de_ventas
	(
		id				int identity(1,1),
		idFactura		int,
		idEmpleado      int,
		idSucursal		int,
		idCliente		int NULL,
		constraint pk_ventas_registradas primary key clustered (id),
		constraint fk_sucursal foreign key (idSucursal) references supermercado.sucursal(id),
		CONSTRAINT fk_emp FOREIGN KEY (idEmpleado) REFERENCES supermercado.empleado(legajo),
		constraint fk_factura2 foreign key (idFactura) references ventas.factura(id),
		constraint fk_cliente foreign key (idCliente) references ventas.cliente(id)
	);
end


go

if not exists (SELECT * FROM sys.tables WHERE name = 'notasDeCredito ' AND schema_id = SCHEMA_ID('ventas'))
begin
CREATE TABLE ventas.notasDeCredito 
	(
		id				INT IDENTITY(1,1),
		idDetalleVenta	INT,	--- el detalle de venta es lo que posee el nombre del producto y el nro de factura, asociados por la FK de esas tablas
		fecha			DATE DEFAULT GETDATE(),
		monto			DECIMAL(12,2),
		razon			CHAR(7), 
		constraint pk_NC primary key clustered (id),
		CONSTRAINT fk_detalleVenta FOREIGN KEY (idDetalleVenta) REFERENCES ventas.detalleVenta(id),
		CONSTRAINT chk_razon CHECK (razon IN ('devPago', 'devProd'))
	);
end



GO

/*
Los parámetros de tipo TABLE no se pueden pasar directamente a un procedimiento almacenado. 
Una alternativa es crear una variable de tipo de tabla en la base de datos, 
que luego podemos usar como parámetro en el procedimiento.

creamos un tipo de tabla llamado TipoProductosDetalle para pasar 
la información de multiples productos como un parámetro al sp que inserta nuevas ventas.
*/

--Lo usamos al insertar una venta
IF NOT EXISTS ( SELECT * FROM sys.types WHERE name = 'TipoProductosDetalle' AND schema_id = SCHEMA_ID('ventas'))
begin
CREATE TYPE ventas.TipoProductosDetalle AS TABLE (
		idProducto INT,
		cantidad SMALLINT
);
end
GO


--- por si viene una factura no coincidente con algun producto del catalogo (si, somos paranoicos...y que!!!)
if not exists (SELECT * FROM sys.tables WHERE name = 'ventasProductosNoRegistrados' AND schema_id = SCHEMA_ID('ventas'))
begin
create table ventas.ventasProductosNoRegistrados
	(
		factura			varchar(20),
		tipo_Factura	char(1),
		ciudad			varchar(20),
		tipo_cliente	varchar(20),
		genero			varchar(15),
		Producto		nvarchar(200),
		precio_unitario	DECIMAL(20, 2),
		cantidad		int,
		fecha			varchar(15),
		hora			time,
		Medio_de_pago	varchar(20),
		idEmpleado		int,
		idPago			varchar(30)
    );
end


go

----esta tabla ayuda porque despues de cambiar los caracteres  raros en nombre de producto
----no coincidieron productos que venian con esos caracteres raros en sus nombres en ventas registradas
----estos tipos de problema por futuros nombres de producto que se escriban incorrectamente 
---- son los que justifican que se deje esta tabla como auxiliar de registros extraños entre otras anormalidades posibles






 --------------------------------------------------------------------------------------------------------
-----------------------------------------  CREACIÓN DE ÍNDICES ---------------------------------------------
 --------------------------------------------------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_nombre' AND object_id = OBJECT_ID('catalogo.producto'))
begin
	create nonclustered index ix_nombre on catalogo.producto(nombre)
end
go

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_ciudad' AND object_id = OBJECT_ID('supermercado.sucursal'))
begin
	create nonclustered index ix_ciudad on supermercado.sucursal(ciudad) include (localidad)
end

go
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_linea' AND object_id = OBJECT_ID('catalogo.linea_de_producto'))
begin
	create nonclustered index ix_linea on catalogo.linea_de_producto(nombre) include (categoria)
end

go
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_factura' AND object_id = OBJECT_ID('ventas.factura'))
begin
	create nonclustered index ix_factura on ventas.factura(nroFactura)
end

go
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_clientes' AND object_id = OBJECT_ID('ventas.cliente'))
begin
	create nonclustered index ix_clientes on ventas.cliente(cuil)
end
go
