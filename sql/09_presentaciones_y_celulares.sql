-- Generado por scripts/generar_muestra.mjs. Solo modifica fichas ficticias de la muestra.
BEGIN;
SET LOCAL search_path = salchipaperia, pg_catalog;
SELECT pg_advisory_xact_lock(hashtext('salchipaperia.red_pepper.ventas_100.v1'));

CREATE TEMP TABLE rp_presentaciones (
    categoria varchar(10), nombre varchar(100), porcion varchar(30), PRIMARY KEY (categoria, nombre)
) ON COMMIT DROP;
INSERT INTO rp_presentaciones VALUES
    ('RPSAN', 'Triple clásico', 'Sánguche'),
    ('RPSAN', 'Triple mixto', 'Sánguche'),
    ('RPSAN', 'Triple de durazno', 'Sánguche'),
    ('RPSAN', 'Baguetino de pollo a la brasa', 'Baguetino'),
    ('RPEMP', 'Empanada de ají de gallina', 'Empanada'),
    ('RPEMP', 'Empanada de rocoto relleno', 'Empanada'),
    ('RPEMP', 'Empanada de lomo saltado', 'Empanada'),
    ('RPEMP', 'Empanada de pizza', 'Empanada'),
    ('RPEMP', 'Empanada de hawaiana', 'Empanada'),
    ('RPEMP', 'Empanada de queso', 'Empanada'),
    ('RPEMP', 'Empanada de triple', 'Empanada'),
    ('RPEMP', 'Empanada de chorizo', 'Empanada'),
    ('RPSAL', 'Salchicono', 'Cono'),
    ('RPSAL', 'Cono Mix', 'Cono'),
    ('RPSAL', 'Salchipapa clásica', 'Porción estándar'),
    ('RPSAL', 'Double Black', 'Porción estándar'),
    ('RPSAL', 'Choripapas', 'Porción estándar'),
    ('RPSAL', 'Salchibrasa', 'Porción estándar'),
    ('RPPLA', 'Salchichaufa', 'Al plato'),
    ('RPPLA', 'Mostrito con pechuga a la plancha', 'Al plato'),
    ('RPPLA', 'Jack Pepper', 'Al plato'),
    ('RPPLA', 'Cheese Pepper', 'Al plato'),
    ('RPCOM', 'Extrema', 'Bandeja para 4 personas'),
    ('RPCOM', 'La Gaucha', 'Para 4 personas'),
    ('RPHAM', 'Hamburguesa clásica de res', 'Hamburguesa con papas'),
    ('RPHAM', 'Hamburguesa clásica de pollo', 'Hamburguesa con papas'),
    ('RPHAM', 'Cheese Burguer de res', 'Hamburguesa con papas'),
    ('RPHAM', 'Cheese Burguer de pollo', 'Hamburguesa con papas'),
    ('RPHAM', 'La Royal de res', 'Hamburguesa con papas'),
    ('RPHAM', 'La Royal de pollo', 'Hamburguesa con papas'),
    ('RPHAM', 'Doble Burguer de res', 'Hamburguesa con papas'),
    ('RPHAM', 'Doble Burguer de pollo', 'Hamburguesa con papas');

CREATE TEMP TABLE rp_celulares (
    tipo_documento varchar(10), documento varchar(20), anterior varchar(16),
    numero varchar(9) NOT NULL UNIQUE CHECK (numero ~ '^9[0-9]{8}$'),
    PRIMARY KEY (tipo_documento, documento, anterior)
) ON COMMIT DROP;
INSERT INTO rp_celulares VALUES
    ('DNI', '00000001', '000000001', '906381472'),
    ('DNI', '00000001', '000000002', '934720615'),
    ('DNI', '00000002', '000000003', '972506183'),
    ('CE', 'RPDEMO001', '000000101', '931640728'),
    ('CE', 'RPDEMO002', '000000102', '964285317'),
    ('CE', 'RPDEMO003', '000000103', '927536041'),
    ('CE', 'RPDEMO004', '000000104', '982471635'),
    ('CE', 'RPDEMO005', '000000105', '956317284'),
    ('CE', 'RPDEMO006', '000000106', '913748562');

DO $validar$
BEGIN
    IF EXISTS (SELECT FROM rp_presentaciones f WHERE NOT EXISTS (
        SELECT FROM productos p JOIN snacks s USING (id_producto)
        WHERE p.id_categoria = f.categoria AND p.nombre = f.nombre
    )) THEN
        RAISE EXCEPTION 'Faltan presentaciones de la muestra RP01';
    END IF;

    IF EXISTS (SELECT FROM rp_celulares f WHERE (
        SELECT count(*) FROM clientes c JOIN telefonos_cliente t USING (id_cliente)
        WHERE c.tipo_documento = f.tipo_documento AND c.numero_documento = f.documento
          AND t.numero IN (f.anterior, f.numero)
    ) <> 1) THEN
        RAISE EXCEPTION 'Faltan celulares de la muestra o hay un número anterior y uno nuevo para la misma ficha';
    END IF;
END;
$validar$;

UPDATE snacks s SET porcion = f.porcion
FROM productos p JOIN rp_presentaciones f ON p.id_categoria = f.categoria AND p.nombre = f.nombre
WHERE s.id_producto = p.id_producto AND s.porcion IS DISTINCT FROM f.porcion;

UPDATE telefonos_cliente t SET numero = f.numero
FROM clientes c JOIN rp_celulares f
    ON c.tipo_documento = f.tipo_documento AND c.numero_documento = f.documento
WHERE t.id_cliente = c.id_cliente AND t.numero = f.anterior;

SELECT (SELECT count(*) FROM rp_presentaciones f
        JOIN productos p ON p.id_categoria = f.categoria AND p.nombre = f.nombre
        JOIN snacks s ON s.id_producto = p.id_producto AND s.porcion = f.porcion) AS presentaciones,
       (SELECT count(*) FROM rp_celulares f
        JOIN clientes c ON c.tipo_documento = f.tipo_documento AND c.numero_documento = f.documento
        JOIN telefonos_cliente t ON t.id_cliente = c.id_cliente AND t.numero = f.numero) AS celulares;
COMMIT;
