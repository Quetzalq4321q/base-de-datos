export const categorias = [
  { id_categoria: 'RPSAN', nombre: 'Sánguches', tipo_subtipo: 'snack' },
  { id_categoria: 'RPEMP', nombre: 'Empanadas', tipo_subtipo: 'snack' },
  { id_categoria: 'RPSAL', nombre: 'Salchipapas', tipo_subtipo: 'snack' },
  { id_categoria: 'RPPLA', nombre: 'Salchipapas al plato', tipo_subtipo: 'snack' },
  { id_categoria: 'RPCOM', nombre: 'Para compartir', tipo_subtipo: 'snack' },
  { id_categoria: 'RPHAM', nombre: 'Hamburguesas', tipo_subtipo: 'snack' },
  { id_categoria: 'RPBEB', nombre: 'Bebidas de la carta', tipo_subtipo: 'bebida' },
];

const carta = [
  ['RPSAN', 'Triple clásico', 500, 'Sánguche'],
  ['RPSAN', 'Triple mixto', 550, 'Sánguche'],
  ['RPSAN', 'Triple de durazno', 600, 'Sánguche'],
  ['RPSAN', 'Baguetino de pollo a la brasa', 700, 'Baguetino'],
  ...['Ají de gallina', 'Rocoto relleno', 'Lomo saltado', 'Pizza', 'Hawaiana', 'Queso', 'Triple', 'Chorizo']
    .map((relleno) => ['RPEMP', `Empanada de ${relleno.toLowerCase()}`, 500, 'Empanada']),
  ['RPSAL', 'Salchicono', 500, 'Cono', true],
  ['RPSAL', 'Cono Mix', 600, 'Cono', true],
  ['RPSAL', 'Salchipapa clásica', 800, 'Porción estándar', true],
  ['RPSAL', 'Double Black', 900, 'Porción estándar', true],
  ['RPSAL', 'Choripapas', 1000, 'Porción estándar', true],
  ['RPSAL', 'Salchibrasa', 1000, 'Porción estándar', true],
  ['RPPLA', 'Salchichaufa', 1200, 'Al plato', true],
  ['RPPLA', 'Mostrito con pechuga a la plancha', 1600, 'Al plato'],
  ['RPPLA', 'Jack Pepper', 1400, 'Al plato'],
  ['RPPLA', 'Cheese Pepper', 1500, 'Al plato', true],
  ['RPCOM', 'Extrema', 3000, 'Bandeja para 4 personas'],
  ['RPCOM', 'La Gaucha', 2500, 'Para 4 personas'],
  ...[['Hamburguesa clásica', 800], ['Cheese Burguer', 900], ['La Royal', 1000], ['Doble Burguer', 1500]]
    .flatMap(([nombre, precio]) => ['res', 'pollo'].map((carne) => ['RPHAM', `${nombre} de ${carne}`, precio, 'Hamburguesa con papas'])),
  ['RPBEB', 'Chicha morada', 300],
  ['RPBEB', 'Maracuyá', 300],
  ['RPBEB', 'Coca-Cola', 400],
  ['RPBEB', 'Inca Kola', 400],
  ['RPBEB', 'Fanta', 350],
  ['RPBEB', 'Agua Cielo', 200],
];

export const productos = carta.map(([id_categoria, nombre, precio], indice) => ({
  id_producto: indice + 1, id_categoria, nombre, precio, disponible: true,
}));

export const snacks = productos.filter((p) => p.id_categoria !== 'RPBEB').map(({ id_producto }) => ({
  id_producto, porcion: carta[id_producto - 1][3], tipo_papa: null, incluye_cremas: carta[id_producto - 1][4] ?? null,
}));

export const bebidas = productos.filter((p) => p.id_categoria === 'RPBEB').map(({ id_producto }) => ({
  id_producto, volumen_ml: null, temperatura: null, envase: null,
}));

const identidadesFicticias = [
  ['Lucía Elena', 'Salazar Vega'], ['Diego Alonso', 'Huamán Paredes'], ['Camila', 'Rojas Quispe'],
  ['Mateo Andrés', 'Cáceres Flores'], ['Valeria Inés', 'Mendoza Rivas'], ['Sebastián', 'Torres Zavaleta'],
  ['Adriana Milagros', 'Condori Núñez'], ['Nicolás', 'Chávez Medina'], ['Mariana Sofía', 'Vargas León'],
  ['Gabriel Andrés', 'Benavides Soto'], ['Renata', 'Ponce Aguilar'], ['Joaquín', 'Velásquez Campos'],
];

export const clientes = identidadesFicticias.map(([nombres, apellidos], indice) => ({
  id_cliente: indice + 1, nombres, apellidos,
  tipo_documento: 'CE', numero_documento: `RPDEMO${String(indice + 1).padStart(3, '0')}`,
}));

