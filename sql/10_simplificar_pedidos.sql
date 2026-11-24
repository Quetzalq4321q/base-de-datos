-- Aplicar una vez sobre el modelo original, después de verificar un respaldo del esquema.
BEGIN;
SET LOCAL search_path = salchipaperia, pg_catalog;
SET LOCAL lock_timeout = '10s';
SELECT pg_advisory_xact_lock(hashtext('salchipaperia.red_pepper.ventas_100.v1'));

LOCK TABLE clientes, categorias, productos, snacks, bebidas, pedidos, detalle_pedido,
    telefonos_cliente, tipos_comprobante, series_comprobante, comprobantes, metodos_pago, pagos
    IN ACCESS EXCLUSIVE MODE;

DROP FUNCTION IF EXISTS public.red_pepper_demo_resumen();
DROP FUNCTION IF EXISTS salchipaperia.resumen_publico_demo();
DROP VIEW v_conciliacion;
DROP VIEW v_importes_comprobante;
DROP VIEW v_detalle_pedido;

DROP TRIGGER detalle_edicion ON detalle_pedido;
DROP TRIGGER pedido_emitido ON pedidos;
DROP FUNCTION proteger_detalle_emitido();
DROP FUNCTION proteger_pedido_emitido();
DROP FUNCTION emitir_comprobante(bigint, varchar, numeric, timestamptz);

DROP TABLE pagos, comprobantes, series_comprobante, tipos_comprobante, metodos_pago, telefonos_cliente;
DROP FUNCTION validar_comprobante_nuevo();
DROP FUNCTION proteger_tipo_serie();
DROP FUNCTION comprobar_pago();
DROP FUNCTION proteger_documentos_emitidos();

DROP TRIGGER categoria_subtipo_estable ON categorias;
DROP FUNCTION impedir_cambio_subtipo_categoria();

ALTER TABLE bebidas ADD COLUMN tipo_bebida text CHECK (tipo_bebida IN ('Gaseosa', 'Chicha'));
UPDATE bebidas b
SET tipo_bebida = CASE
    WHEN p.nombre ILIKE 'chicha %' OR p.nombre ILIKE 'chicha' THEN 'Chicha'
    WHEN p.nombre ILIKE ANY (ARRAY['coca-cola%', 'inca kola%', 'fanta%']) THEN 'Gaseosa'
END
FROM productos p WHERE p.id_producto = b.id_producto;

CREATE TABLE hamburguesas (
    id_producto bigint PRIMARY KEY REFERENCES productos ON DELETE CASCADE,
    tipo_carne text CHECK (tipo_carne IN ('Res', 'Pollo')),
    incluye_papas boolean
);
REVOKE ALL ON TABLE hamburguesas FROM PUBLIC;

CREATE OR REPLACE FUNCTION comprobar_subtipo() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, salchipaperia AS $$
DECLARE
    producto bigint;
    subtipos integer;
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.id_producto <> NEW.id_producto THEN
        RAISE EXCEPTION 'La identidad del producto o del subtipo es inmutable' USING ERRCODE = '23514';
    END IF;
    producto := CASE WHEN TG_OP = 'DELETE' THEN OLD.id_producto ELSE NEW.id_producto END;
    PERFORM FROM productos WHERE id_producto = producto FOR NO KEY UPDATE;
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    SELECT (EXISTS (SELECT FROM snacks WHERE id_producto = producto))::int
         + (EXISTS (SELECT FROM bebidas WHERE id_producto = producto))::int
         + (EXISTS (SELECT FROM hamburguesas WHERE id_producto = producto))::int
    INTO subtipos;
    IF subtipos <> 1 THEN
        RAISE EXCEPTION 'El producto % debe tener exactamente un subtipo', producto USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER hamburguesa_subtipo AFTER INSERT OR UPDATE OF id_producto OR DELETE ON hamburguesas
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION comprobar_subtipo();

INSERT INTO hamburguesas (id_producto, tipo_carne, incluye_papas)
SELECT p.id_producto,
       CASE WHEN p.nombre ILIKE '% de res' THEN 'Res' WHEN p.nombre ILIKE '% de pollo' THEN 'Pollo' END,
       CASE WHEN s.porcion = 'Hamburguesa con papas' THEN true END
FROM productos p JOIN snacks s USING (id_producto)
WHERE p.id_categoria = 'RPHAM';

DELETE FROM snacks s USING hamburguesas h WHERE s.id_producto = h.id_producto;
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE clientes DROP COLUMN tipo_documento, DROP COLUMN numero_documento;
ALTER TABLE categorias DROP COLUMN tipo_subtipo;
ALTER TABLE bebidas DROP COLUMN volumen_ml, DROP COLUMN temperatura;
ALTER TABLE snacks DROP COLUMN tipo_papa;

NOTIFY pgrst, 'reload schema';
COMMIT;
