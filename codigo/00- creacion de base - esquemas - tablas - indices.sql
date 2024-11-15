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

----------------esquema de sumpermercado : orden : sucursal, empleado
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


------------------------
-- Esta tabla se emplea como bitácora (log) de las operaciones de inserción, borrado y modificación

create table registros.bitácora(
	
	id		int identity(1,1),
	txt		varchar(300),
	modulo  varchar(60),
	fyH		datetime default getdate(),
	constraint pk_registro primary key clustered (id)
	);
go
--------------------------------------------------------------------------

CREATE TABLE supermercado.Comercio (
    cuit NVARCHAR(20) , 
    nombre_comercio nvarchar(30),           
	razon_social  nvarchar(30),                 
    email nvarchar(100)
	constraint pk_comercio primary key clustered (cuit)
);    
 
go


create table supermercado.sucursal 
	(
		id			int identity(1,1),
		idComercio  nvarchar(20),
		ciudad		varchar(40),
		localidad   varchar(40),
		direccion	varchar(150),
		horario		varchar(100),
		telefono	VARCHAR(20),
		activo		bit default 1,-- para el borrado logico
		constraint pk_sucursal primary key clustered (id),
		constraint fk_empresa foreign key (idComercio) references supermercado.Comercio(cuit)
	);
go


create table supermercado.empleado 
	(
		legajo			int,
		nombre          VARBINARY(256),     -- Cambiado a VARBINARY para encriptación
		apellido        VARBINARY(256),     -- Cambiado a VARBINARY para encriptación
		dni             VARBINARY(256),     -- Cambiado a VARBINARY para encriptación
		direccion       VARBINARY(256),     -- Cambiado a VARBINARY para encriptación
		email_personal  VARBINARY(256),     -- Cambiado a VARBINARY para encriptación
		email_empresa	VARBINARY(256),     -- Cambiado a VARBINARY para encriptación
		cargo			varchar(20),
		idSucursal		int,
		turno			varchar(30),
		activo			bit default 1,-- para el borrado logico
		constraint pk_empleado primary key clustered (legajo),
		constraint fk_sucursal foreign key (idSucursal) references supermercado.sucursal(id)
	);
go

                                       




---------------------esquema catalogo


create table catalogo.linea_de_producto
	(
		id			int identity(1,1) primary key,
		nombre		varchar(20),
		categoria	varchar(50),
		activo		bit default 1,-- para el borrado logico
	);
GO

create table catalogo.producto   
	(
		id				int identity(1,1),
		nombre			nvarchar(200),
		Precio			DECIMAL(18, 2),
		id_linea		int,
		activo			bit default 1,
		constraint pk_producto primary key clustered (id),
		constraint fk_Linea_de_producto foreign key (id_linea) 
			references catalogo.linea_de_producto(id)
	);
go


------------------------

create table ventas.mediosDePago
	(
		id		int identity(1,1),
		nombre	varchar(15),
		activo	bit default 1,
		constraint pk_medios primary key clustered (id)
	);
go

create table ventas.factura
	(
		id				int identity(1,1),
		nroFactura		char(11),
		tipo_Factura	char(1),
		fecha			date,
		hora			time,
		idMedio_de_pago	int,
		idPago			varchar(50),
		estadoDePago    char(17) default 'pagada', --- En espera de pago
		total			decimal(12,2),
		totalConIva		decimal(12,2),
		CONSTRAINT pk_Fact PRIMARY KEY CLUSTERED (id),
		constraint fk_medioDePago foreign key (idMedio_de_pago) references ventas.mediosDePago(id),
	);
go

create table ventas.detalleVenta
	(
		id				int identity(1,1),
		idFactura		int,
		idProducto		int,
		precio			decimal(6,2),
		cant			smallint not null,
		subtotal		decimal(10,2),
		constraint pk_detalleVenta primary key clustered (id),
		constraint fk_factura1 foreign key (idFactura) references ventas.factura(id),
		constraint fk_producto2 foreign key (idProducto) references catalogo.producto(id)
	);
go


CREATE TABLE ventas.cliente 
	(
		id INT IDENTITY(1,1),
		cuil VARCHAR(20),
		tipo_cliente VARCHAR(10),
		genero VARCHAR(10),
		constraint pk_cliente primary key clustered (id)
	);
go


create table ventas.registro_de_ventas
	(
		id				int identity(1,1),
		idFactura		int,
		idEmpleado      int not null,
		idSucursal		int,
		idCliente		int NULL,
		constraint pk_ventas_registradas primary key clustered (id),
		constraint fk_sucursal foreign key (idSucursal) references supermercado.sucursal(id),
		CONSTRAINT fk_emp FOREIGN KEY (idEmpleado) REFERENCES supermercado.empleado(legajo),
		constraint fk_factura2 foreign key (idFactura) references ventas.factura(id),
		constraint fk_cliente foreign key (idCliente) references ventas.cliente(id)
	);
go



CREATE TABLE ventas.notasDeCredito 
	(
		id				INT IDENTITY(1,1),
		idDetalleVenta	INT,	--- el detalle de venta es lo que posee el nombre del producto y el nro de factura, asociados por la FK de esas tablas
		fecha			DATE DEFAULT GETDATE(),
		monto			DECIMAL(6,2),
		razon			NVARCHAR(255),
		constraint pk_NC primary key clustered (id),
		CONSTRAINT fk_detalleVenta FOREIGN KEY (idDetalleVenta) REFERENCES ventas.detalleVenta(id)
	);
GO

/*
los parámetros de tipo TABLE no se pueden pasar directamente a un procedimiento almacenado. 
Una alternativa es crear una variable de tipo de tabla en la base de datos, 
que luego podemos usar como parámetro en el procedimiento.

creamos un tipo de tabla llamado TipoProductosDetalle para pasar 
la información de multiples productos como un parámetro al sp que inserta nuevas ventas.
*/

--Lo usamos al insertar una venta

CREATE TYPE ventas.TipoProductosDetalle AS TABLE (
    idProducto INT,
    cantidad SMALLINT
);
GO


--- por si viene una factura no coincidente con algun producto del catalogo (si, somos paranoicos...y que!!!)

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
		idPago			varchar(100)
    );
go


-------------------- creacion de indices ---fijarse que otros mas convienen
create nonclustered index ix_nombre on catalogo.producto(nombre)
go
create nonclustered index ix_ciudad on supermercado.sucursal(ciudad)
go
create nonclustered index ix_linea on catalogo.linea_de_producto(nombre)
go
create nonclustered index ix_factura on ventas.factura(nroFactura)
go


