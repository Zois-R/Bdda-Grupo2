/************************************************************
 *                                                          *
 *                      BASE DE DATOS APLICADA             *
 *                                                          *
 *   INTEGRANTES:                                           *
 *      - Edilberto Guzman                                  *
 *      - Zois Andres Uziel Ruggiero Bellone                *
 *      - Karen Anabella Bursa                              *
 *      - Jonathan Ivan Aranda Robles                       *
 *                                                          *
 *   NRO. DE ENTREGA: 5                                     *
 *   FECHA DE ENTREGA: 15/11/2024                           *
 *                                                          *
 *   CONSIGNA:                                              *
 *   Cuando un cliente reclama la devolución de un producto *
 *   se genera una nota de crédito por el valor del         *
 *   producto o un producto del mismo tipo. En el caso de   *
 *   que el cliente solicite la nota de crédito, solo los   *
 *   Supervisores tienen el permiso para generarla. Tener   *
 *   en cuenta que la nota de crédito debe estar asociada a *
 *   una Factura con estado pagada. Asigne los roles        *
 *   correspondientes para poder cumplir con este           *
 *   requisito.                                             *
 *                                                          *
 *   Por otra parte, se requiere que los datos de los       *
 *   empleados se encuentren encriptados, dado que los      *
 *   mismos contienen información personal.                 *
 *                                                          *
 *   La información de las ventas es de vital importancia   *
 *   para el negocio, por ello se requiere que se           *
 *   establezcan políticas de respaldo tanto en las ventas  *
 *   diarias generadas como en los reportes generados.      *
 *                                                          *
 *   Plantee una política de respaldo adecuada para cumplir *
 *   con este requisito y justifique la misma.              *
 *                                                          *
 *   LO QUE HICIMOS EN ESTE SCRIPT:                         *
 *   - Declaramos variables para definir la ruta base de    *
 *     los backups.                                         *
 *   - Implementamos backups completos semanales            *
 *     utilizando SQL dinámico.                             *
 *   - Configuramos backups diferenciales diarios para      *
 *     almacenar únicamente los cambios realizados desde el *
 *     último backup completo.                              *
 *   - Verificamos el modelo de recuperación de la base de  *
 *     datos y lo configuramos como FULL en caso de que no  *
 *     lo estuviera, asegurando la capacidad de realizar    *
 *     backups de log de transacciones.                     *
 *   - Realizamos un backup inicial completo en caso de     *
 *     cambiar el modelo de recuperación a FULL.            *
 *   - Ejecutamos el backup del log de transacciones para   *
 *     registrar las que se realizaron y asegurar la        *
 *     posibilidad de recuperar los datos hasta un punto    *
 *     en el tiempo.                                        *
 *                                                          *
 ************************************************************/


---declaro todo al principio para poder hacer execute
DECLARE @RutaBase NVARCHAR(255) = 'C:\backup\'; --poner siempre al final la barra \
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

