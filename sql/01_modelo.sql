BEGIN;

CREATE SCHEMA salchipaperia;
REVOKE ALL ON SCHEMA salchipaperia FROM PUBLIC;
SET LOCAL search_path = salchipaperia, pg_catalog;

CREATE TABLE clientes (
    id_cliente bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombres varchar(60) NOT NULL CHECK (btrim(nombres) <> ''),
    apellidos varchar(60) NOT NULL CHECK (btrim(apellidos) <> ''),
    tipo_documento varchar(10) NOT NULL,
    numero_documento varchar(20) NOT NULL,
    UNIQUE (tipo_documento, numero_documento),
    CHECK (
        (tipo_documento = 'DNI' AND numero_documento ~ '^[0-9]{8}$') OR
        (tipo_documento = 'RUC' AND numero_documento ~ '^[0-9]{11}$') OR
        (tipo_documento = 'CE' AND numero_documento ~ '^[A-Z0-9]{1,20}$')
    )
);

CREATE TABLE telefonos_cliente (
    id_telefono bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente bigint NOT NULL REFERENCES clientes ON DELETE CASCADE,
    numero varchar(16) NOT NULL CHECK (numero ~ '^\+?[0-9]{7,15}$'),
    UNIQUE (id_cliente, numero)
);

CREATE TABLE categorias (
    id_categoria varchar(10) PRIMARY KEY,
    nombre varchar(40) NOT NULL UNIQUE CHECK (btrim(nombre) <> ''),
    descripcion varchar(120),
    tipo_subtipo text NOT NULL CHECK (tipo_subtipo IN ('snack', 'bebida'))
);

CREATE TABLE productos (
    id_producto bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_categoria varchar(10) NOT NULL REFERENCES categorias,
    nombre varchar(100) NOT NULL CHECK (btrim(nombre) <> ''),
    precio numeric(10,2) NOT NULL CHECK (precio BETWEEN 0 AND 99999999.99),
    disponible boolean NOT NULL DEFAULT true,
    UNIQUE (id_categoria, nombre)
);

CREATE TABLE snacks (
    id_producto bigint PRIMARY KEY REFERENCES productos ON DELETE CASCADE,
    porcion varchar(30) NOT NULL CHECK (btrim(porcion) <> ''),
    tipo_papa varchar(40) NOT NULL CHECK (btrim(tipo_papa) <> ''),
    incluye_cremas boolean NOT NULL DEFAULT true
);

CREATE TABLE bebidas (
    id_producto bigint PRIMARY KEY REFERENCES productos ON DELETE CASCADE,
    volumen_ml integer NOT NULL CHECK (volumen_ml > 0),
    temperatura varchar(20) NOT NULL CHECK (btrim(temperatura) <> ''),
    envase varchar(30) NOT NULL CHECK (btrim(envase) <> '')
);

CREATE TABLE pedidos (
    id_pedido bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente bigint NOT NULL REFERENCES clientes,
    fecha_pedido timestamptz NOT NULL DEFAULT now(),
    tipo_pedido text NOT NULL CHECK (tipo_pedido IN ('En local', 'Para llevar', 'Delivery')),
    estado text NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente', 'En Cocina', 'Entregado', 'Anulado'))
);

CREATE TABLE detalle_pedido (
    id_pedido bigint NOT NULL REFERENCES pedidos ON DELETE CASCADE,
    id_producto bigint NOT NULL REFERENCES productos,
    cantidad integer NOT NULL CHECK (cantidad > 0),
    precio_unitario numeric(10,2) NOT NULL CHECK (precio_unitario BETWEEN 0 AND 99999999.99),
    PRIMARY KEY (id_pedido, id_producto)
);

CREATE TABLE tipos_comprobante (
    id_tipo_comprobante varchar(10) PRIMARY KEY,
    nombre varchar(30) NOT NULL UNIQUE CHECK (btrim(nombre) <> '')
);

CREATE TABLE series_comprobante (
    serie varchar(10) PRIMARY KEY CHECK (serie ~ '^[A-Z0-9]{1,10}$'),
    id_tipo_comprobante varchar(10) NOT NULL REFERENCES tipos_comprobante,
    ultimo_correlativo integer NOT NULL DEFAULT 0 CHECK (ultimo_correlativo BETWEEN 0 AND 9999999)
);

CREATE TABLE comprobantes (
    id_comprobante bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pedido bigint NOT NULL UNIQUE REFERENCES pedidos,
    serie varchar(10) NOT NULL REFERENCES series_comprobante,
    numero_correlativo integer NOT NULL CHECK (numero_correlativo BETWEEN 1 AND 9999999),
    fecha_emision timestamptz NOT NULL DEFAULT now(),
    tasa_igv numeric(5,2) NOT NULL CHECK (tasa_igv BETWEEN 0 AND 100),
    UNIQUE (serie, numero_correlativo)
);

