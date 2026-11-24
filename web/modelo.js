import { estados, modalidades, seriePrueba } from './datos.js?v=20261124b';

const relacion = (tabla, columna, cardinalidad) => ({ tabla, columna, cardinalidad });

export const esquema = {
  clientes: { titulo: 'Clientes', icono: 'groups', clave: ['id_cliente'], columnas: ['id_cliente', 'nombres', 'apellidos', 'tipo_documento', 'numero_documento'], texto: 'Identifica a quien hace el pedido. Se admiten distintos tipos de documento.', relaciones: [relacion('pedidos', 'id_cliente', '1 a N'), relacion('telefonos_cliente', 'id_cliente', '1 a N')] },
  telefonos_cliente: { titulo: 'Teléfonos', icono: 'call', clave: ['id_telefono'], columnas: ['id_telefono', 'id_cliente', 'numero'], texto: 'Cada fila vincula un celular ficticio de nueve dígitos con su cliente.', relaciones: [relacion('clientes', 'id_cliente', 'N a 1')] },
  categorias: { titulo: 'Categorías', icono: 'category', clave: ['id_categoria'], columnas: ['id_categoria', 'nombre', 'descripcion', 'tipo_subtipo'], texto: 'Agrupa las secciones de la carta e indica el subtipo esperado.', relaciones: [relacion('productos', 'id_categoria', '1 a N')] },
  productos: { titulo: 'Productos', icono: 'restaurant_menu', clave: ['id_producto'], columnas: ['id_producto', 'id_categoria', 'nombre', 'precio', 'disponible'], texto: 'Mantiene el precio vigente. Las líneas de venta conservan el precio aplicado.', relaciones: [relacion('categorias', 'id_categoria', 'N a 1'), relacion('detalle_pedido', 'id_producto', '1 a N'), relacion('snacks', 'id_producto', '1 a 0..1'), relacion('bebidas', 'id_producto', '1 a 0..1')] },
  snacks: { titulo: 'Snacks', icono: 'lunch_dining', clave: ['id_producto'], columnas: ['id_producto', 'porcion', 'tipo_papa', 'incluye_cremas'], texto: 'Registra la presentación de cada producto, como cono, al plato o para compartir.', relaciones: [relacion('productos', 'id_producto', '1 a 1')] },
  bebidas: { titulo: 'Bebidas', icono: 'local_drink', clave: ['id_producto'], columnas: ['id_producto', 'volumen_ml', 'temperatura', 'envase'], texto: 'Añade datos de presentación cuando están disponibles en la carta.', relaciones: [relacion('productos', 'id_producto', '1 a 1')] },
  pedidos: { titulo: 'Pedidos', icono: 'shopping_bag', clave: ['id_pedido'], columnas: ['id_pedido', 'id_cliente', 'fecha_pedido', 'tipo_pedido', 'estado'], texto: 'Registra cliente, fecha, modalidad y estado de una venta.', relaciones: [relacion('clientes', 'id_cliente', 'N a 1'), relacion('detalle_pedido', 'id_pedido', '1 a N'), relacion('comprobantes', 'id_pedido', '1 a 0..1')] },
  detalle_pedido: { titulo: 'Detalle del pedido', icono: 'list_alt', clave: ['id_pedido', 'id_producto'], columnas: ['id_pedido', 'id_producto', 'cantidad', 'precio_unitario'], texto: 'Resuelve la relación entre pedidos y productos. Registra la cantidad y el precio aplicado.', relaciones: [relacion('pedidos', 'id_pedido', 'N a 1'), relacion('productos', 'id_producto', 'N a 1')] },
  tipos_comprobante: { titulo: 'Tipos de comprobante', icono: 'description', clave: ['id_tipo_comprobante'], columnas: ['id_tipo_comprobante', 'nombre'], texto: 'Enumera las clases documentales del modelo.', relaciones: [relacion('series_comprobante', 'id_tipo_comprobante', '1 a N')] },
  series_comprobante: { titulo: 'Series', icono: 'tag', clave: ['serie'], columnas: ['serie', 'id_tipo_comprobante', 'ultimo_correlativo'], texto: 'Administra el correlativo por serie. RP01 identifica los comprobantes de la muestra.', relaciones: [relacion('tipos_comprobante', 'id_tipo_comprobante', 'N a 1'), relacion('comprobantes', 'serie', '1 a N')] },
  comprobantes: { titulo: 'Comprobantes', icono: 'receipt_long', clave: ['id_comprobante'], columnas: ['id_comprobante', 'id_pedido', 'serie', 'numero_correlativo', 'fecha_emision', 'tasa_igv'], texto: 'Vincula un pedido a su comprobante. La emisión conserva el detalle.', relaciones: [relacion('pedidos', 'id_pedido', '1 a 1'), relacion('series_comprobante', 'serie', 'N a 1'), relacion('pagos', 'id_comprobante', '1 a N')] },
  metodos_pago: { titulo: 'Métodos de pago', icono: 'payments', clave: ['id_metodo_pago'], columnas: ['id_metodo_pago', 'nombre', 'requiere_referencia'], texto: 'Indica qué medios exigen una referencia de operación.', relaciones: [relacion('pagos', 'id_metodo_pago', '1 a N')] },
  pagos: { titulo: 'Pagos', icono: 'credit_card', clave: ['id_pago'], columnas: ['id_pago', 'id_comprobante', 'id_metodo_pago', 'monto', 'numero_operacion', 'fecha_pago'], texto: 'Acumula abonos por comprobante. Cada uno utiliza un método de pago.', relaciones: [relacion('comprobantes', 'id_comprobante', 'N a 1'), relacion('metodos_pago', 'id_metodo_pago', 'N a 1')] },
};

