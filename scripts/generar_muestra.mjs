import { writeFile } from 'node:fs/promises';
import { bebidas, categorias, clientes, productos, snacks, ventas, seriePrueba, telefonos } from '../web/datos.js';

const sql = (valor) => valor === null ? 'NULL' : `'${String(valor).replaceAll("'", "''")}'`;
const valores = (filas) => filas.map((fila) => `    (${fila.join(', ')})`).join(',\n');
const soles = (centavos) => (centavos / 100).toFixed(2);

const catalogo = productos.map((p) => {
  const snack = snacks.find((fila) => fila.id_producto === p.id_producto);
  const bebida = bebidas.find((fila) => fila.id_producto === p.id_producto);
  return [p.id_producto, sql(p.id_categoria), sql(p.nombre), soles(p.precio), sql(snack?.porcion ?? null),
    sql(snack?.tipo_papa ?? null), snack?.incluye_cremas ?? 'NULL', bebida?.volumen_ml ?? 'NULL',
    sql(bebida?.temperatura ?? null), sql(bebida?.envase ?? null)];
});

const ventasSql = ventas.map(({ pedido, detalle, comprobante, pagos }) => {
  const cliente = clientes.find((fila) => fila.id_cliente === pedido.id_cliente);
  const lineas = detalle.map((fila) => ({ producto: fila.id_producto, cantidad: fila.cantidad }));
  const abonos = pagos.map((pago) => ({ ...pago, monto: soles(pago.monto) }));
  const total = detalle.reduce((suma, linea) => suma + linea.cantidad * linea.precio_unitario, 0);
  return [pedido.id_pedido, sql(cliente.numero_documento), sql(pedido.fecha_pedido), sql(pedido.tipo_pedido),
    sql(comprobante.fecha_emision), soles(total), sql(JSON.stringify(lineas)), sql(JSON.stringify(abonos))];
});

const migracion = `-- Generado por scripts/generar_muestra.mjs a partir de la muestra versionada en web/datos.js.
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
${valores(categorias.map((c) => [sql(c.id_categoria), sql(c.nombre), sql(c.tipo_subtipo)]))}
ON CONFLICT (id_categoria) DO NOTHING;

INSERT INTO clientes (nombres, apellidos, tipo_documento, numero_documento) VALUES
${valores(clientes.map((c) => [sql('Cliente'), sql(`De prueba ${String(c.id_cliente).padStart(2, '0')}`), sql(c.tipo_documento), sql(c.numero_documento)]))}
ON CONFLICT (tipo_documento, numero_documento) DO NOTHING;

INSERT INTO telefonos_cliente (id_cliente, numero)
SELECT c.id_cliente, t.numero
FROM (VALUES
${valores(telefonos.map((t) => [sql(clientes.find((c) => c.id_cliente === t.id_cliente).numero_documento), sql(t.numero)]))}
) t(documento, numero)
JOIN clientes c ON c.tipo_documento = 'CE' AND c.numero_documento = t.documento
ON CONFLICT (id_cliente, numero) DO NOTHING;

CREATE TEMP TABLE rp_catalogo (
    ficha integer PRIMARY KEY, categoria varchar(10), nombre varchar(100), precio numeric(10,2),
    porcion varchar(30), tipo_papa varchar(40), incluye_cremas boolean,
    volumen_ml integer, temperatura varchar(20), envase varchar(30)
) ON COMMIT DROP;
INSERT INTO rp_catalogo VALUES
${valores(catalogo)};

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

INSERT INTO series_comprobante (serie, id_tipo_comprobante) VALUES (${sql(seriePrueba)}, 'TC01')
ON CONFLICT (serie) DO NOTHING;

CREATE TEMP TABLE rp_ventas (
    orden integer PRIMARY KEY, documento varchar(20), fecha timestamptz, modalidad text,
    emision timestamptz, total numeric(10,2), detalle jsonb, abonos jsonb
) ON COMMIT DROP;
INSERT INTO rp_ventas VALUES
${valores(ventasSql)};

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

            documento := emitir_comprobante(pedido, ${sql(seriePrueba)}, 18, venta.emision);
            INSERT INTO pagos (id_comprobante, id_metodo_pago, monto, numero_operacion, fecha_pago)
            SELECT documento, abono.id_metodo_pago, abono.monto, abono.numero_operacion, abono.fecha_pago
            FROM jsonb_to_recordset(venta.abonos) AS abono(
                id_metodo_pago varchar(10), monto numeric(16,2), numero_operacion varchar(30), fecha_pago timestamptz
            );
        END IF;

        SELECT v.total, v.cobrado INTO STRICT total_real, cobrado_real
        FROM v_conciliacion v JOIN comprobantes comp USING (id_comprobante)
        WHERE v.id_pedido = pedido AND comp.serie = ${sql(seriePrueba)} AND comp.numero_correlativo = venta.orden;
        IF total_real <> venta.total OR cobrado_real <> venta.total THEN
            RAISE EXCEPTION 'La venta ficticia % no coincide con la muestra', venta.orden;
        END IF;
    END LOOP;
END;
$carga$;

SELECT count(*) AS ventas, sum(total) AS total_pen, sum(cobrado) AS cobrado_pen, sum(saldo) AS saldo_pen
FROM v_conciliacion c JOIN comprobantes d USING (id_comprobante)
WHERE d.serie = ${sql(seriePrueba)} AND d.numero_correlativo BETWEEN 1 AND ${ventas.length};

COMMIT;
`;

await writeFile(new URL('../sql/06_catalogo_y_ventas.sql', import.meta.url), migracion, 'utf8');

const identidades = `-- Generado por scripts/generar_muestra.mjs a partir de las identidades ficticias versionadas en web/datos.js.
BEGIN;
CREATE TEMP TABLE rp_identidades (
    documento varchar(20) PRIMARY KEY, nombres varchar(60), apellidos varchar(60)
) ON COMMIT DROP;
INSERT INTO rp_identidades VALUES
${valores(clientes.map((cliente) => [sql(cliente.numero_documento), sql(cliente.nombres), sql(cliente.apellidos)]))};

DO $validar$
BEGIN
    IF (SELECT count(*) FROM salchipaperia.clientes c JOIN rp_identidades i
        ON c.tipo_documento = 'CE' AND c.numero_documento = i.documento) <> ${clientes.length} THEN
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
`;

await writeFile(new URL('../sql/08_nombres_ficticios.sql', import.meta.url), identidades, 'utf8');