CREATE TABLE metodos_pago (
    id_metodo_pago varchar(10) PRIMARY KEY,
    nombre varchar(30) NOT NULL UNIQUE CHECK (btrim(nombre) <> ''),
    requiere_referencia boolean NOT NULL
);

CREATE TABLE pagos (
    id_pago bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_comprobante bigint NOT NULL REFERENCES comprobantes,
    id_metodo_pago varchar(10) NOT NULL REFERENCES metodos_pago,
    monto numeric(16,2) NOT NULL CHECK (monto BETWEEN 0.01 AND 99999999999999.99),
    numero_operacion varchar(30) CHECK (numero_operacion = btrim(numero_operacion) AND numero_operacion <> ''),
    fecha_pago timestamptz NOT NULL DEFAULT now(),
    UNIQUE (id_metodo_pago, numero_operacion)
);

CREATE INDEX pedidos_cliente_idx ON pedidos (id_cliente);
CREATE INDEX pedidos_fecha_idx ON pedidos (fecha_pedido, id_pedido);
CREATE INDEX detalle_producto_idx ON detalle_pedido (id_producto);
CREATE INDEX series_tipo_idx ON series_comprobante (id_tipo_comprobante);
CREATE INDEX pagos_comprobante_idx ON pagos (id_comprobante);

CREATE FUNCTION impedir_cambio_subtipo_categoria() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, salchipaperia AS $$
BEGIN
    IF OLD.tipo_subtipo IS DISTINCT FROM NEW.tipo_subtipo THEN
        RAISE EXCEPTION 'Crea una categoría nueva para cambiar la familia del producto' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER categoria_subtipo_estable BEFORE UPDATE OF tipo_subtipo ON categorias
FOR EACH ROW EXECUTE FUNCTION impedir_cambio_subtipo_categoria();

CREATE FUNCTION comprobar_subtipo() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, salchipaperia AS $$
DECLARE
    producto bigint;
    familia text;
    tiene_snack boolean;
    tiene_bebida boolean;
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.id_producto <> NEW.id_producto THEN
        RAISE EXCEPTION 'La identidad del producto o del subtipo es inmutable' USING ERRCODE = '23514';
    END IF;
    producto := CASE WHEN TG_OP = 'DELETE' THEN OLD.id_producto ELSE NEW.id_producto END;
    SELECT cat.tipo_subtipo INTO familia
    FROM productos p JOIN categorias cat USING (id_categoria)
    WHERE p.id_producto = producto
    FOR NO KEY UPDATE OF p;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    SELECT EXISTS (SELECT FROM snacks WHERE id_producto = producto),
           EXISTS (SELECT FROM bebidas WHERE id_producto = producto)
    INTO tiene_snack, tiene_bebida;

    IF tiene_snack IS DISTINCT FROM (familia = 'snack') OR
       tiene_bebida IS DISTINCT FROM (familia = 'bebida') THEN
        RAISE EXCEPTION 'El producto % requiere exactamente un subtipo %', producto, familia USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER producto_subtipo AFTER INSERT OR UPDATE OF id_producto, id_categoria ON productos
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION comprobar_subtipo();

CREATE CONSTRAINT TRIGGER snack_subtipo AFTER INSERT OR UPDATE OF id_producto OR DELETE ON snacks
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION comprobar_subtipo();

CREATE CONSTRAINT TRIGGER bebida_subtipo AFTER INSERT OR UPDATE OF id_producto OR DELETE ON bebidas
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION comprobar_subtipo();

CREATE FUNCTION proteger_detalle_emitido() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, salchipaperia AS $$
DECLARE
    pedido bigint;
    estado_pedido text;
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.id_pedido <> NEW.id_pedido THEN
        RAISE EXCEPTION 'La línea conserva su pedido original' USING ERRCODE = '23514';
    END IF;
    pedido := CASE WHEN TG_OP = 'DELETE' THEN OLD.id_pedido ELSE NEW.id_pedido END;

    -- Actualizar la fila también detecta conflictos en niveles de aislamiento con una instantánea fija.
    UPDATE pedidos SET estado = estado WHERE id_pedido = pedido RETURNING estado INTO estado_pedido;
    IF EXISTS (SELECT FROM comprobantes WHERE id_pedido = pedido) THEN
        RAISE EXCEPTION 'El pedido % ya tiene comprobante', pedido USING ERRCODE = '23514';
    END IF;
    IF estado_pedido = 'Anulado' AND TG_OP <> 'DELETE' THEN
        RAISE EXCEPTION 'El pedido % está anulado', pedido USING ERRCODE = '23514';
    END IF;
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;

CREATE TRIGGER detalle_edicion BEFORE INSERT OR UPDATE OR DELETE ON detalle_pedido
FOR EACH ROW EXECUTE FUNCTION proteger_detalle_emitido();