export const totalLineas = (lineas) => lineas.reduce((suma, linea) => suma + linea.cantidad * linea.precio_unitario, 0);
export const lineasDe = (tablas, pedido) => tablas.detalle_pedido.filter((linea) => linea.id_pedido === pedido);
export const documentoDe = (tablas, pedido) => tablas.comprobantes.find((doc) => doc.id_pedido === pedido);
export const pagosDe = (tablas, comprobante) => tablas.pagos.filter((pago) => pago.id_comprobante === comprobante);

export function conciliar(tablas, pedido) {
  const total = totalLineas(lineasDe(tablas, pedido));
  const comprobante = documentoDe(tablas, pedido);
  const pagos = comprobante ? pagosDe(tablas, comprobante.id_comprobante) : [];
  const cobrado = pagos.reduce((suma, pago) => suma + pago.monto, 0);
  const base = comprobante ? Math.round(total * 100 / (100 + comprobante.tasa_igv)) : null;
  return { comprobante, pagos, total, cobrado, saldo: total - cobrado, base, igv: base === null ? null : total - base };
}

export function dividirPago(saldo, efectivo) {
  if (!Number.isSafeInteger(efectivo) || efectivo < 0 || efectivo > saldo || saldo <= 0) {
    throw new Error('Ingresa un importe de efectivo entre cero y el saldo disponible.');
  }
  return { efectivo, yape: saldo - efectivo };
}

function obtenerPedido(tablas, id) {
  const pedido = tablas.pedidos.find((fila) => fila.id_pedido === id);
  if (!pedido) throw new Error('Selecciona un pedido disponible.');
  return pedido;
}

function editable(tablas, id) {
  const pedido = obtenerPedido(tablas, id);
  if (documentoDe(tablas, id) || pedido.estado === 'Anulado') throw new Error('Selecciona un pedido vigente y sin comprobante.');
  return pedido;
}

function obtenerLinea(tablas, id, producto) {
  const linea = tablas.detalle_pedido.find((fila) => fila.id_pedido === id && fila.id_producto === producto);
  if (!linea) throw new Error('La línea ya no existe en el pedido.');
  return linea;
}

