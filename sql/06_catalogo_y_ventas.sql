-- Generado por scripts/generar_muestra.mjs a partir de la muestra versionada en web/datos.js.
BEGIN;
SET LOCAL search_path = salchipaperia, pg_catalog;
SELECT pg_advisory_xact_lock(hashtext('salchipaperia.red_pepper.ventas_100.v1'));

-- La carta no especifica estos atributos. NULL representa un dato desconocido.
ALTER TABLE snacks ALTER COLUMN tipo_papa DROP NOT NULL, ALTER COLUMN incluye_cremas DROP NOT NULL;
ALTER TABLE bebidas ALTER COLUMN volumen_ml DROP NOT NULL,
    ALTER COLUMN temperatura DROP NOT NULL, ALTER COLUMN envase DROP NOT NULL;

CREATE OR REPLACE VIEW v_detalle_pedido AS
SELECT p.id_pedido, p.fecha_pedido, p.tipo_pedido, p.estado,
       prod.nombre AS producto, cat.nombre AS categoria,
       coalesce(s.porcion, nullif(concat_ws(' · ', b.volumen_ml::text || ' ml', b.envase), ''),
                'Presentación sin especificar') AS presentacion,
       d.cantidad, d.precio_unitario, d.cantidad * d.precio_unitario AS subtotal_linea
FROM detalle_pedido d
JOIN pedidos p USING (id_pedido)
JOIN productos prod USING (id_producto)
JOIN categorias cat USING (id_categoria)
LEFT JOIN snacks s USING (id_producto)
LEFT JOIN bebidas b USING (id_producto);

INSERT INTO categorias (id_categoria, nombre, tipo_subtipo) VALUES
    ('RPSAN', 'Sánguches', 'snack'),
    ('RPEMP', 'Empanadas', 'snack'),
    ('RPSAL', 'Salchipapas', 'snack'),
    ('RPPLA', 'Salchipapas al plato', 'snack'),
    ('RPCOM', 'Para compartir', 'snack'),
    ('RPHAM', 'Hamburguesas', 'snack'),
    ('RPBEB', 'Bebidas de la carta', 'bebida')
ON CONFLICT (id_categoria) DO NOTHING;

INSERT INTO clientes (nombres, apellidos, tipo_documento, numero_documento) VALUES
    ('Cliente', 'De prueba 01', 'CE', 'RPDEMO001'),
    ('Cliente', 'De prueba 02', 'CE', 'RPDEMO002'),
    ('Cliente', 'De prueba 03', 'CE', 'RPDEMO003'),
    ('Cliente', 'De prueba 04', 'CE', 'RPDEMO004'),
    ('Cliente', 'De prueba 05', 'CE', 'RPDEMO005'),
    ('Cliente', 'De prueba 06', 'CE', 'RPDEMO006'),
    ('Cliente', 'De prueba 07', 'CE', 'RPDEMO007'),
    ('Cliente', 'De prueba 08', 'CE', 'RPDEMO008'),
    ('Cliente', 'De prueba 09', 'CE', 'RPDEMO009'),
    ('Cliente', 'De prueba 10', 'CE', 'RPDEMO010'),
    ('Cliente', 'De prueba 11', 'CE', 'RPDEMO011'),
    ('Cliente', 'De prueba 12', 'CE', 'RPDEMO012')
ON CONFLICT (tipo_documento, numero_documento) DO NOTHING;

INSERT INTO telefonos_cliente (id_cliente, numero)
SELECT c.id_cliente, t.numero
FROM (VALUES
    ('RPDEMO001', '000000101'),
    ('RPDEMO002', '000000102'),
    ('RPDEMO003', '000000103'),
    ('RPDEMO004', '000000104'),
    ('RPDEMO005', '000000105'),
    ('RPDEMO006', '000000106')
) t(documento, numero)
JOIN clientes c ON c.tipo_documento = 'CE' AND c.numero_documento = t.documento
ON CONFLICT (id_cliente, numero) DO NOTHING;

