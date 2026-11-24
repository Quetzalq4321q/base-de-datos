BEGIN;
SET LOCAL search_path = salchipaperia, pg_catalog;

DO $$
DECLARE
    pedido_cliente bigint;
    pedido_nuevo bigint;
    producto bigint;
    nueva_bebida bigint;
    comprobante bigint;
    resultado numeric;
    verificacion record;
BEGIN
    SELECT count(*) INTO resultado FROM information_schema.tables
    WHERE table_schema = 'salchipaperia' AND table_type = 'BASE TABLE';
    IF resultado <> 13 THEN RAISE EXCEPTION 'Se esperaban 13 tablas'; END IF;

    SELECT v.* INTO STRICT verificacion FROM v_conciliacion v WHERE v.comprobante = 'B001-0000001';
    IF (verificacion.base_imponible, verificacion.igv, verificacion.total, verificacion.cobrado, verificacion.saldo)
        IS DISTINCT FROM (17.80, 3.20, 21.00, 21.00, 0.00) THEN
        RAISE EXCEPTION 'Importes inesperados para el pedido de pago mixto';
    END IF;
    IF (SELECT count(*) FROM v_detalle_pedido WHERE id_pedido = verificacion.id_pedido) <> 2 OR
       (SELECT count(*) FROM pagos WHERE id_comprobante = verificacion.id_comprobante) <> 2 THEN
        RAISE EXCEPTION 'Se esperaban dos productos y dos pagos en el primer pedido';
    END IF;

    SELECT v.* INTO STRICT verificacion FROM v_conciliacion v WHERE v.comprobante = 'B001-0000002';
    IF (verificacion.base_imponible, verificacion.igv, verificacion.total, verificacion.cobrado, verificacion.saldo)
        IS DISTINCT FROM (20.34, 3.66, 24.00, 24.00, 0.00) THEN
        RAISE EXCEPTION 'Importes inesperados para el pedido de delivery';
    END IF;

    SELECT id_cliente INTO STRICT pedido_cliente FROM clientes WHERE numero_documento = '00000001';
    SELECT id_producto INTO STRICT producto FROM productos
    WHERE id_categoria = 'S001' AND nombre = 'Salchipapa Especial';

    BEGIN
        INSERT INTO productos (id_categoria, nombre, precio) VALUES ('B001', 'Sin subtipo', 3.50);
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'Se aceptó un producto sin subtipo';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    BEGIN
        INSERT INTO bebidas (id_producto, volumen_ml, temperatura, envase)
        VALUES (producto, 500, 'Helada', 'Lata');
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'Se aceptó un producto con dos subtipos';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    BEGIN
        INSERT INTO productos (id_categoria, nombre, precio)
        VALUES ('S001', 'Familia equivocada', 3.50) RETURNING id_producto INTO nueva_bebida;
        INSERT INTO bebidas (id_producto, volumen_ml, temperatura, envase)
        VALUES (nueva_bebida, 500, 'Helada', 'Lata');
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'Se aceptó un subtipo incompatible con la categoría';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    INSERT INTO pedidos (id_cliente, tipo_pedido) VALUES (pedido_cliente, 'Para llevar')
    RETURNING id_pedido INTO pedido_nuevo;

    BEGIN
        PERFORM emitir_comprobante(pedido_nuevo, 'B001', 18);
        RAISE EXCEPTION 'Se emitió un pedido vacío';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    BEGIN
        PERFORM agregar_item(pedido_nuevo, producto, 0);
        RAISE EXCEPTION 'Se aceptó una cantidad igual a cero';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    PERFORM agregar_item(pedido_nuevo, producto, 1);
    UPDATE productos SET precio = 9.00 WHERE id_producto = producto;
    PERFORM agregar_item(pedido_nuevo, producto, 1);

    IF (SELECT cantidad = 2 AND precio_unitario = 7.00 FROM detalle_pedido
        WHERE id_pedido = pedido_nuevo AND id_producto = producto) IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'No se conservó el precio original al agrupar el producto';
    END IF;
    comprobante := emitir_comprobante(pedido_nuevo, 'B001', 18);
    IF emitir_comprobante(pedido_nuevo, 'B001', 18) <> comprobante THEN
        RAISE EXCEPTION 'La reemisión cambió el identificador';
    END IF;
    IF (SELECT ultimo_correlativo FROM series_comprobante WHERE serie = 'B001') <>
        (SELECT numero_correlativo FROM comprobantes WHERE id_comprobante = comprobante) THEN
        RAISE EXCEPTION 'El contador de la serie no coincide con la emisión';
    END IF;

    BEGIN
        PERFORM agregar_item(pedido_nuevo, producto, 1);
        RAISE EXCEPTION 'Se editó un pedido emitido';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    BEGIN
        INSERT INTO pagos (id_comprobante, id_metodo_pago, monto) VALUES (comprobante, 'MP02', 1.00);
        RAISE EXCEPTION 'Se aceptó un pago con referencia vacía';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    INSERT INTO pagos (id_comprobante, id_metodo_pago, monto) VALUES (comprobante, 'MP01', 5.00);
    IF (SELECT saldo FROM v_conciliacion WHERE id_pedido = pedido_nuevo) IS DISTINCT FROM 9.00 THEN
        RAISE EXCEPTION 'El abono parcial debía dejar S/ 9.00 pendientes';
    END IF;

    BEGIN
        INSERT INTO pagos (id_comprobante, id_metodo_pago, monto) VALUES (comprobante, 'MP01', 9.01);
        RAISE EXCEPTION 'Se aceptó un sobrepago';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    BEGIN
        INSERT INTO pagos (id_comprobante, id_metodo_pago, monto, numero_operacion)
        VALUES (comprobante, 'MP02', 9.00, 'DEMO-YP-01');
        RAISE EXCEPTION 'Se aceptó un número de operación duplicado';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;

    INSERT INTO pagos (id_comprobante, id_metodo_pago, monto, numero_operacion)
    VALUES (comprobante, 'MP02', 9.00, 'DEMO-YP-PRUEBA');
    IF (SELECT saldo FROM v_conciliacion WHERE id_pedido = pedido_nuevo) IS DISTINCT FROM 0.00 THEN
        RAISE EXCEPTION 'El segundo abono debía liquidar el saldo';
    END IF;

    BEGIN
        UPDATE pagos SET monto = 1.00 WHERE numero_operacion = 'DEMO-YP-PRUEBA';
        RAISE EXCEPTION 'Se alteró un pago registrado';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
END;
$$;

SELECT 'OK · 13 tablas, importes, subtipos, reemisión, historial y pagos' AS resultado;
ROLLBACK;
