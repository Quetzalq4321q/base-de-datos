BEGIN;
SET LOCAL search_path = salchipaperia, pg_catalog;

INSERT INTO clientes (nombres, apellidos, tipo_documento, numero_documento) VALUES
    ('Cliente', 'Demostración Uno', 'DNI', '00000001'),
    ('Cliente', 'Demostración Dos', 'DNI', '00000002');

INSERT INTO telefonos_cliente (id_cliente, numero)
SELECT c.id_cliente, t.numero
FROM clientes c
JOIN (VALUES ('00000001', '000000001'), ('00000001', '000000002'), ('00000002', '000000003'))
    AS t(documento, numero) ON c.tipo_documento = 'DNI' AND c.numero_documento = t.documento;

INSERT INTO categorias (id_categoria, nombre, descripcion, tipo_subtipo) VALUES
    ('S001', 'Snack', 'Salchipapas y frituras', 'snack'),
    ('B001', 'Bebida', 'Gaseosas y refrescos', 'bebida');

INSERT INTO productos (id_categoria, nombre, precio) VALUES
    ('S001', 'Salchipapa Clásica', 5.00),
    ('S001', 'Salchipapa Especial', 7.00),
    ('S001', 'Salchipapa Familiar', 18.00),
    ('B001', 'Coca-Cola 500 ml', 3.50),
    ('B001', 'Inca Kola 500 ml', 3.50),
    ('B001', 'Chicha Morada 1 L', 6.00);

INSERT INTO snacks (id_producto, porcion, tipo_papa)
SELECT p.id_producto, s.porcion, s.tipo_papa
FROM productos p
JOIN (VALUES ('Salchipapa Clásica', 'Personal', 'Papa Canchán'),
             ('Salchipapa Especial', 'Personal Grande', 'Papa Amarilla'),
             ('Salchipapa Familiar', 'Familiar', 'Papa Nativa')) AS s(nombre, porcion, tipo_papa)
    ON p.id_categoria = 'S001' AND p.nombre = s.nombre;

INSERT INTO bebidas (id_producto, volumen_ml, temperatura, envase)
SELECT p.id_producto, b.volumen_ml, b.temperatura, b.envase
FROM productos p
JOIN (VALUES ('Coca-Cola 500 ml', 500, 'Helada', 'Botella plástica'),
             ('Inca Kola 500 ml', 500, 'Sin helar', 'Botella plástica'),
             ('Chicha Morada 1 L', 1000, 'Helada', 'Jarra de vidrio'))
    AS b(nombre, volumen_ml, temperatura, envase) ON p.id_categoria = 'B001' AND p.nombre = b.nombre;

INSERT INTO tipos_comprobante (id_tipo_comprobante, nombre) VALUES
    ('TC01', 'Boleta de venta'), ('TC02', 'Factura');

INSERT INTO series_comprobante (serie, id_tipo_comprobante) VALUES
    ('B001', 'TC01'), ('F001', 'TC02');

INSERT INTO metodos_pago (id_metodo_pago, nombre, requiere_referencia) VALUES
    ('MP01', 'Efectivo', false), ('MP02', 'Yape', true),
    ('MP03', 'Plin', true), ('MP04', 'Tarjeta', true);

DO $$
DECLARE
    pedido bigint;
    comprobante bigint;
BEGIN
    INSERT INTO pedidos (id_cliente, fecha_pedido, tipo_pedido, estado)
    SELECT id_cliente, '2026-11-23 19:15:00-05'::timestamptz, 'En local', 'Entregado'
    FROM clientes WHERE tipo_documento = 'DNI' AND numero_documento = '00000001'
    RETURNING id_pedido INTO STRICT pedido;

    PERFORM agregar_item(pedido, id_producto, 2) FROM productos
    WHERE (id_categoria, nombre) IN (('S001', 'Salchipapa Especial'), ('B001', 'Coca-Cola 500 ml'));
    comprobante := emitir_comprobante(pedido, 'B001', 18, '2026-11-23 19:20:00-05');
    INSERT INTO pagos (id_comprobante, id_metodo_pago, monto, numero_operacion, fecha_pago) VALUES
        (comprobante, 'MP01', 10.00, NULL, '2026-11-23 19:20:05-05'),
        (comprobante, 'MP02', 11.00, 'DEMO-YP-01', '2026-11-23 19:20:30-05');

    INSERT INTO pedidos (id_cliente, fecha_pedido, tipo_pedido, estado)
    SELECT id_cliente, '2026-11-23 20:00:00-05'::timestamptz, 'Delivery', 'En Cocina'
    FROM clientes WHERE tipo_documento = 'DNI' AND numero_documento = '00000002'
    RETURNING id_pedido INTO STRICT pedido;

    PERFORM agregar_item(pedido, id_producto, 1) FROM productos
    WHERE (id_categoria, nombre) IN (('S001', 'Salchipapa Familiar'), ('B001', 'Chicha Morada 1 L'));
    comprobante := emitir_comprobante(pedido, 'B001', 18, '2026-11-23 20:02:00-05');
    INSERT INTO pagos (id_comprobante, id_metodo_pago, monto, numero_operacion, fecha_pago)
    VALUES (comprobante, 'MP03', 24.00, 'DEMO-PL-02', '2026-11-23 20:02:15-05');
END;
$$;

COMMIT;
