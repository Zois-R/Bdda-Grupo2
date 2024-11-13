USE COM5600G02 
GO

---cada inserción, borrado, modificación crea un registro en la tabla bitácora
create or alter procedure registros.insertarLog 
(
	@modulo varchar(60),
	@texto	varchar(300) 
)
as
begin
	if LTRIM(RTRIM(@modulo)) = ''
		set @modulo = 'N/A';

	insert into registros.bitácora (txt, modulo)
	values	(@texto, @modulo);
end;