function filasCambiadas(antes, despues, tablas) {
  return tablas.split(', ').flatMap((tabla) => {
    const { clave, columnas } = esquema[tabla];
    const conClave = (filas) => new Map(filas.map((fila) => [JSON.stringify(clave.map((campo) => fila[campo])), fila]));
    const previas = conClave(antes[tabla]);
    const nuevas = conClave(despues[tabla]);
    return [...new Set([...previas.keys(), ...nuevas.keys()])].flatMap((id) => {
      const previa = previas.get(id);
      const nueva = nuevas.get(id);
      const campos = columnas.filter((campo) => previa?.[campo] !== nueva?.[campo]);
      return campos.length ? [{ tabla, previa, nueva, campos }] : [];
    });
  });
}

export function operar(base, accion) {
  const siguiente = structuredClone(base);
  const { tablas, secuencias, cambios } = siguiente;
  const { tipo, id, producto } = accion;
  const fecha = new Date().toISOString();
  let elegido = id;
  let mensaje;
  let cambia;

  switch (tipo) {
    case 'crear':
    case 'editar-pedido': {
      if (!tablas.clientes.some((cliente) => cliente.id_cliente === accion.cliente) || !modalidades.includes(accion.modalidad)) {
        throw new Error('Selecciona un cliente de prueba y una modalidad.');
      }
      if (tipo === 'crear') {
        elegido = secuencias.pedido++;
        tablas.pedidos.push({ id_pedido: elegido, id_cliente: accion.cliente, tipo_pedido: accion.modalidad, fecha_pedido: fecha, estado: 'Pendiente' });
        mensaje = `Se creó el pedido #${elegido}.`;
      } else {
        const pedido = editable(tablas, id);
        Object.assign(pedido, { id_cliente: accion.cliente, tipo_pedido: accion.modalidad });
        mensaje = `Se guardó el cliente y la modalidad del pedido #${id}.`;
      }
      cambia = 'pedidos';
      break;
    }
    case 'agregar':
    case 'cantidad': {
      editable(tablas, id);
      if (!Number.isInteger(accion.cantidad) || accion.cantidad < 1 || accion.cantidad > 999) throw new Error('La cantidad debe estar entre 1 y 999.');
      const ficha = tablas.productos.find((fila) => fila.id_producto === producto && fila.disponible);
      if (!ficha) throw new Error('Elige un producto disponible.');
      const linea = lineasDe(tablas, id).find((fila) => fila.id_producto === producto);
      if (tipo === 'cantidad' && !linea) throw new Error('Selecciona una línea existente.');
      if (linea) {
        const nuevaCantidad = tipo === 'cantidad' ? accion.cantidad : linea.cantidad + accion.cantidad;
        if (nuevaCantidad > 999) throw new Error('Cada línea admite hasta 999 unidades.');
        linea.cantidad = nuevaCantidad;
      } else {
        tablas.detalle_pedido.push({ id_pedido: id, id_producto: producto, cantidad: accion.cantidad, precio_unitario: ficha.precio });
      }
      mensaje = `Se ${tipo === 'cantidad' ? 'actualizó' : 'agregó'} ${ficha.nombre} en el pedido #${id}.`;
      cambia = 'detalle_pedido';
      break;
    }
    case 'mover': {
      editable(tablas, id);
      editable(tablas, accion.destino);
      if (id === accion.destino) throw new Error('Selecciona un pedido de destino diferente.');
      const origen = obtenerLinea(tablas, id, producto);
      const destino = lineasDe(tablas, accion.destino).find((fila) => fila.id_producto === producto);
      if (destino) {
        if (origen.precio_unitario !== destino.precio_unitario) throw new Error('Los precios históricos difieren entre los pedidos.');
        if (origen.cantidad + destino.cantidad > 999) throw new Error('El traslado excede el máximo de unidades por línea.');
        destino.cantidad += origen.cantidad;
        tablas.detalle_pedido = tablas.detalle_pedido.filter((fila) => fila !== origen);
      } else {
        origen.id_pedido = accion.destino;
      }
      mensaje = `Se movió la línea del pedido #${id} al #${accion.destino}.`;
      cambia = 'detalle_pedido';
      break;
    }
    case 'borrar-linea': {
      editable(tablas, id);
      const linea = obtenerLinea(tablas, id, producto);
      tablas.detalle_pedido = tablas.detalle_pedido.filter((fila) => fila !== linea);
      mensaje = `Se borró una línea del pedido #${id}.`;
      cambia = 'detalle_pedido';
      break;
    }
    case 'estado': {
      const pedido = obtenerPedido(tablas, id);
      if (!estados.includes(accion.estado)) throw new Error('Selecciona un estado válido.');
      if (documentoDe(tablas, id) && accion.estado === 'Anulado') throw new Error('El comprobante emitido requiere su propio flujo de anulación.');
      pedido.estado = accion.estado;
      mensaje = `El pedido #${id} pasó a «${accion.estado}».`;
      cambia = 'pedidos';
      break;
    }
    case 'borrar-pedido': {
      obtenerPedido(tablas, id);
      if (documentoDe(tablas, id)) throw new Error('El pedido tiene un comprobante asociado.');
      tablas.pedidos = tablas.pedidos.filter((fila) => fila.id_pedido !== id);
      tablas.detalle_pedido = tablas.detalle_pedido.filter((fila) => fila.id_pedido !== id);
      elegido = tablas.pedidos.findLast((fila) => !documentoDe(tablas, fila.id_pedido))?.id_pedido ?? tablas.pedidos.at(-1)?.id_pedido;
      mensaje = `Se borró el pedido #${id} con sus líneas.`;
      cambia = 'pedidos, detalle_pedido';
      break;
    }
    case 'emitir': {
      const pedido = editable(tablas, id);
      if (lineasDe(tablas, id).length === 0) throw new Error('Agrega un producto antes de emitir.');
      const serie = tablas.series_comprobante.find((fila) => fila.serie === seriePrueba);
      const fechaEmision = new Date(Math.max(Date.parse(fecha), Date.parse(pedido.fecha_pedido))).toISOString();
      tablas.comprobantes.push({ id_comprobante: secuencias.comprobante++, id_pedido: id, serie: serie.serie,
        numero_correlativo: ++serie.ultimo_correlativo, fecha_emision: fechaEmision, tasa_igv: 18 });
      mensaje = `Se emitió el comprobante de prueba del pedido #${id}.`;
      cambia = 'comprobantes, series_comprobante';
      break;
    }
    case 'abonar': {
      const { comprobante, saldo } = conciliar(tablas, id);
      if (!comprobante) throw new Error('Emite un comprobante de prueba antes del abono.');
      const { efectivo, yape } = dividirPago(saldo, accion.efectivo);
      const fechaPago = new Date(Math.max(Date.parse(fecha), Date.parse(comprobante.fecha_emision))).toISOString();
      for (const [id_metodo_pago, monto] of [['MP01', efectivo], ['MP02', yape]]) {
        if (monto === 0) continue;
        const id_pago = secuencias.pago++;
        tablas.pagos.push({ id_pago, id_comprobante: comprobante.id_comprobante, id_metodo_pago, monto,
          numero_operacion: id_metodo_pago === 'MP02' ? `PRACTICA-${id_pago}` : null, fecha_pago: fechaPago });
      }
      mensaje = `Se registró el abono de práctica del pedido #${id}. Saldo: S/ 0.00.`;
      cambia = 'pagos';
      break;
    }
    default:
      throw new Error('La operación solicitada no está disponible.');
  }

  cambios.unshift({ mensaje, tabla: cambia, filas: filasCambiadas(base.tablas, tablas, cambia) });
  cambios.splice(12);
  return { base: siguiente, elegido, mensaje };
}