// Números inventados para la práctica. Se guardan como texto, sin separadores.
export const telefonos = ['931640728', '964285317', '927536041', '982471635', '956317284', '913748562'].map((numero, indice) => ({
  id_telefono: indice + 1, id_cliente: clientes[indice].id_cliente, numero,
}));

export function mostrarCelular(numero) {
  return numero.replace(/^(9\d{2})(\d{3})(\d{3})$/, '$1 $2 $3');
}

export const metodos = [
  { id_metodo_pago: 'MP01', nombre: 'Efectivo', requiere_referencia: false },
  { id_metodo_pago: 'MP02', nombre: 'Yape', requiere_referencia: true },
  { id_metodo_pago: 'MP03', nombre: 'Plin', requiere_referencia: true },
  { id_metodo_pago: 'MP04', nombre: 'Tarjeta de Débito/Crédito', requiere_referencia: true },
];

export const modalidades = ['En local', 'Para llevar', 'Delivery'];
export const estados = ['Pendiente', 'En Cocina', 'Entregado', 'Anulado'];
export const seriePrueba = 'RP01';
export const comprobanteTexto = (c) => `${c.serie}-${String(c.numero_correlativo).padStart(7, '0')}`;

function fechaVenta(indice) {
  const dia = new Date(Date.UTC(2026, 9, 24 + Math.floor(indice * 30 / 100))).toISOString().slice(0, 10);
  const hora = String(12 + (indice * 7) % 9).padStart(2, '0');
  const minutos = String((indice * 13) % 60).padStart(2, '0');
  return `${dia}T${hora}:${minutos}:00-05:00`;
}

function linea(id_pedido, producto, cantidad) {
  return { id_pedido, id_producto: producto.id_producto, cantidad, precio_unitario: producto.precio };
}

export const ventas = Array.from({ length: 100 }, (_, indice) => {
  const id = indice + 1;
  const pedido = {
    id_pedido: id, id_cliente: (indice * 5) % clientes.length + 1, fecha_pedido: fechaVenta(indice),
    tipo_pedido: modalidades[indice % modalidades.length], estado: 'Entregado',
  };
  const detalle = [linea(id, productos[indice % snacks.length], 1 + indice % 3)];
  if (indice % 7 !== 6) {
    detalle.push(linea(id, productos[snacks.length + Math.floor(indice / 2) % bebidas.length], 1 + indice % 2));
  }
  const total = detalle.reduce((suma, item) => suma + item.cantidad * item.precio_unitario, 0);
  const fecha_emision = new Date(Date.parse(pedido.fecha_pedido) + 120000).toISOString();
  const comprobante = { id_comprobante: id, id_pedido: id, serie: seriePrueba, numero_correlativo: id, fecha_emision, tasa_igv: 18 };
  const distribuir = indice % 5 === 0;
  const efectivo = Math.floor(total / 200) * 100;
  const pagos = (distribuir
    ? [[metodos[0], efectivo], [metodos[1], total - efectivo]]
    : [[metodos[indice % metodos.length], total]]
  ).map(([metodo, monto], orden) => ({
    id_comprobante: id, id_metodo_pago: metodo.id_metodo_pago, monto,
    numero_operacion: metodo.requiere_referencia ? `RP-DEMO-${id}-${orden + 1}` : null,
    fecha_pago: new Date(Date.parse(fecha_emision) + (orden + 1) * 30000).toISOString(),
  }));
  return { pedido, detalle, comprobante, pagos };
});

export function crearBase() {
  const pedidos = ventas.map(({ pedido }) => pedido);
  const detalle = ventas.flatMap((venta) => venta.detalle);
  const borradores = [
    { id_pedido: 101, id_cliente: 1, fecha_pedido: '2026-11-23T10:00:00-05:00', tipo_pedido: 'En local', estado: 'Pendiente' },
    { id_pedido: 102, id_cliente: 2, fecha_pedido: '2026-11-23T10:05:00-05:00', tipo_pedido: 'Para llevar', estado: 'Pendiente' },
  ];
  const pagos = ventas.flatMap((venta) => venta.pagos).map((pago, indice) => ({ ...pago, id_pago: indice + 1 }));
  return structuredClone({
    tablas: {
      clientes, telefonos_cliente: telefonos, categorias, productos, snacks, bebidas,
      pedidos: [...pedidos, ...borradores], detalle_pedido: [...detalle, linea(101, productos[12], 1), linea(102, productos[32], 1)],
      tipos_comprobante: [{ id_tipo_comprobante: 'TC01', nombre: 'Boleta de venta' }, { id_tipo_comprobante: 'TC02', nombre: 'Factura' }],
      series_comprobante: [{ serie: seriePrueba, id_tipo_comprobante: 'TC01', ultimo_correlativo: ventas.length }],
      comprobantes: ventas.map(({ comprobante }) => comprobante), metodos_pago: metodos, pagos,
    },
    secuencias: { pedido: 103, comprobante: 101, pago: pagos.length + 1 },
    cambios: [],
  });
}