CREATE FUNCTION proteger_pedido_emitido() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, salchipaperia AS $$
BEGIN
    IF (NEW.id_cliente <> OLD.id_cliente OR NEW.estado = 'Anulado') AND
       EXISTS (SELECT FROM comprobantes WHERE id_pedido = OLD.id_pedido) THEN
        RAISE EXCEPTION 'El pedido emitido conserva su cliente y requiere un flujo de anulación propio' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER pedido_emitido BEFORE UPDATE OF id_cliente, estado ON pedidos
FOR EACH ROW EXECUTE FUNCTION proteger_pedido_emitido();

CREATE FUNCTION validar_comprobante_nuevo() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, salchipaperia AS $$
DECLARE
    pedido pedidos%ROWTYPE;
BEGIN
    UPDATE pedidos SET estado = estado WHERE id_pedido = NEW.id_pedido RETURNING * INTO pedido;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El pedido no existe' USING ERRCODE = '23503';
    END IF;
    IF pedido.estado = 'Anulado' OR NEW.fecha_emision < pedido.fecha_pedido OR
       NOT EXISTS (SELECT FROM detalle_pedido WHERE id_pedido = NEW.id_pedido) THEN
        RAISE EXCEPTION 'La emisión requiere un pedido vigente con líneas y una fecha válida' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER comprobante_nuevo BEFORE INSERT ON comprobantes
FOR EACH ROW EXECUTE FUNCTION validar_comprobante_nuevo();

CREATE FUNCTION proteger_tipo_serie() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, salchipaperia AS $$
BEGIN
    IF NEW.id_tipo_comprobante <> OLD.id_tipo_comprobante THEN
        RAISE EXCEPTION 'La serie conserva su tipo de comprobante' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER serie_tipo_estable BEFORE UPDATE OF id_tipo_comprobante ON series_comprobante
FOR EACH ROW EXECUTE FUNCTION proteger_tipo_serie();

CREATE VIEW v_detalle_pedido AS
SELECT p.id_pedido, p.fecha_pedido, p.tipo_pedido, p.estado,
       prod.nombre AS producto, cat.nombre AS categoria,
       coalesce(s.porcion, format('%s ml · %s', b.volumen_ml, b.envase)) AS presentacion,
       d.cantidad, d.precio_unitario, d.cantidad * d.precio_unitario AS subtotal_linea
FROM detalle_pedido d
JOIN pedidos p USING (id_pedido)
JOIN productos prod USING (id_producto)
JOIN categorias cat USING (id_categoria)
LEFT JOIN snacks s USING (id_producto)
LEFT JOIN bebidas b USING (id_producto);

CREATE VIEW v_importes_comprobante AS
SELECT c.id_comprobante, c.id_pedido, c.serie, c.numero_correlativo, c.fecha_emision,
       c.tasa_igv, importes.total,
       round(importes.total / (1 + c.tasa_igv / 100), 2) AS base_imponible
FROM comprobantes c
CROSS JOIN LATERAL (
    SELECT sum(d.cantidad * d.precio_unitario) AS total
    FROM detalle_pedido d WHERE d.id_pedido = c.id_pedido
) importes;

CREATE VIEW v_conciliacion AS
SELECT c.id_pedido, c.id_comprobante,
       c.serie || '-' || lpad(c.numero_correlativo::text, 7, '0') AS comprobante,
       tc.nombre AS tipo_comprobante, c.fecha_emision, c.tasa_igv, c.base_imponible,
       c.total - c.base_imponible AS igv, c.total,
       coalesce(p.cobrado, 0) AS cobrado,
       c.total - coalesce(p.cobrado, 0) AS saldo
FROM v_importes_comprobante c
JOIN series_comprobante s USING (serie)
JOIN tipos_comprobante tc USING (id_tipo_comprobante)
LEFT JOIN LATERAL (
    SELECT sum(monto) AS cobrado FROM pagos WHERE id_comprobante = c.id_comprobante
) p ON true;

CREATE FUNCTION agregar_item(p_pedido bigint, p_producto bigint, p_cantidad integer) RETURNS void
LANGUAGE plpgsql SET search_path = pg_catalog, salchipaperia AS $$
DECLARE
    precio_actual numeric(10,2);
BEGIN
    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser positiva' USING ERRCODE = '23514';
    END IF;
    SELECT precio INTO precio_actual FROM productos WHERE id_producto = p_producto AND disponible;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Producto % indisponible o inexistente', p_producto USING ERRCODE = '23514';
    END IF;
    INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
    VALUES (p_pedido, p_producto, p_cantidad, precio_actual)
    ON CONFLICT (id_pedido, id_producto) DO UPDATE
    SET cantidad = detalle_pedido.cantidad + EXCLUDED.cantidad;
END;
$$;

