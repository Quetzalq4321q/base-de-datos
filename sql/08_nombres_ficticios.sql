-- Generado por scripts/generar_muestra.mjs a partir de las identidades ficticias versionadas en web/datos.js.
BEGIN;
CREATE TEMP TABLE rp_identidades (
    documento varchar(20) PRIMARY KEY, nombres varchar(60), apellidos varchar(60)
) ON COMMIT DROP;
INSERT INTO rp_identidades VALUES
    ('RPDEMO001', 'Lucía Elena', 'Salazar Vega'),
    ('RPDEMO002', 'Diego Alonso', 'Huamán Paredes'),
    ('RPDEMO003', 'Camila', 'Rojas Quispe'),
    ('RPDEMO004', 'Mateo Andrés', 'Cáceres Flores'),
    ('RPDEMO005', 'Valeria Inés', 'Mendoza Rivas'),
    ('RPDEMO006', 'Sebastián', 'Torres Zavaleta'),
    ('RPDEMO007', 'Adriana Milagros', 'Condori Núñez'),
    ('RPDEMO008', 'Nicolás', 'Chávez Medina'),
    ('RPDEMO009', 'Mariana Sofía', 'Vargas León'),
    ('RPDEMO010', 'Gabriel Andrés', 'Benavides Soto'),
    ('RPDEMO011', 'Renata', 'Ponce Aguilar'),
    ('RPDEMO012', 'Joaquín', 'Velásquez Campos');

DO $validar$
BEGIN
    IF (SELECT count(*) FROM salchipaperia.clientes c JOIN rp_identidades i
        ON c.tipo_documento = 'CE' AND c.numero_documento = i.documento) <> 12 THEN
        RAISE EXCEPTION 'Aplica primero la muestra de ventas RP01';
    END IF;
END;
$validar$;

UPDATE salchipaperia.clientes c SET nombres = i.nombres, apellidos = i.apellidos
FROM rp_identidades i
WHERE c.tipo_documento = 'CE' AND c.numero_documento = i.documento
  AND (c.nombres, c.apellidos) IS DISTINCT FROM (i.nombres, i.apellidos);

SELECT count(*) AS clientes_ficticios
FROM salchipaperia.clientes c JOIN rp_identidades i
ON c.tipo_documento = 'CE' AND c.numero_documento = i.documento
   AND (c.nombres, c.apellidos) = (i.nombres, i.apellidos);
COMMIT;
