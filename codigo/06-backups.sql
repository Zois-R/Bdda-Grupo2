DECLARE @RutaBase NVARCHAR(255) = 'C:\Users\karen\OneDrive\Escritorio\Nueva carpeta\backups'; 
DECLARE @Query NVARCHAR(MAX); 
DECLARE @RecoveryModel NVARCHAR(50);


-- ------------------ Backups full semanal ------------------ 
SET @Query = 'BACKUP DATABASE Com5600G02 ' + 
             'TO DISK = ''' + @RutaBase + 'Com5600G02_Full.bak'' ' + 
             'WITH INIT, NAME = ''Backup Completo Semanal de Com5600G02'';'; 
EXEC sp_executesql @Query; 





-- ------------------ Backups diferencial diario ------------------ 
SET @Query = 'BACKUP DATABASE COM5600G02 ' + 
             'TO DISK = ''' + @RutaBase + 'COM5600G02_Diff.bak'' ' + 
             'WITH DIFFERENTIAL, NAME = ''Backup Diferencial Diario de COM5600G02'';'; 
EXEC sp_executesql @Query; 




-- ------------------ Verificar y establecer el modelo de recuperación en FULL ------------------
----me aseguro que sea full para poder hacer el log trasancion
SELECT @RecoveryModel = recovery_model_desc 
FROM sys.databases 
WHERE name = 'COM5600G02';

IF @RecoveryModel <> 'FULL' 
BEGIN 
    PRINT 'El modelo de recuperación no es FULL. Se cambiará a FULL.'; 
    ALTER DATABASE COM5600G02  
    SET RECOVERY FULL; 

    -- Backup completo inicial
    SET @Query = 'BACKUP DATABASE COM5600G02 ' + 
                 'TO DISK = ''' + @RutaBase + 'COM5600G02_Full_Initial.bak'' ' + 
                 'WITH INIT, NAME = ''Backup Completo Inicial de COM5600G02 para asegurar consistencia'';'; 
    EXEC sp_executesql @Query; 
END 
ELSE 
BEGIN 
    PRINT 'El modelo de recuperación ya es FULL.'; 
END;


-- ------------------ Backup del log de transacciones ------------------

SET @Query = 'BACKUP LOG COM5600G02 ' + 
             'TO DISK = ''' + @RutaBase + 'COM5600G02_Log.bak'' ' + 
             'WITH INIT, NAME = ''Backup Log de Transacciones de COM5600G02'';'; 
EXEC sp_executesql @Query; 
