BEGIN;

CREATE FUNCTION salchipaperia.resumen_publico_demo() RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = pg_catalog AS $$
    WITH demo AS (
        SELECT v.*
        FROM salchipaperia.v_conciliacion v
        JOIN salchipaperia.pedidos p USING (id_pedido)
        JOIN salchipaperia.clientes c USING (id_cliente)
        WHERE c.tipo_documento = 'DNI'
          AND (c.numero_documento, v.comprobante, v.fecha_emision) IN (
              ('00000001', 'B001-0000001', '2026-11-23 19:20:00-05'::timestamptz),
              ('00000002', 'B001-0000002', '2026-11-23 20:02:00-05'::timestamptz)
          )
    )
    SELECT jsonb_build_object('pedidos', coalesce(jsonb_agg(jsonb_build_object(
        'comprobante', d.comprobante,
        'base', d.base_imponible,
        'igv', d.igv,
        'total', d.total,
        'cobrado', d.cobrado,
        'saldo', d.saldo,
        'detalle', (
            SELECT jsonb_agg(jsonb_build_object(
                'producto', l.producto, 'presentacion', l.presentacion, 'categoria', l.categoria,
                'cantidad', l.cantidad, 'total', l.subtotal_linea
            ) ORDER BY l.producto)
            FROM salchipaperia.v_detalle_pedido l WHERE l.id_pedido = d.id_pedido
        ),
        'pagos', (
            SELECT jsonb_agg(jsonb_build_object('metodo', m.nombre, 'monto', p.monto) ORDER BY p.id_pago)
            FROM salchipaperia.pagos p
            JOIN salchipaperia.metodos_pago m USING (id_metodo_pago)
            WHERE p.id_comprobante = d.id_comprobante
        )
    ) ORDER BY d.comprobante), '[]'::jsonb)) FROM demo d;
$$;

CREATE FUNCTION public.red_pepper_demo_resumen() RETURNS jsonb
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = pg_catalog AS $$
    SELECT salchipaperia.resumen_publico_demo();
$$;

REVOKE ALL ON FUNCTION salchipaperia.resumen_publico_demo() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.red_pepper_demo_resumen() FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA salchipaperia TO anon;
GRANT EXECUTE ON FUNCTION salchipaperia.resumen_publico_demo() TO anon;
GRANT EXECUTE ON FUNCTION public.red_pepper_demo_resumen() TO anon;

SET LOCAL ROLE anon;
DO $$
BEGIN
    IF has_table_privilege(current_user, 'salchipaperia.clientes', 'SELECT') OR
       has_table_privilege(current_user, 'salchipaperia.pedidos', 'INSERT') OR
       has_table_privilege(current_user, 'salchipaperia.pagos', 'SELECT,INSERT,UPDATE,DELETE') THEN
        RAISE EXCEPTION 'El rol web recibió permisos de tabla que no corresponden';
    END IF;
    IF jsonb_array_length(public.red_pepper_demo_resumen()->'pedidos') <> 2 THEN
        RAISE EXCEPTION 'El resumen web debe devolver los dos pedidos de demostración';
    END IF;
END;
$$;
RESET ROLE;

NOTIFY pgrst, 'reload schema';
COMMIT;