CREATE TEMP TABLE rp_catalogo (
    ficha integer PRIMARY KEY, categoria varchar(10), nombre varchar(100), precio numeric(10,2),
    porcion varchar(30), tipo_papa varchar(40), incluye_cremas boolean,
    volumen_ml integer, temperatura varchar(20), envase varchar(30)
) ON COMMIT DROP;
INSERT INTO rp_catalogo VALUES
    (1, 'RPSAN', 'Triple clásico', 5.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (2, 'RPSAN', 'Triple mixto', 5.50, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (3, 'RPSAN', 'Triple de durazno', 6.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (4, 'RPSAN', 'Baguetino de pollo a la brasa', 7.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (5, 'RPEMP', 'Empanada de ají de gallina', 5.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (6, 'RPEMP', 'Empanada de rocoto relleno', 5.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (7, 'RPEMP', 'Empanada de lomo saltado', 5.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (8, 'RPEMP', 'Empanada de pizza', 5.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (9, 'RPEMP', 'Empanada de hawaiana', 5.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (10, 'RPEMP', 'Empanada de queso', 5.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (11, 'RPEMP', 'Empanada de triple', 5.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (12, 'RPEMP', 'Empanada de chorizo', 5.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (13, 'RPSAL', 'Salchicono', 5.00, 'Cono', NULL, true, NULL, NULL, NULL),
    (14, 'RPSAL', 'Cono Mix', 6.00, 'Cono', NULL, true, NULL, NULL, NULL),
    (15, 'RPSAL', 'Salchipapa clásica', 8.00, 'Porción individual', NULL, true, NULL, NULL, NULL),
    (16, 'RPSAL', 'Double Black', 9.00, 'Porción individual', NULL, true, NULL, NULL, NULL),
    (17, 'RPSAL', 'Choripapas', 10.00, 'Porción individual', NULL, true, NULL, NULL, NULL),
    (18, 'RPSAL', 'Salchibrasa', 10.00, 'Porción individual', NULL, true, NULL, NULL, NULL),
    (19, 'RPPLA', 'Salchichaufa', 12.00, 'Plato', NULL, true, NULL, NULL, NULL),
    (20, 'RPPLA', 'Mostrito con pechuga a la plancha', 16.00, 'Plato', NULL, NULL, NULL, NULL, NULL),
    (21, 'RPPLA', 'Jack Pepper', 14.00, 'Plato', NULL, NULL, NULL, NULL, NULL),
    (22, 'RPPLA', 'Cheese Pepper', 15.00, 'Plato', NULL, true, NULL, NULL, NULL),
    (23, 'RPCOM', 'Extrema', 30.00, 'Para 4 personas', NULL, NULL, NULL, NULL, NULL),
    (24, 'RPCOM', 'La Gaucha', 25.00, 'Para 4 personas', NULL, NULL, NULL, NULL, NULL),
    (25, 'RPHAM', 'Hamburguesa clásica de res', 8.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (26, 'RPHAM', 'Hamburguesa clásica de pollo', 8.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (27, 'RPHAM', 'Cheese Burguer de res', 9.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (28, 'RPHAM', 'Cheese Burguer de pollo', 9.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (29, 'RPHAM', 'La Royal de res', 10.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (30, 'RPHAM', 'La Royal de pollo', 10.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (31, 'RPHAM', 'Doble Burguer de res', 15.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (32, 'RPHAM', 'Doble Burguer de pollo', 15.00, 'Unidad', NULL, NULL, NULL, NULL, NULL),
    (33, 'RPBEB', 'Chicha morada', 3.00, NULL, NULL, NULL, NULL, NULL, NULL),
    (34, 'RPBEB', 'Maracuyá', 3.00, NULL, NULL, NULL, NULL, NULL, NULL),
    (35, 'RPBEB', 'Coca-Cola', 4.00, NULL, NULL, NULL, NULL, NULL, NULL),
    (36, 'RPBEB', 'Inca Kola', 4.00, NULL, NULL, NULL, NULL, NULL, NULL),
    (37, 'RPBEB', 'Fanta', 3.50, NULL, NULL, NULL, NULL, NULL, NULL),
    (38, 'RPBEB', 'Agua Cielo', 2.00, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO productos (id_categoria, nombre, precio)
SELECT categoria, nombre, precio FROM rp_catalogo
ON CONFLICT (id_categoria, nombre) DO NOTHING;

INSERT INTO snacks (id_producto, porcion, tipo_papa, incluye_cremas)
SELECT p.id_producto, d.porcion, d.tipo_papa, d.incluye_cremas
FROM rp_catalogo d JOIN productos p ON (p.id_categoria, p.nombre) = (d.categoria, d.nombre)
WHERE d.porcion IS NOT NULL ON CONFLICT (id_producto) DO NOTHING;

INSERT INTO bebidas (id_producto, volumen_ml, temperatura, envase)
SELECT p.id_producto, d.volumen_ml, d.temperatura, d.envase
FROM rp_catalogo d JOIN productos p ON (p.id_categoria, p.nombre) = (d.categoria, d.nombre)
WHERE d.porcion IS NULL ON CONFLICT (id_producto) DO NOTHING;

INSERT INTO series_comprobante (serie, id_tipo_comprobante) VALUES ('RP01', 'TC01')
ON CONFLICT (serie) DO NOTHING;

CREATE TEMP TABLE rp_ventas (
    orden integer PRIMARY KEY, documento varchar(20), fecha timestamptz, modalidad text,
    emision timestamptz, total numeric(10,2), detalle jsonb, abonos jsonb
) ON COMMIT DROP;
INSERT INTO rp_ventas VALUES
    (1, 'RPDEMO001', '2026-10-24T12:00:00-05:00', 'En local', '2026-10-24T17:02:00.000Z', 8.00, '[{"producto":1,"cantidad":1},{"producto":33,"cantidad":1}]', '[{"id_comprobante":1,"id_metodo_pago":"MP01","monto":"4.00","numero_operacion":null,"fecha_pago":"2026-10-24T17:02:30.000Z"},{"id_comprobante":1,"id_metodo_pago":"MP02","monto":"4.00","numero_operacion":"RP-DEMO-1-2","fecha_pago":"2026-10-24T17:03:00.000Z"}]'),
    (2, 'RPDEMO006', '2026-10-24T19:13:00-05:00', 'Para llevar', '2026-10-25T00:15:00.000Z', 17.00, '[{"producto":2,"cantidad":2},{"producto":33,"cantidad":2}]', '[{"id_comprobante":2,"id_metodo_pago":"MP02","monto":"17.00","numero_operacion":"RP-DEMO-2-1","fecha_pago":"2026-10-25T00:15:30.000Z"}]'),
    (3, 'RPDEMO011', '2026-10-24T17:26:00-05:00', 'Delivery', '2026-10-24T22:28:00.000Z', 21.00, '[{"producto":3,"cantidad":3},{"producto":34,"cantidad":1}]', '[{"id_comprobante":3,"id_metodo_pago":"MP03","monto":"21.00","numero_operacion":"RP-DEMO-3-1","fecha_pago":"2026-10-24T22:28:30.000Z"}]'),
    (4, 'RPDEMO004', '2026-10-24T15:39:00-05:00', 'En local', '2026-10-24T20:41:00.000Z', 13.00, '[{"producto":4,"cantidad":1},{"producto":34,"cantidad":2}]', '[{"id_comprobante":4,"id_metodo_pago":"MP04","monto":"13.00","numero_operacion":"RP-DEMO-4-1","fecha_pago":"2026-10-24T20:41:30.000Z"}]'),
    (5, 'RPDEMO009', '2026-10-25T13:52:00-05:00', 'Para llevar', '2026-10-25T18:54:00.000Z', 14.00, '[{"producto":5,"cantidad":2},{"producto":35,"cantidad":1}]', '[{"id_comprobante":5,"id_metodo_pago":"MP01","monto":"14.00","numero_operacion":null,"fecha_pago":"2026-10-25T18:54:30.000Z"}]'),
    (6, 'RPDEMO002', '2026-10-25T20:05:00-05:00', 'Delivery', '2026-10-26T01:07:00.000Z', 23.00, '[{"producto":6,"cantidad":3},{"producto":35,"cantidad":2}]', '[{"id_comprobante":6,"id_metodo_pago":"MP01","monto":"11.00","numero_operacion":null,"fecha_pago":"2026-10-26T01:07:30.000Z"},{"id_comprobante":6,"id_metodo_pago":"MP02","monto":"12.00","numero_operacion":"RP-DEMO-6-2","fecha_pago":"2026-10-26T01:08:00.000Z"}]'),
    (7, 'RPDEMO007', '2026-10-25T18:18:00-05:00', 'En local', '2026-10-25T23:20:00.000Z', 5.00, '[{"producto":7,"cantidad":1}]', '[{"id_comprobante":7,"id_metodo_pago":"MP03","monto":"5.00","numero_operacion":"RP-DEMO-7-1","fecha_pago":"2026-10-25T23:20:30.000Z"}]'),
    (8, 'RPDEMO012', '2026-10-26T16:31:00-05:00', 'Para llevar', '2026-10-26T21:33:00.000Z', 18.00, '[{"producto":8,"cantidad":2},{"producto":36,"cantidad":2}]', '[{"id_comprobante":8,"id_metodo_pago":"MP04","monto":"18.00","numero_operacion":"RP-DEMO-8-1","fecha_pago":"2026-10-26T21:33:30.000Z"}]'),
    (9, 'RPDEMO005', '2026-10-26T14:44:00-05:00', 'Delivery', '2026-10-26T19:46:00.000Z', 18.50, '[{"producto":9,"cantidad":3},{"producto":37,"cantidad":1}]', '[{"id_comprobante":9,"id_metodo_pago":"MP01","monto":"18.50","numero_operacion":null,"fecha_pago":"2026-10-26T19:46:30.000Z"}]'),
    (10, 'RPDEMO010', '2026-10-26T12:57:00-05:00', 'En local', '2026-10-26T17:59:00.000Z', 12.00, '[{"producto":10,"cantidad":1},{"producto":37,"cantidad":2}]', '[{"id_comprobante":10,"id_metodo_pago":"MP02","monto":"12.00","numero_operacion":"RP-DEMO-10-1","fecha_pago":"2026-10-26T17:59:30.000Z"}]'),
    (11, 'RPDEMO003', '2026-10-27T19:10:00-05:00', 'Para llevar', '2026-10-28T00:12:00.000Z', 12.00, '[{"producto":11,"cantidad":2},{"producto":38,"cantidad":1}]', '[{"id_comprobante":11,"id_metodo_pago":"MP01","monto":"6.00","numero_operacion":null,"fecha_pago":"2026-10-28T00:12:30.000Z"},{"id_comprobante":11,"id_metodo_pago":"MP02","monto":"6.00","numero_operacion":"RP-DEMO-11-2","fecha_pago":"2026-10-28T00:13:00.000Z"}]'),
    (12, 'RPDEMO008', '2026-10-27T17:23:00-05:00', 'Delivery', '2026-10-27T22:25:00.000Z', 19.00, '[{"producto":12,"cantidad":3},{"producto":38,"cantidad":2}]', '[{"id_comprobante":12,"id_metodo_pago":"MP04","monto":"19.00","numero_operacion":"RP-DEMO-12-1","fecha_pago":"2026-10-27T22:25:30.000Z"}]'),
    (13, 'RPDEMO001', '2026-10-27T15:36:00-05:00', 'En local', '2026-10-27T20:38:00.000Z', 8.00, '[{"producto":13,"cantidad":1},{"producto":33,"cantidad":1}]', '[{"id_comprobante":13,"id_metodo_pago":"MP01","monto":"8.00","numero_operacion":null,"fecha_pago":"2026-10-27T20:38:30.000Z"}]'),
    (14, 'RPDEMO006', '2026-10-27T13:49:00-05:00', 'Para llevar', '2026-10-27T18:51:00.000Z', 12.00, '[{"producto":14,"cantidad":2}]', '[{"id_comprobante":14,"id_metodo_pago":"MP02","monto":"12.00","numero_operacion":"RP-DEMO-14-1","fecha_pago":"2026-10-27T18:51:30.000Z"}]'),
    (15, 'RPDEMO011', '2026-10-28T20:02:00-05:00', 'Delivery', '2026-10-29T01:04:00.000Z', 27.00, '[{"producto":15,"cantidad":3},{"producto":34,"cantidad":1}]', '[{"id_comprobante":15,"id_metodo_pago":"MP03","monto":"27.00","numero_operacion":"RP-DEMO-15-1","fecha_pago":"2026-10-29T01:04:30.000Z"}]'),
    (16, 'RPDEMO004', '2026-10-28T18:15:00-05:00', 'En local', '2026-10-28T23:17:00.000Z', 15.00, '[{"producto":16,"cantidad":1},{"producto":34,"cantidad":2}]', '[{"id_comprobante":16,"id_metodo_pago":"MP01","monto":"7.00","numero_operacion":null,"fecha_pago":"2026-10-28T23:17:30.000Z"},{"id_comprobante":16,"id_metodo_pago":"MP02","monto":"8.00","numero_operacion":"RP-DEMO-16-2","fecha_pago":"2026-10-28T23:18:00.000Z"}]'),
    (17, 'RPDEMO009', '2026-10-28T16:28:00-05:00', 'Para llevar', '2026-10-28T21:30:00.000Z', 24.00, '[{"producto":17,"cantidad":2},{"producto":35,"cantidad":1}]', '[{"id_comprobante":17,"id_metodo_pago":"MP01","monto":"24.00","numero_operacion":null,"fecha_pago":"2026-10-28T21:30:30.000Z"}]'),
    (18, 'RPDEMO002', '2026-10-29T14:41:00-05:00', 'Delivery', '2026-10-29T19:43:00.000Z', 38.00, '[{"producto":18,"cantidad":3},{"producto":35,"cantidad":2}]', '[{"id_comprobante":18,"id_metodo_pago":"MP02","monto":"38.00","numero_operacion":"RP-DEMO-18-1","fecha_pago":"2026-10-29T19:43:30.000Z"}]'),
    (19, 'RPDEMO007', '2026-10-29T12:54:00-05:00', 'En local', '2026-10-29T17:56:00.000Z', 16.00, '[{"producto":19,"cantidad":1},{"producto":36,"cantidad":1}]', '[{"id_comprobante":19,"id_metodo_pago":"MP03","monto":"16.00","numero_operacion":"RP-DEMO-19-1","fecha_pago":"2026-10-29T17:56:30.000Z"}]'),
    (20, 'RPDEMO012', '2026-10-29T19:07:00-05:00', 'Para llevar', '2026-10-30T00:09:00.000Z', 40.00, '[{"producto":20,"cantidad":2},{"producto":36,"cantidad":2}]', '[{"id_comprobante":20,"id_metodo_pago":"MP04","monto":"40.00","numero_operacion":"RP-DEMO-20-1","fecha_pago":"2026-10-30T00:09:30.000Z"}]'),
    (21, 'RPDEMO005', '2026-10-30T17:20:00-05:00', 'Delivery', '2026-10-30T22:22:00.000Z', 42.00, '[{"producto":21,"cantidad":3}]', '[{"id_comprobante":21,"id_metodo_pago":"MP01","monto":"21.00","numero_operacion":null,"fecha_pago":"2026-10-30T22:22:30.000Z"},{"id_comprobante":21,"id_metodo_pago":"MP02","monto":"21.00","numero_operacion":"RP-DEMO-21-2","fecha_pago":"2026-10-30T22:23:00.000Z"}]'),
    (22, 'RPDEMO010', '2026-10-30T15:33:00-05:00', 'En local', '2026-10-30T20:35:00.000Z', 22.00, '[{"producto":22,"cantidad":1},{"producto":37,"cantidad":2}]', '[{"id_comprobante":22,"id_metodo_pago":"MP02","monto":"22.00","numero_operacion":"RP-DEMO-22-1","fecha_pago":"2026-10-30T20:35:30.000Z"}]'),
    (23, 'RPDEMO003', '2026-10-30T13:46:00-05:00', 'Para llevar', '2026-10-30T18:48:00.000Z', 62.00, '[{"producto":23,"cantidad":2},{"producto":38,"cantidad":1}]', '[{"id_comprobante":23,"id_metodo_pago":"MP03","monto":"62.00","numero_operacion":"RP-DEMO-23-1","fecha_pago":"2026-10-30T18:48:30.000Z"}]'),
    (24, 'RPDEMO008', '2026-10-30T20:59:00-05:00', 'Delivery', '2026-10-31T02:01:00.000Z', 79.00, '[{"producto":24,"cantidad":3},{"producto":38,"cantidad":2}]', '[{"id_comprobante":24,"id_metodo_pago":"MP04","monto":"79.00","numero_operacion":"RP-DEMO-24-1","fecha_pago":"2026-10-31T02:01:30.000Z"}]'),
    (25, 'RPDEMO001', '2026-10-31T18:12:00-05:00', 'En local', '2026-10-31T23:14:00.000Z', 11.00, '[{"producto":25,"cantidad":1},{"producto":33,"cantidad":1}]', '[{"id_comprobante":25,"id_metodo_pago":"MP01","monto":"11.00","numero_operacion":null,"fecha_pago":"2026-10-31T23:14:30.000Z"}]'),
    (26, 'RPDEMO006', '2026-10-31T16:25:00-05:00', 'Para llevar', '2026-10-31T21:27:00.000Z', 22.00, '[{"producto":26,"cantidad":2},{"producto":33,"cantidad":2}]', '[{"id_comprobante":26,"id_metodo_pago":"MP01","monto":"11.00","numero_operacion":null,"fecha_pago":"2026-10-31T21:27:30.000Z"},{"id_comprobante":26,"id_metodo_pago":"MP02","monto":"11.00","numero_operacion":"RP-DEMO-26-2","fecha_pago":"2026-10-31T21:28:00.000Z"}]'),
    (27, 'RPDEMO011', '2026-10-31T14:38:00-05:00', 'Delivery', '2026-10-31T19:40:00.000Z', 30.00, '[{"producto":27,"cantidad":3},{"producto":34,"cantidad":1}]', '[{"id_comprobante":27,"id_metodo_pago":"MP03","monto":"30.00","numero_operacion":"RP-DEMO-27-1","fecha_pago":"2026-10-31T19:40:30.000Z"}]'),
    (28, 'RPDEMO004', '2026-11-01T12:51:00-05:00', 'En local', '2026-11-01T17:53:00.000Z', 9.00, '[{"producto":28,"cantidad":1}]', '[{"id_comprobante":28,"id_metodo_pago":"MP04","monto":"9.00","numero_operacion":"RP-DEMO-28-1","fecha_pago":"2026-11-01T17:53:30.000Z"}]'),
    (29, 'RPDEMO009', '2026-11-01T19:04:00-05:00', 'Para llevar', '2026-11-02T00:06:00.000Z', 24.00, '[{"producto":29,"cantidad":2},{"producto":35,"cantidad":1}]', '[{"id_comprobante":29,"id_metodo_pago":"MP01","monto":"24.00","numero_operacion":null,"fecha_pago":"2026-11-02T00:06:30.000Z"}]'),
    (30, 'RPDEMO002', '2026-11-01T17:17:00-05:00', 'Delivery', '2026-11-01T22:19:00.000Z', 38.00, '[{"producto":30,"cantidad":3},{"producto":35,"cantidad":2}]', '[{"id_comprobante":30,"id_metodo_pago":"MP02","monto":"38.00","numero_operacion":"RP-DEMO-30-1","fecha_pago":"2026-11-01T22:19:30.000Z"}]'),
    (31, 'RPDEMO007', '2026-11-02T15:30:00-05:00', 'En local', '2026-11-02T20:32:00.000Z', 19.00, '[{"producto":31,"cantidad":1},{"producto":36,"cantidad":1}]', '[{"id_comprobante":31,"id_metodo_pago":"MP01","monto":"9.00","numero_operacion":null,"fecha_pago":"2026-11-02T20:32:30.000Z"},{"id_comprobante":31,"id_metodo_pago":"MP02","monto":"10.00","numero_operacion":"RP-DEMO-31-2","fecha_pago":"2026-11-02T20:33:00.000Z"}]'),
    (32, 'RPDEMO012', '2026-11-02T13:43:00-05:00', 'Para llevar', '2026-11-02T18:45:00.000Z', 38.00, '[{"producto":32,"cantidad":2},{"producto":36,"cantidad":2}]', '[{"id_comprobante":32,"id_metodo_pago":"MP04","monto":"38.00","numero_operacion":"RP-DEMO-32-1","fecha_pago":"2026-11-02T18:45:30.000Z"}]'),
    (33, 'RPDEMO005', '2026-11-02T20:56:00-05:00', 'Delivery', '2026-11-03T01:58:00.000Z', 18.50, '[{"producto":1,"cantidad":3},{"producto":37,"cantidad":1}]', '[{"id_comprobante":33,"id_metodo_pago":"MP01","monto":"18.50","numero_operacion":null,"fecha_pago":"2026-11-03T01:58:30.000Z"}]'),
    (34, 'RPDEMO010', '2026-11-02T18:09:00-05:00', 'En local', '2026-11-02T23:11:00.000Z', 12.50, '[{"producto":2,"cantidad":1},{"producto":37,"cantidad":2}]', '[{"id_comprobante":34,"id_metodo_pago":"MP02","monto":"12.50","numero_operacion":"RP-DEMO-34-1","fecha_pago":"2026-11-02T23:11:30.000Z"}]'),
    (35, 'RPDEMO003', '2026-11-03T16:22:00-05:00', 'Para llevar', '2026-11-03T21:24:00.000Z', 12.00, '[{"producto":3,"cantidad":2}]', '[{"id_comprobante":35,"id_metodo_pago":"MP03","monto":"12.00","numero_operacion":"RP-DEMO-35-1","fecha_pago":"2026-11-03T21:24:30.000Z"}]'),
    (36, 'RPDEMO008', '2026-11-03T14:35:00-05:00', 'Delivery', '2026-11-03T19:37:00.000Z', 25.00, '[{"producto":4,"cantidad":3},{"producto":38,"cantidad":2}]', '[{"id_comprobante":36,"id_metodo_pago":"MP01","monto":"12.00","numero_operacion":null,"fecha_pago":"2026-11-03T19:37:30.000Z"},{"id_comprobante":36,"id_metodo_pago":"MP02","monto":"13.00","numero_operacion":"RP-DEMO-36-2","fecha_pago":"2026-11-03T19:38:00.000Z"}]'),
    (37, 'RPDEMO001', '2026-11-03T12:48:00-05:00', 'En local', '2026-11-03T17:50:00.000Z', 8.00, '[{"producto":5,"cantidad":1},{"producto":33,"cantidad":1}]', '[{"id_comprobante":37,"id_metodo_pago":"MP01","monto":"8.00","numero_operacion":null,"fecha_pago":"2026-11-03T17:50:30.000Z"}]'),
    (38, 'RPDEMO006', '2026-11-04T19:01:00-05:00', 'Para llevar', '2026-11-05T00:03:00.000Z', 16.00, '[{"producto":6,"cantidad":2},{"producto":33,"cantidad":2}]', '[{"id_comprobante":38,"id_metodo_pago":"MP02","monto":"16.00","numero_operacion":"RP-DEMO-38-1","fecha_pago":"2026-11-05T00:03:30.000Z"}]'),
    (39, 'RPDEMO011', '2026-11-04T17:14:00-05:00', 'Delivery', '2026-11-04T22:16:00.000Z', 18.00, '[{"producto":7,"cantidad":3},{"producto":34,"cantidad":1}]', '[{"id_comprobante":39,"id_metodo_pago":"MP03","monto":"18.00","numero_operacion":"RP-DEMO-39-1","fecha_pago":"2026-11-04T22:16:30.000Z"}]'),
    (40, 'RPDEMO004', '2026-11-04T15:27:00-05:00', 'En local', '2026-11-04T20:29:00.000Z', 11.00, '[{"producto":8,"cantidad":1},{"producto":34,"cantidad":2}]', '[{"id_comprobante":40,"id_metodo_pago":"MP04","monto":"11.00","numero_operacion":"RP-DEMO-40-1","fecha_pago":"2026-11-04T20:29:30.000Z"}]'),
    (41, 'RPDEMO009', '2026-11-05T13:40:00-05:00', 'Para llevar', '2026-11-05T18:42:00.000Z', 14.00, '[{"producto":9,"cantidad":2},{"producto":35,"cantidad":1}]', '[{"id_comprobante":41,"id_metodo_pago":"MP01","monto":"7.00","numero_operacion":null,"fecha_pago":"2026-11-05T18:42:30.000Z"},{"id_comprobante":41,"id_metodo_pago":"MP02","monto":"7.00","numero_operacion":"RP-DEMO-41-2","fecha_pago":"2026-11-05T18:43:00.000Z"}]'),
    (42, 'RPDEMO002', '2026-11-05T20:53:00-05:00', 'Delivery', '2026-11-06T01:55:00.000Z', 15.00, '[{"producto":10,"cantidad":3}]', '[{"id_comprobante":42,"id_metodo_pago":"MP02","monto":"15.00","numero_operacion":"RP-DEMO-42-1","fecha_pago":"2026-11-06T01:55:30.000Z"}]'),
    (43, 'RPDEMO007', '2026-11-05T18:06:00-05:00', 'En local', '2026-11-05T23:08:00.000Z', 9.00, '[{"producto":11,"cantidad":1},{"producto":36,"cantidad":1}]', '[{"id_comprobante":43,"id_metodo_pago":"MP03","monto":"9.00","numero_operacion":"RP-DEMO-43-1","fecha_pago":"2026-11-05T23:08:30.000Z"}]'),
    (44, 'RPDEMO012', '2026-11-05T16:19:00-05:00', 'Para llevar', '2026-11-05T21:21:00.000Z', 18.00, '[{"producto":12,"cantidad":2},{"producto":36,"cantidad":2}]', '[{"id_comprobante":44,"id_metodo_pago":"MP04","monto":"18.00","numero_operacion":"RP-DEMO-44-1","fecha_pago":"2026-11-05T21:21:30.000Z"}]'),
    (45, 'RPDEMO005', '2026-11-06T14:32:00-05:00', 'Delivery', '2026-11-06T19:34:00.000Z', 18.50, '[{"producto":13,"cantidad":3},{"producto":37,"cantidad":1}]', '[{"id_comprobante":45,"id_metodo_pago":"MP01","monto":"18.50","numero_operacion":null,"fecha_pago":"2026-11-06T19:34:30.000Z"}]'),
    (46, 'RPDEMO010', '2026-11-06T12:45:00-05:00', 'En local', '2026-11-06T17:47:00.000Z', 13.00, '[{"producto":14,"cantidad":1},{"producto":37,"cantidad":2}]', '[{"id_comprobante":46,"id_metodo_pago":"MP01","monto":"6.00","numero_operacion":null,"fecha_pago":"2026-11-06T17:47:30.000Z"},{"id_comprobante":46,"id_metodo_pago":"MP02","monto":"7.00","numero_operacion":"RP-DEMO-46-2","fecha_pago":"2026-11-06T17:48:00.000Z"}]'),
    (47, 'RPDEMO003', '2026-11-06T19:58:00-05:00', 'Para llevar', '2026-11-07T01:00:00.000Z', 18.00, '[{"producto":15,"cantidad":2},{"producto":38,"cantidad":1}]', '[{"id_comprobante":47,"id_metodo_pago":"MP03","monto":"18.00","numero_operacion":"RP-DEMO-47-1","fecha_pago":"2026-11-07T01:00:30.000Z"}]'),
    (48, 'RPDEMO008', '2026-11-07T17:11:00-05:00', 'Delivery', '2026-11-07T22:13:00.000Z', 31.00, '[{"producto":16,"cantidad":3},{"producto":38,"cantidad":2}]', '[{"id_comprobante":48,"id_metodo_pago":"MP04","monto":"31.00","numero_operacion":"RP-DEMO-48-1","fecha_pago":"2026-11-07T22:13:30.000Z"}]'),
    (49, 'RPDEMO001', '2026-11-07T15:24:00-05:00', 'En local', '2026-11-07T20:26:00.000Z', 10.00, '[{"producto":17,"cantidad":1}]', '[{"id_comprobante":49,"id_metodo_pago":"MP01","monto":"10.00","numero_operacion":null,"fecha_pago":"2026-11-07T20:26:30.000Z"}]'),
    (50, 'RPDEMO006', '2026-11-07T13:37:00-05:00', 'Para llevar', '2026-11-07T18:39:00.000Z', 26.00, '[{"producto":18,"cantidad":2},{"producto":33,"cantidad":2}]', '[{"id_comprobante":50,"id_metodo_pago":"MP02","monto":"26.00","numero_operacion":"RP-DEMO-50-1","fecha_pago":"2026-11-07T18:39:30.000Z"}]'),
    (51, 'RPDEMO011', '2026-11-08T20:50:00-05:00', 'Delivery', '2026-11-09T01:52:00.000Z', 39.00, '[{"producto":19,"cantidad":3},{"producto":34,"cantidad":1}]', '[{"id_comprobante":51,"id_metodo_pago":"MP01","monto":"19.00","numero_operacion":null,"fecha_pago":"2026-11-09T01:52:30.000Z"},{"id_comprobante":51,"id_metodo_pago":"MP02","monto":"20.00","numero_operacion":"RP-DEMO-51-2","fecha_pago":"2026-11-09T01:53:00.000Z"}]'),
    (52, 'RPDEMO004', '2026-11-08T18:03:00-05:00', 'En local', '2026-11-08T23:05:00.000Z', 22.00, '[{"producto":20,"cantidad":1},{"producto":34,"cantidad":2}]', '[{"id_comprobante":52,"id_metodo_pago":"MP04","monto":"22.00","numero_operacion":"RP-DEMO-52-1","fecha_pago":"2026-11-08T23:05:30.000Z"}]'),
    (53, 'RPDEMO009', '2026-11-08T16:16:00-05:00', 'Para llevar', '2026-11-08T21:18:00.000Z', 32.00, '[{"producto":21,"cantidad":2},{"producto":35,"cantidad":1}]', '[{"id_comprobante":53,"id_metodo_pago":"MP01","monto":"32.00","numero_operacion":null,"fecha_pago":"2026-11-08T21:18:30.000Z"}]'),
    (54, 'RPDEMO002', '2026-11-08T14:29:00-05:00', 'Delivery', '2026-11-08T19:31:00.000Z', 53.00, '[{"producto":22,"cantidad":3},{"producto":35,"cantidad":2}]', '[{"id_comprobante":54,"id_metodo_pago":"MP02","monto":"53.00","numero_operacion":"RP-DEMO-54-1","fecha_pago":"2026-11-08T19:31:30.000Z"}]'),
    (55, 'RPDEMO007', '2026-11-09T12:42:00-05:00', 'En local', '2026-11-09T17:44:00.000Z', 34.00, '[{"producto":23,"cantidad":1},{"producto":36,"cantidad":1}]', '[{"id_comprobante":55,"id_metodo_pago":"MP03","monto":"34.00","numero_operacion":"RP-DEMO-55-1","fecha_pago":"2026-11-09T17:44:30.000Z"}]'),
    (56, 'RPDEMO012', '2026-11-09T19:55:00-05:00', 'Para llevar', '2026-11-10T00:57:00.000Z', 50.00, '[{"producto":24,"cantidad":2}]', '[{"id_comprobante":56,"id_metodo_pago":"MP01","monto":"25.00","numero_operacion":null,"fecha_pago":"2026-11-10T00:57:30.000Z"},{"id_comprobante":56,"id_metodo_pago":"MP02","monto":"25.00","numero_operacion":"RP-DEMO-56-2","fecha_pago":"2026-11-10T00:58:00.000Z"}]'),
    (57, 'RPDEMO005', '2026-11-09T17:08:00-05:00', 'Delivery', '2026-11-09T22:10:00.000Z', 27.50, '[{"producto":25,"cantidad":3},{"producto":37,"cantidad":1}]', '[{"id_comprobante":57,"id_metodo_pago":"MP01","monto":"27.50","numero_operacion":null,"fecha_pago":"2026-11-09T22:10:30.000Z"}]'),
    (58, 'RPDEMO010', '2026-11-10T15:21:00-05:00', 'En local', '2026-11-10T20:23:00.000Z', 15.00, '[{"producto":26,"cantidad":1},{"producto":37,"cantidad":2}]', '[{"id_comprobante":58,"id_metodo_pago":"MP02","monto":"15.00","numero_operacion":"RP-DEMO-58-1","fecha_pago":"2026-11-10T20:23:30.000Z"}]'),
    (59, 'RPDEMO003', '2026-11-10T13:34:00-05:00', 'Para llevar', '2026-11-10T18:36:00.000Z', 20.00, '[{"producto":27,"cantidad":2},{"producto":38,"cantidad":1}]', '[{"id_comprobante":59,"id_metodo_pago":"MP03","monto":"20.00","numero_operacion":"RP-DEMO-59-1","fecha_pago":"2026-11-10T18:36:30.000Z"}]'),
    (60, 'RPDEMO008', '2026-11-10T20:47:00-05:00', 'Delivery', '2026-11-11T01:49:00.000Z', 31.00, '[{"producto":28,"cantidad":3},{"producto":38,"cantidad":2}]', '[{"id_comprobante":60,"id_metodo_pago":"MP04","monto":"31.00","numero_operacion":"RP-DEMO-60-1","fecha_pago":"2026-11-11T01:49:30.000Z"}]'),
    (61, 'RPDEMO001', '2026-11-11T18:00:00-05:00', 'En local', '2026-11-11T23:02:00.000Z', 13.00, '[{"producto":29,"cantidad":1},{"producto":33,"cantidad":1}]', '[{"id_comprobante":61,"id_metodo_pago":"MP01","monto":"6.00","numero_operacion":null,"fecha_pago":"2026-11-11T23:02:30.000Z"},{"id_comprobante":61,"id_metodo_pago":"MP02","monto":"7.00","numero_operacion":"RP-DEMO-61-2","fecha_pago":"2026-11-11T23:03:00.000Z"}]'),
    (62, 'RPDEMO006', '2026-11-11T16:13:00-05:00', 'Para llevar', '2026-11-11T21:15:00.000Z', 26.00, '[{"producto":30,"cantidad":2},{"producto":33,"cantidad":2}]', '[{"id_comprobante":62,"id_metodo_pago":"MP02","monto":"26.00","numero_operacion":"RP-DEMO-62-1","fecha_pago":"2026-11-11T21:15:30.000Z"}]'),
    (63, 'RPDEMO011', '2026-11-11T14:26:00-05:00', 'Delivery', '2026-11-11T19:28:00.000Z', 45.00, '[{"producto":31,"cantidad":3}]', '[{"id_comprobante":63,"id_metodo_pago":"MP03","monto":"45.00","numero_operacion":"RP-DEMO-63-1","fecha_pago":"2026-11-11T19:28:30.000Z"}]'),
    (64, 'RPDEMO004', '2026-11-11T12:39:00-05:00', 'En local', '2026-11-11T17:41:00.000Z', 21.00, '[{"producto":32,"cantidad":1},{"producto":34,"cantidad":2}]', '[{"id_comprobante":64,"id_metodo_pago":"MP04","monto":"21.00","numero_operacion":"RP-DEMO-64-1","fecha_pago":"2026-11-11T17:41:30.000Z"}]'),
    (65, 'RPDEMO009', '2026-11-12T19:52:00-05:00', 'Para llevar', '2026-11-13T00:54:00.000Z', 14.00, '[{"producto":1,"cantidad":2},{"producto":35,"cantidad":1}]', '[{"id_comprobante":65,"id_metodo_pago":"MP01","monto":"14.00","numero_operacion":null,"fecha_pago":"2026-11-13T00:54:30.000Z"}]'),
    (66, 'RPDEMO002', '2026-11-12T17:05:00-05:00', 'Delivery', '2026-11-12T22:07:00.000Z', 24.50, '[{"producto":2,"cantidad":3},{"producto":35,"cantidad":2}]', '[{"id_comprobante":66,"id_metodo_pago":"MP01","monto":"12.00","numero_operacion":null,"fecha_pago":"2026-11-12T22:07:30.000Z"},{"id_comprobante":66,"id_metodo_pago":"MP02","monto":"12.50","numero_operacion":"RP-DEMO-66-2","fecha_pago":"2026-11-12T22:08:00.000Z"}]'),
    (67, 'RPDEMO007', '2026-11-12T15:18:00-05:00', 'En local', '2026-11-12T20:20:00.000Z', 10.00, '[{"producto":3,"cantidad":1},{"producto":36,"cantidad":1}]', '[{"id_comprobante":67,"id_metodo_pago":"MP03","monto":"10.00","numero_operacion":"RP-DEMO-67-1","fecha_pago":"2026-11-12T20:20:30.000Z"}]'),
    (68, 'RPDEMO012', '2026-11-13T13:31:00-05:00', 'Para llevar', '2026-11-13T18:33:00.000Z', 22.00, '[{"producto":4,"cantidad":2},{"producto":36,"cantidad":2}]', '[{"id_comprobante":68,"id_metodo_pago":"MP04","monto":"22.00","numero_operacion":"RP-DEMO-68-1","fecha_pago":"2026-11-13T18:33:30.000Z"}]'),
    (69, 'RPDEMO005', '2026-11-13T20:44:00-05:00', 'Delivery', '2026-11-14T01:46:00.000Z', 18.50, '[{"producto":5,"cantidad":3},{"producto":37,"cantidad":1}]', '[{"id_comprobante":69,"id_metodo_pago":"MP01","monto":"18.50","numero_operacion":null,"fecha_pago":"2026-11-14T01:46:30.000Z"}]'),
    (70, 'RPDEMO010', '2026-11-13T18:57:00-05:00', 'En local', '2026-11-13T23:59:00.000Z', 5.00, '[{"producto":6,"cantidad":1}]', '[{"id_comprobante":70,"id_metodo_pago":"MP02","monto":"5.00","numero_operacion":"RP-DEMO-70-1","fecha_pago":"2026-11-13T23:59:30.000Z"}]'),
    (71, 'RPDEMO003', '2026-11-14T16:10:00-05:00', 'Para llevar', '2026-11-14T21:12:00.000Z', 12.00, '[{"producto":7,"cantidad":2},{"producto":38,"cantidad":1}]', '[{"id_comprobante":71,"id_metodo_pago":"MP01","monto":"6.00","numero_operacion":null,"fecha_pago":"2026-11-14T21:12:30.000Z"},{"id_comprobante":71,"id_metodo_pago":"MP02","monto":"6.00","numero_operacion":"RP-DEMO-71-2","fecha_pago":"2026-11-14T21:13:00.000Z"}]'),
    (72, 'RPDEMO008', '2026-11-14T14:23:00-05:00', 'Delivery', '2026-11-14T19:25:00.000Z', 19.00, '[{"producto":8,"cantidad":3},{"producto":38,"cantidad":2}]', '[{"id_comprobante":72,"id_metodo_pago":"MP04","monto":"19.00","numero_operacion":"RP-DEMO-72-1","fecha_pago":"2026-11-14T19:25:30.000Z"}]'),
    (73, 'RPDEMO001', '2026-11-14T12:36:00-05:00', 'En local', '2026-11-14T17:38:00.000Z', 8.00, '[{"producto":9,"cantidad":1},{"producto":33,"cantidad":1}]', '[{"id_comprobante":73,"id_metodo_pago":"MP01","monto":"8.00","numero_operacion":null,"fecha_pago":"2026-11-14T17:38:30.000Z"}]'),
    (74, 'RPDEMO006', '2026-11-14T19:49:00-05:00', 'Para llevar', '2026-11-15T00:51:00.000Z', 16.00, '[{"producto":10,"cantidad":2},{"producto":33,"cantidad":2}]', '[{"id_comprobante":74,"id_metodo_pago":"MP02","monto":"16.00","numero_operacion":"RP-DEMO-74-1","fecha_pago":"2026-11-15T00:51:30.000Z"}]'),
    (75, 'RPDEMO011', '2026-11-15T17:02:00-05:00', 'Delivery', '2026-11-15T22:04:00.000Z', 18.00, '[{"producto":11,"cantidad":3},{"producto":34,"cantidad":1}]', '[{"id_comprobante":75,"id_metodo_pago":"MP03","monto":"18.00","numero_operacion":"RP-DEMO-75-1","fecha_pago":"2026-11-15T22:04:30.000Z"}]'),
    (76, 'RPDEMO004', '2026-11-15T15:15:00-05:00', 'En local', '2026-11-15T20:17:00.000Z', 11.00, '[{"producto":12,"cantidad":1},{"producto":34,"cantidad":2}]', '[{"id_comprobante":76,"id_metodo_pago":"MP01","monto":"5.00","numero_operacion":null,"fecha_pago":"2026-11-15T20:17:30.000Z"},{"id_comprobante":76,"id_metodo_pago":"MP02","monto":"6.00","numero_operacion":"RP-DEMO-76-2","fecha_pago":"2026-11-15T20:18:00.000Z"}]'),
    (77, 'RPDEMO009', '2026-11-15T13:28:00-05:00', 'Para llevar', '2026-11-15T18:30:00.000Z', 10.00, '[{"producto":13,"cantidad":2}]', '[{"id_comprobante":77,"id_metodo_pago":"MP01","monto":"10.00","numero_operacion":null,"fecha_pago":"2026-11-15T18:30:30.000Z"}]'),
    (78, 'RPDEMO002', '2026-11-16T20:41:00-05:00', 'Delivery', '2026-11-17T01:43:00.000Z', 26.00, '[{"producto":14,"cantidad":3},{"producto":35,"cantidad":2}]', '[{"id_comprobante":78,"id_metodo_pago":"MP02","monto":"26.00","numero_operacion":"RP-DEMO-78-1","fecha_pago":"2026-11-17T01:43:30.000Z"}]'),
    (79, 'RPDEMO007', '2026-11-16T18:54:00-05:00', 'En local', '2026-11-16T23:56:00.000Z', 12.00, '[{"producto":15,"cantidad":1},{"producto":36,"cantidad":1}]', '[{"id_comprobante":79,"id_metodo_pago":"MP03","monto":"12.00","numero_operacion":"RP-DEMO-79-1","fecha_pago":"2026-11-16T23:56:30.000Z"}]'),
    (80, 'RPDEMO012', '2026-11-16T16:07:00-05:00', 'Para llevar', '2026-11-16T21:09:00.000Z', 26.00, '[{"producto":16,"cantidad":2},{"producto":36,"cantidad":2}]', '[{"id_comprobante":80,"id_metodo_pago":"MP04","monto":"26.00","numero_operacion":"RP-DEMO-80-1","fecha_pago":"2026-11-16T21:09:30.000Z"}]'),
    (81, 'RPDEMO005', '2026-11-17T14:20:00-05:00', 'Delivery', '2026-11-17T19:22:00.000Z', 33.50, '[{"producto":17,"cantidad":3},{"producto":37,"cantidad":1}]', '[{"id_comprobante":81,"id_metodo_pago":"MP01","monto":"16.00","numero_operacion":null,"fecha_pago":"2026-11-17T19:22:30.000Z"},{"id_comprobante":81,"id_metodo_pago":"MP02","monto":"17.50","numero_operacion":"RP-DEMO-81-2","fecha_pago":"2026-11-17T19:23:00.000Z"}]'),
    (82, 'RPDEMO010', '2026-11-17T12:33:00-05:00', 'En local', '2026-11-17T17:35:00.000Z', 17.00, '[{"producto":18,"cantidad":1},{"producto":37,"cantidad":2}]', '[{"id_comprobante":82,"id_metodo_pago":"MP02","monto":"17.00","numero_operacion":"RP-DEMO-82-1","fecha_pago":"2026-11-17T17:35:30.000Z"}]'),
    (83, 'RPDEMO003', '2026-11-17T19:46:00-05:00', 'Para llevar', '2026-11-18T00:48:00.000Z', 26.00, '[{"producto":19,"cantidad":2},{"producto":38,"cantidad":1}]', '[{"id_comprobante":83,"id_metodo_pago":"MP03","monto":"26.00","numero_operacion":"RP-DEMO-83-1","fecha_pago":"2026-11-18T00:48:30.000Z"}]'),
    (84, 'RPDEMO008', '2026-11-17T17:59:00-05:00', 'Delivery', '2026-11-17T23:01:00.000Z', 48.00, '[{"producto":20,"cantidad":3}]', '[{"id_comprobante":84,"id_metodo_pago":"MP04","monto":"48.00","numero_operacion":"RP-DEMO-84-1","fecha_pago":"2026-11-17T23:01:30.000Z"}]'),
    (85, 'RPDEMO001', '2026-11-18T15:12:00-05:00', 'En local', '2026-11-18T20:14:00.000Z', 17.00, '[{"producto":21,"cantidad":1},{"producto":33,"cantidad":1}]', '[{"id_comprobante":85,"id_metodo_pago":"MP01","monto":"17.00","numero_operacion":null,"fecha_pago":"2026-11-18T20:14:30.000Z"}]'),
    (86, 'RPDEMO006', '2026-11-18T13:25:00-05:00', 'Para llevar', '2026-11-18T18:27:00.000Z', 36.00, '[{"producto":22,"cantidad":2},{"producto":33,"cantidad":2}]', '[{"id_comprobante":86,"id_metodo_pago":"MP01","monto":"18.00","numero_operacion":null,"fecha_pago":"2026-11-18T18:27:30.000Z"},{"id_comprobante":86,"id_metodo_pago":"MP02","monto":"18.00","numero_operacion":"RP-DEMO-86-2","fecha_pago":"2026-11-18T18:28:00.000Z"}]'),
    (87, 'RPDEMO011', '2026-11-18T20:38:00-05:00', 'Delivery', '2026-11-19T01:40:00.000Z', 93.00, '[{"producto":23,"cantidad":3},{"producto":34,"cantidad":1}]', '[{"id_comprobante":87,"id_metodo_pago":"MP03","monto":"93.00","numero_operacion":"RP-DEMO-87-1","fecha_pago":"2026-11-19T01:40:30.000Z"}]'),
    (88, 'RPDEMO004', '2026-11-19T18:51:00-05:00', 'En local', '2026-11-19T23:53:00.000Z', 31.00, '[{"producto":24,"cantidad":1},{"producto":34,"cantidad":2}]', '[{"id_comprobante":88,"id_metodo_pago":"MP04","monto":"31.00","numero_operacion":"RP-DEMO-88-1","fecha_pago":"2026-11-19T23:53:30.000Z"}]'),
    (89, 'RPDEMO009', '2026-11-19T16:04:00-05:00', 'Para llevar', '2026-11-19T21:06:00.000Z', 20.00, '[{"producto":25,"cantidad":2},{"producto":35,"cantidad":1}]', '[{"id_comprobante":89,"id_metodo_pago":"MP01","monto":"20.00","numero_operacion":null,"fecha_pago":"2026-11-19T21:06:30.000Z"}]'),
    (90, 'RPDEMO002', '2026-11-19T14:17:00-05:00', 'Delivery', '2026-11-19T19:19:00.000Z', 32.00, '[{"producto":26,"cantidad":3},{"producto":35,"cantidad":2}]', '[{"id_comprobante":90,"id_metodo_pago":"MP02","monto":"32.00","numero_operacion":"RP-DEMO-90-1","fecha_pago":"2026-11-19T19:19:30.000Z"}]'),
    (91, 'RPDEMO007', '2026-11-20T12:30:00-05:00', 'En local', '2026-11-20T17:32:00.000Z', 9.00, '[{"producto":27,"cantidad":1}]', '[{"id_comprobante":91,"id_metodo_pago":"MP01","monto":"4.00","numero_operacion":null,"fecha_pago":"2026-11-20T17:32:30.000Z"},{"id_comprobante":91,"id_metodo_pago":"MP02","monto":"5.00","numero_operacion":"RP-DEMO-91-2","fecha_pago":"2026-11-20T17:33:00.000Z"}]'),
    (92, 'RPDEMO012', '2026-11-20T19:43:00-05:00', 'Para llevar', '2026-11-21T00:45:00.000Z', 26.00, '[{"producto":28,"cantidad":2},{"producto":36,"cantidad":2}]', '[{"id_comprobante":92,"id_metodo_pago":"MP04","monto":"26.00","numero_operacion":"RP-DEMO-92-1","fecha_pago":"2026-11-21T00:45:30.000Z"}]'),
    (93, 'RPDEMO005', '2026-11-20T17:56:00-05:00', 'Delivery', '2026-11-20T22:58:00.000Z', 33.50, '[{"producto":29,"cantidad":3},{"producto":37,"cantidad":1}]', '[{"id_comprobante":93,"id_metodo_pago":"MP01","monto":"33.50","numero_operacion":null,"fecha_pago":"2026-11-20T22:58:30.000Z"}]'),
    (94, 'RPDEMO010', '2026-11-20T15:09:00-05:00', 'En local', '2026-11-20T20:11:00.000Z', 17.00, '[{"producto":30,"cantidad":1},{"producto":37,"cantidad":2}]', '[{"id_comprobante":94,"id_metodo_pago":"MP02","monto":"17.00","numero_operacion":"RP-DEMO-94-1","fecha_pago":"2026-11-20T20:11:30.000Z"}]'),
    (95, 'RPDEMO003', '2026-11-21T13:22:00-05:00', 'Para llevar', '2026-11-21T18:24:00.000Z', 32.00, '[{"producto":31,"cantidad":2},{"producto":38,"cantidad":1}]', '[{"id_comprobante":95,"id_metodo_pago":"MP03","monto":"32.00","numero_operacion":"RP-DEMO-95-1","fecha_pago":"2026-11-21T18:24:30.000Z"}]'),
    (96, 'RPDEMO008', '2026-11-21T20:35:00-05:00', 'Delivery', '2026-11-22T01:37:00.000Z', 49.00, '[{"producto":32,"cantidad":3},{"producto":38,"cantidad":2}]', '[{"id_comprobante":96,"id_metodo_pago":"MP01","monto":"24.00","numero_operacion":null,"fecha_pago":"2026-11-22T01:37:30.000Z"},{"id_comprobante":96,"id_metodo_pago":"MP02","monto":"25.00","numero_operacion":"RP-DEMO-96-2","fecha_pago":"2026-11-22T01:38:00.000Z"}]'),
    (97, 'RPDEMO001', '2026-11-21T18:48:00-05:00', 'En local', '2026-11-21T23:50:00.000Z', 8.00, '[{"producto":1,"cantidad":1},{"producto":33,"cantidad":1}]', '[{"id_comprobante":97,"id_metodo_pago":"MP01","monto":"8.00","numero_operacion":null,"fecha_pago":"2026-11-21T23:50:30.000Z"}]'),
    (98, 'RPDEMO006', '2026-11-22T16:01:00-05:00', 'Para llevar', '2026-11-22T21:03:00.000Z', 11.00, '[{"producto":2,"cantidad":2}]', '[{"id_comprobante":98,"id_metodo_pago":"MP02","monto":"11.00","numero_operacion":"RP-DEMO-98-1","fecha_pago":"2026-11-22T21:03:30.000Z"}]'),
    (99, 'RPDEMO011', '2026-11-22T14:14:00-05:00', 'Delivery', '2026-11-22T19:16:00.000Z', 21.00, '[{"producto":3,"cantidad":3},{"producto":34,"cantidad":1}]', '[{"id_comprobante":99,"id_metodo_pago":"MP03","monto":"21.00","numero_operacion":"RP-DEMO-99-1","fecha_pago":"2026-11-22T19:16:30.000Z"}]'),
    (100, 'RPDEMO004', '2026-11-22T12:27:00-05:00', 'En local', '2026-11-22T17:29:00.000Z', 13.00, '[{"producto":4,"cantidad":1},{"producto":34,"cantidad":2}]', '[{"id_comprobante":100,"id_metodo_pago":"MP04","monto":"13.00","numero_operacion":"RP-DEMO-100-1","fecha_pago":"2026-11-22T17:29:30.000Z"}]');

DO $carga$
DECLARE
    venta rp_ventas%ROWTYPE;
    cliente bigint;
    pedido bigint;
    documento bigint;
    total_real numeric;
    cobrado_real numeric;
BEGIN
    FOR venta IN SELECT * FROM rp_ventas ORDER BY orden LOOP
        SELECT c.id_cliente INTO STRICT cliente FROM clientes c
        WHERE c.tipo_documento = 'CE' AND c.numero_documento = venta.documento;

        SELECT p.id_pedido INTO pedido FROM pedidos p
        WHERE p.id_cliente = cliente AND p.fecha_pedido = venta.fecha;
        IF NOT FOUND THEN
            INSERT INTO pedidos (id_cliente, fecha_pedido, tipo_pedido, estado)
            VALUES (cliente, venta.fecha, venta.modalidad, 'Entregado') RETURNING id_pedido INTO pedido;

            PERFORM agregar_item(pedido, p.id_producto, item.cantidad)
            FROM jsonb_to_recordset(venta.detalle) AS item(producto integer, cantidad integer)
            JOIN rp_catalogo d ON d.ficha = item.producto
            JOIN productos p ON (p.id_categoria, p.nombre) = (d.categoria, d.nombre);

            documento := emitir_comprobante(pedido, 'RP01', 18, venta.emision);
            INSERT INTO pagos (id_comprobante, id_metodo_pago, monto, numero_operacion, fecha_pago)
            SELECT documento, abono.id_metodo_pago, abono.monto, abono.numero_operacion, abono.fecha_pago
            FROM jsonb_to_recordset(venta.abonos) AS abono(
                id_metodo_pago varchar(10), monto numeric(16,2), numero_operacion varchar(30), fecha_pago timestamptz
            );
        END IF;

        SELECT v.total, v.cobrado INTO STRICT total_real, cobrado_real
        FROM v_conciliacion v JOIN comprobantes comp USING (id_comprobante)
        WHERE v.id_pedido = pedido AND comp.serie = 'RP01' AND comp.numero_correlativo = venta.orden;
        IF total_real <> venta.total OR cobrado_real <> venta.total THEN
            RAISE EXCEPTION 'La venta ficticia % no coincide con la muestra', venta.orden;
        END IF;
    END LOOP;
END;
$carga$;

SELECT count(*) AS ventas, sum(total) AS total_pen, sum(cobrado) AS cobrado_pen, sum(saldo) AS saldo_pen
FROM v_conciliacion c JOIN comprobantes d USING (id_comprobante)
WHERE d.serie = 'RP01' AND d.numero_correlativo BETWEEN 1 AND 100;

COMMIT;
