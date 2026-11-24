-- Abrir una consola en la conexión Supabase de NexLabs y ejecutar por bloques.
-- Este archivo consulta la carga del piloto.

SELECT current_database() AS base,
       current_user AS usuario,
       current_schema() AS esquema_activo,
       current_setting('server_version') AS version_postgresql,
       to_regnamespace('salchipaperia') IS NOT NULL AS existe_salchipaperia;

SELECT table_name AS tabla
FROM information_schema.tables
WHERE table_schema = 'salchipaperia' AND table_type = 'BASE TABLE'
ORDER BY table_name;

SELECT c.nombre AS categoria, count(*) AS productos, min(p.precio) AS precio_minimo_pen,
       max(p.precio) AS precio_maximo_pen
FROM salchipaperia.productos p
JOIN salchipaperia.categorias c USING (id_categoria)
WHERE c.id_categoria IN ('RPSAN', 'RPEMP', 'RPSAL', 'RPPLA', 'RPCOM', 'RPHAM', 'RPBEB')
GROUP BY c.nombre
ORDER BY c.nombre;

SELECT count(*) AS ventas, sum(v.total) AS total_pen, sum(v.cobrado) AS cobrado_pen,
       sum(v.saldo) AS saldo_pen
FROM salchipaperia.v_conciliacion v
JOIN salchipaperia.comprobantes c USING (id_comprobante)
WHERE c.serie = 'RP01';

SELECT v.comprobante, p.tipo_pedido AS modalidad, p.estado,
       p.fecha_pedido AT TIME ZONE 'America/Lima' AS fecha_lima,
       v.base_imponible, v.igv, v.total, v.cobrado, v.saldo
FROM salchipaperia.v_conciliacion v
JOIN salchipaperia.comprobantes c USING (id_comprobante)
JOIN salchipaperia.pedidos p ON p.id_pedido = v.id_pedido
WHERE c.serie = 'RP01'
ORDER BY c.numero_correlativo;

-- Cambiar 1 por otro correlativo RP01 para recorrer sus líneas y abonos.
SELECT v.comprobante, l.producto, l.cantidad, l.precio_unitario, l.subtotal_linea
FROM salchipaperia.comprobantes c
JOIN salchipaperia.v_conciliacion v USING (id_comprobante)
JOIN salchipaperia.v_detalle_pedido l ON l.id_pedido = c.id_pedido
WHERE c.serie = 'RP01' AND c.numero_correlativo = 1
ORDER BY l.producto;

SELECT v.comprobante, m.nombre AS metodo_pago, p.monto,
       p.fecha_pago AT TIME ZONE 'America/Lima' AS fecha_lima
FROM salchipaperia.comprobantes c
JOIN salchipaperia.v_conciliacion v USING (id_comprobante)
JOIN salchipaperia.pagos p USING (id_comprobante)
JOIN salchipaperia.metodos_pago m USING (id_metodo_pago)
WHERE c.serie = 'RP01' AND c.numero_correlativo = 1
ORDER BY p.id_pago;
