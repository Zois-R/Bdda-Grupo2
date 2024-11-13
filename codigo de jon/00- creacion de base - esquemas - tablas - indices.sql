use master --drop database COM5600G02
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
--------------

create table supermercado.sucursal 
	(
		id			int identity(1,1),
		ciudad		varchar(40),
		localidad   varchar(40),
		direccion	varchar(150),
		horario		varchar(100),
		telefono	VARCHAR(20),
		activo		bit default 1,-- para el borrado logico
		constraint pk_sucursal primary key clustered (id)
	);
go

create table supermercado.empleado
	(
		legajo			int,
		nombre			varchar(30),
		apellido		varchar(30),
		dni				int,
		direccion		varchar(100),
		email_personal	varchar(80),
		email_empresa	varchar(80),
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


create table ventas.ventas_registradas
	(
		id				int identity(1,1),
		factura			varchar(20),
		tipo_Factura	char(1),
		idSucursal		int,
		tipo_cliente	varchar(15),
		genero			varchar(15),
		idProducto		int,
		precio_unitario	decimal(20,2),
		cantidad		int,
		fecha			date,
		hora			time,
		idMedio_de_pago	int,
		idEmpleado		int,
		idPago			varchar(50),
		activo			bit default 1,
		constraint pk_ventas_registradas primary key clustered (id),
		constraint fk_sucursal foreign key (idSucursal) 
			references supermercado.sucursal(id),
		constraint fk_producto foreign key (idProducto) 
			references catalogo.producto(id),
		constraint fk_medioDePago foreign key (idMedio_de_pago) 
			references ventas.mediosDePago(id),
		constraint fk_empleado foreign key (idEmpleado) 
			references supermercado.empleado(legajo)
	);
go

create table ventas.ventasProductosNoRegistrados
	(
		factura			varchar(20) COLLATE Latin1_General_CI_AI,
		tipo_Factura	char(1),
		ciudad			varchar(20) COLLATE Latin1_General_CI_AI,
		tipo_cliente	varchar(20) COLLATE Latin1_General_CI_AI,
		genero			varchar(15) COLLATE Latin1_General_CI_AI,
		Producto		nvarchar(200) COLLATE Latin1_General_CI_AI,
		precio_unitario	DECIMAL(20, 2),
		cantidad		int,
		fecha			varchar(15),
		hora			time,
		Medio_de_pago	varchar(20) COLLATE Latin1_General_CI_AI,
		idEmpleado		int,
		idPago			varchar(100) COLLATE Latin1_General_CI_AI
    );
go

-------------------- creacion de indices 
create nonclustered index ix_nombre on catalogo.producto(nombre)
go
create nonclustered index ix_ciudad on supermercado.sucursal(ciudad)
go
create nonclustered index ix_linea on catalogo.linea_de_producto(nombre)
go
create nonclustered index ix_factura on ventas.ventas_registradas(factura)
go
