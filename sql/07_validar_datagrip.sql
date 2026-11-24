-- Ejecutar por bloques en la conexión de Supabase después de la migración 10.
SELECT current_database() AS base, current_schema() AS esquema_activo,
       current_setting('server_version') AS version_postgresql,
       to_regnamespace('salchipaperia') IS NOT NULL AS existe_salchipaperia;

SELECT table_name AS objeto, table_type AS tipo
FROM information_schema.tables
WHERE table_schema = 'salchipaperia'
ORDER BY table_name;

SELECT c.nombre AS categoria, count(*) AS productos, min(p.precio) AS precio_minimo_pen,
       max(p.precio) AS precio_maximo_pen
FROM salchipaperia.productos p
JOIN salchipaperia.categorias c USING (id_categoria)
WHERE c.id_categoria IN ('RPSAN', 'RPEMP', 'RPSAL', 'RPPLA', 'RPCOM', 'RPHAM', 'RPBEB')
GROUP BY c.nombre
ORDER BY c.nombre;

SELECT p.nombre AS producto, b.tipo_bebida, b.envase
FROM salchipaperia.bebidas b JOIN salchipaperia.productos p USING (id_producto)
ORDER BY producto;

SELECT p.nombre AS producto, h.tipo_carne, h.incluye_papas
FROM salchipaperia.hamburguesas h JOIN salchipaperia.productos p USING (id_producto)
ORDER BY producto;

-- Los 100 pedidos de la carta tienen fecha del 24/10 al 22/11 inclusive, hora de Lima.
SELECT count(DISTINCT p.id_pedido) AS pedidos, count(d.id_producto) AS lineas,
       sum(d.cantidad * d.precio_unitario) AS total_pen
FROM salchipaperia.pedidos p LEFT JOIN salchipaperia.detalle_pedido d USING (id_pedido)
WHERE p.fecha_pedido >= '2026-10-24 00:00:00-05'::timestamptz
  AND p.fecha_pedido < '2026-11-23 00:00:00-05'::timestamptz;

SELECT p.id_pedido, concat_ws(' ', c.nombres, c.apellidos) AS cliente,
       p.fecha_pedido AT TIME ZONE 'America/Lima' AS fecha_lima, p.tipo_pedido, p.estado,
       count(d.id_producto) AS lineas, coalesce(sum(d.cantidad * d.precio_unitario), 0.00) AS total_pen
FROM salchipaperia.pedidos p
JOIN salchipaperia.clientes c USING (id_cliente)
LEFT JOIN salchipaperia.detalle_pedido d USING (id_pedido)
GROUP BY p.id_pedido, c.nombres, c.apellidos
ORDER BY p.fecha_pedido, p.id_pedido;

-- Cambiar 4 por un id_pedido del resultado anterior para ver sus líneas.
SELECT d.id_pedido, p.nombre AS producto, c.nombre AS categoria,
       coalesce(s.porcion::text,
                CASE WHEN h.incluye_papas THEN 'Hamburguesa con papas' WHEN h.id_producto IS NOT NULL THEN 'Hamburguesa' END,
                nullif(concat_ws(' · ', b.tipo_bebida, b.envase), '')) AS presentacion,
       d.cantidad, d.precio_unitario, d.cantidad * d.precio_unitario AS subtotal_pen
FROM salchipaperia.detalle_pedido d
JOIN salchipaperia.productos p USING (id_producto)
JOIN salchipaperia.categorias c USING (id_categoria)
LEFT JOIN salchipaperia.snacks s USING (id_producto)
LEFT JOIN salchipaperia.bebidas b USING (id_producto)
LEFT JOIN salchipaperia.hamburguesas h USING (id_producto)
WHERE d.id_pedido = 4
ORDER BY producto;
