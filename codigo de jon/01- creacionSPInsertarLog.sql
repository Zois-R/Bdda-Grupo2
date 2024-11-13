USE COM5600G02 
GO

---cada inserci�n, borrado, modificaci�n crea un registro en la tabla bit�cora
create or alter procedure registros.insertarLog 
(
	@modulo varchar(60),
	@texto	varchar(300) 
)
as
begin
	if LTRIM(RTRIM(@modulo)) = ''
		set @modulo = 'N/A';

	insert into registros.bit�cora (txt, modulo)
	values	(@texto, @modulo);
end;