CREATE FUNCTION emitir_comprobante(
    p_pedido bigint, p_serie varchar, p_tasa numeric, p_fecha timestamptz DEFAULT now()
) RETURNS bigint LANGUAGE plpgsql SET search_path = pg_catalog, salchipaperia AS $$
DECLARE
    pedido pedidos%ROWTYPE;
    existente comprobantes%ROWTYPE;
    correlativo integer;
    comprobante bigint;
BEGIN
    UPDATE pedidos SET estado = estado WHERE id_pedido = p_pedido RETURNING * INTO pedido;
    IF NOT FOUND OR pedido.estado = 'Anulado' THEN
        RAISE EXCEPTION 'El pedido no existe o está anulado' USING ERRCODE = '23514';
    END IF;

    SELECT * INTO existente FROM comprobantes WHERE id_pedido = p_pedido;
    IF FOUND THEN
        IF existente.serie IS DISTINCT FROM p_serie OR existente.tasa_igv IS DISTINCT FROM p_tasa THEN
            RAISE EXCEPTION 'El pedido ya se emitió con otra serie o tasa' USING ERRCODE = '23514';
        END IF;
        RETURN existente.id_comprobante;
    END IF;

    IF p_tasa IS NULL OR p_tasa NOT BETWEEN 0 AND 100 OR p_tasa <> round(p_tasa, 2) THEN
        RAISE EXCEPTION 'La tasa debe estar entre 0 y 100 con hasta dos decimales' USING ERRCODE = '23514';
    END IF;
    IF p_fecha < pedido.fecha_pedido OR NOT EXISTS (SELECT FROM detalle_pedido WHERE id_pedido = p_pedido) THEN
        RAISE EXCEPTION 'La emisión requiere un pedido con líneas y una fecha válida' USING ERRCODE = '23514';
    END IF;

    UPDATE series_comprobante SET ultimo_correlativo = ultimo_correlativo + 1
    WHERE serie = p_serie AND ultimo_correlativo < 9999999
    RETURNING ultimo_correlativo INTO correlativo;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'La serie no existe o agotó sus correlativos' USING ERRCODE = '23514';
    END IF;

    INSERT INTO comprobantes (id_pedido, serie, numero_correlativo, fecha_emision, tasa_igv)
    VALUES (p_pedido, p_serie, correlativo, p_fecha, p_tasa)
    RETURNING id_comprobante INTO comprobante;
    RETURN comprobante;
END;
$$;

CREATE FUNCTION comprobar_pago() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, salchipaperia AS $$
DECLARE
    referencia_obligatoria boolean;
    documento comprobantes%ROWTYPE;
    saldo_actual numeric;
BEGIN
    SELECT requiere_referencia INTO referencia_obligatoria
    FROM metodos_pago WHERE id_metodo_pago = NEW.id_metodo_pago;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Método de pago inexistente' USING ERRCODE = '23503';
    END IF;

    IF referencia_obligatoria AND nullif(btrim(NEW.numero_operacion), '') IS NULL THEN
        RAISE EXCEPTION 'El método de pago requiere número de operación' USING ERRCODE = '23514';
    END IF;

    -- Las escrituras sobre el mismo comprobante se serializan antes de consultar el saldo.
    UPDATE comprobantes SET tasa_igv = tasa_igv WHERE id_comprobante = NEW.id_comprobante
    RETURNING * INTO documento;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Comprobante inexistente' USING ERRCODE = '23503';
    END IF;
    SELECT saldo INTO saldo_actual FROM v_conciliacion WHERE id_comprobante = NEW.id_comprobante;

    IF NEW.fecha_pago < documento.fecha_emision OR saldo_actual IS NULL OR NEW.monto > saldo_actual THEN
        RAISE EXCEPTION 'El pago excede el saldo disponible (%) o su fecha es inválida', saldo_actual USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER pago_validado BEFORE INSERT ON pagos
FOR EACH ROW EXECUTE FUNCTION comprobar_pago();

CREATE FUNCTION proteger_documentos_emitidos() RETURNS trigger
LANGUAGE plpgsql SET search_path = pg_catalog, salchipaperia AS $$
BEGIN
    IF TG_OP = 'DELETE' OR OLD IS DISTINCT FROM NEW THEN
        RAISE EXCEPTION 'El comprobante o pago emitido conserva sus valores originales' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER comprobante_inmutable BEFORE UPDATE OR DELETE ON comprobantes
FOR EACH ROW EXECUTE FUNCTION proteger_documentos_emitidos();

CREATE TRIGGER pago_inmutable BEFORE UPDATE OR DELETE ON pagos
FOR EACH ROW EXECUTE FUNCTION proteger_documentos_emitidos();

REVOKE ALL ON ALL TABLES IN SCHEMA salchipaperia FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA salchipaperia FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA salchipaperia FROM PUBLIC;

COMMIT;
