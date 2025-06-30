EXEC sp_configure 'Show Advanced Options', 1;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

EXEC sp_MSSet_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
EXEC sp_MSSet_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;
RECONFIGURE;
GO

USE Com5600G01;
GO
-- #################################################
-- ################### SP IMPORTAR #################
-- #################################################
USE Com5600G01;
GO

CREATE OR ALTER PROCEDURE usuarios.importarGrupoFamiliar
    @path NVARCHAR(400) 
AS
BEGIN
    SET NOCOUNT ON;

    -- Tabla temporal para almacenar los datos importados
    CREATE TABLE #tempGrupoFamiliar (
        nro_de_socio VARCHAR(7),
		nro_de_socio_RP VARCHAR(7),
		nombre VARCHAR(35),
		apellido VARCHAR(35),
		dni INT,
		email_personal VARCHAR(255),
		fec_nac DATE,
		tel_contacto VARCHAR(20),
		tel_emerg INT,
		nom_obra_social VARCHAR(35),
		nro_socio_obra_social VARCHAR(35),
		tel_cont_emerg VARCHAR(35)
    );

    DECLARE @sql NVARCHAR(MAX);

    -- Consulta con los encabezados EXACTOS como aparecen en tu Excel
    SET @sql = N'
        INSERT INTO #tempGrupoFamiliar (
            nro_de_socio,
			nro_de_socio_RP,
			nombre,
			apellido,
			dni,
			email_personal,
			fec_nac,
			tel_contacto,
			tel_emerg,
			nom_obra_social,
			nro_socio_obra_social,
			tel_cont_emerg
        )
        SELECT
            [Nro de Socio],
			[Nro de socio RP],
			RTRIM(LTRIM(LOWER([Nombre]))),
			RTRIM(LTRIM(LOWER([ apellido]))),
			[ DNI],
			[ email personal],
			CONVERT(DATE, [ fecha de nacimiento], 103) AS fecha_nacimiento,
			[ teléfono de contacto],
			[ teléfono de contacto emergencia],
			RTRIM(LTRIM(LOWER([ Nombre de la obra social o prepaga]))),
			[nro# de socio obra social/prepaga ],
			[teléfono de contacto de emergencia ]

			
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @path + ''',
            ''SELECT * FROM [Grupo Familiar$]''
        ) AS ExcelData;
    ';

    BEGIN TRY
        EXEC sp_executesql @sql;
        
        -- Mostrar los datos importados
        SELECT * FROM #tempGrupoFamiliar;
     
    END TRY
    BEGIN CATCH
        SELECT 
            'ERROR' AS Resultado,
            ERROR_MESSAGE() AS Mensaje,
            ERROR_LINE() AS LineaError,
            ERROR_NUMBER() AS CodigoError;
    END CATCH;
END;
GO



GO
EXEC usuarios.importarGrupoFamiliar @path = 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx'
