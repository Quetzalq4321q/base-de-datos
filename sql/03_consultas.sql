-- Líneas y presentaciones. Rango y fecha civil explícitos para Lima.
SELECT id_pedido, fecha_pedido AT TIME ZONE 'America/Lima' AS fecha_lima,
       tipo_pedido, producto, categoria, presentacion, cantidad, precio_unitario, subtotal_linea
FROM salchipaperia.v_detalle_pedido
WHERE fecha_pedido >= '2026-11-23 00:00:00-05'::timestamptz
  AND fecha_pedido < '2026-11-24 00:00:00-05'::timestamptz
ORDER BY id_pedido, producto;

-- Un comprobante por fila, con su conciliación.
SELECT id_pedido, comprobante, tipo_comprobante, base_imponible, igv, total, cobrado, saldo
FROM salchipaperia.v_conciliacion
WHERE fecha_emision >= '2026-11-23 00:00:00-05'::timestamptz
  AND fecha_emision < '2026-11-24 00:00:00-05'::timestamptz
ORDER BY id_pedido;

-- Abonos individuales. Las líneas del pedido quedan fuera de esta agregación.
SELECT c.comprobante, m.nombre AS metodo_pago, p.monto, p.numero_operacion,
       p.fecha_pago AT TIME ZONE 'America/Lima' AS fecha_lima
FROM salchipaperia.v_conciliacion c
JOIN salchipaperia.pagos p USING (id_comprobante)
JOIN salchipaperia.metodos_pago m USING (id_metodo_pago)
WHERE c.fecha_emision >= '2026-11-23 00:00:00-05'::timestamptz
  AND c.fecha_emision < '2026-11-24 00:00:00-05'::timestamptz
ORDER BY c.id_pedido, p.id_pago;
