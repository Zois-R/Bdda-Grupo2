---declaro todo al principio para poder hacer execute
DECLARE @RutaBase NVARCHAR(255) = 'C:\sqlarchivos\backups\'; --poner siempre al final la barra \
DECLARE @ejecutarbackup NVARCHAR(MAX); 
DECLARE @recuperacion NVARCHAR(50);

---uso sql dinamico para las consultas de backups
-- ------------------ Backups full semanal ------------------ 
SET @ejecutarbackup = 'BACKUP DATABASE Com5600G02 ' + 
             'TO DISK = ''' + @RutaBase + 'backup_fullCOM5600G02.bak'' ' + 
             'WITH INIT, NAME = ''Backup Completo Semanal de Com5600G02'';'; 
EXEC sp_executesql @ejecutarbackup; 




-- ------------------ Backups diferencial diario ------------------ 
SET @ejecutarbackup = 'BACKUP DATABASE COM5600G02 ' + 
             'TO DISK = ''' + @RutaBase + 'backup_diffCOM5600G02.bak'' ' + 
             'WITH DIFFERENTIAL, NAME = ''Backup Diferencial Diario de COM5600G02'';'; 
EXEC sp_executesql @ejecutarbackup; 




-- ------------------ Verificar y establecer el modelo de recuperacion en FULL ------------------
----me aseguro que sea full para poder hacer el log de transacciones
SELECT @recuperacion = recovery_model_desc 
FROM sys.databases 
WHERE name = 'COM5600G02';

IF @recuperacion <> 'FULL' 
BEGIN 
    PRINT 'El modelo de recuperación no es FULL. Se cambia a FULL.'; 
    ALTER DATABASE COM5600G02  
    SET RECOVERY FULL; 

    -- Backup completo inicial
    SET @ejecutarbackup = 'BACKUP DATABASE COM5600G02 ' + 
                 'TO DISK = ''' + @RutaBase + 'backup_fullCOM5600G02.bak'' ' + 
                 'WITH INIT, NAME = ''Backup Completo de COM5600G02 para asegurar consistencia'';'; 
    EXEC sp_executesql @ejecutarbackup; 
END 
ELSE 
BEGIN 
    PRINT 'El modelo de recuperación ya es FULL.'; 
END;


-- ------------------ Backup del log de transacciones ------------------

SET @ejecutarbackup = 'BACKUP LOG COM5600G02 ' + 
             'TO DISK = ''' + @RutaBase + 'backup_logCOM5600G02.bak'' ' + 
             'WITH INIT, NAME = ''Backup Log de Transacciones de COM5600G02'';'; 
EXEC sp_executesql @ejecutarbackup; 

