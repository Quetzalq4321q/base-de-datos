// Datos retirados del portal. Solo se usan para reproducir las cargas anteriores a la migración 10.
import { bebidas, categorias as grupos, clientes as nombres, hamburguesas, productos, snacks as porciones, ventas as pedidos } from '../web/datos.js';

export { bebidas, productos };
export const categorias = grupos.map((fila) => ({ ...fila, tipo_subtipo: fila.id_categoria === 'RPBEB' ? 'bebida' : 'snack' }));
export const clientes = nombres.map((fila) => ({
  ...fila, tipo_documento: 'CE', numero_documento: `RPDEMO${String(fila.id_cliente).padStart(3, '0')}`,
}));
export const snacks = [...porciones, ...hamburguesas.map(({ id_producto }) => ({ id_producto, porcion: 'Hamburguesa con papas' }))];
export const telefonos = ['931640728', '964285317', '927536041', '982471635', '956317284', '913748562'].map((numero, indice) => ({
  id_telefono: indice + 1, id_cliente: clientes[indice].id_cliente, numero,
}));

export const seriePrueba = 'RP01';
export const ventas = pedidos.map(({ pedido, detalle }, indice) => {
  const id = pedido.id_pedido;
  const total = detalle.reduce((suma, item) => suma + item.cantidad * item.precio_unitario, 0);
  const fecha_emision = new Date(Date.parse(pedido.fecha_pedido) + 120000).toISOString();
  const comprobante = { id_comprobante: id, id_pedido: id, serie: seriePrueba, numero_correlativo: id, fecha_emision, tasa_igv: 18 };
  const efectivo = Math.floor(total / 200) * 100;
  const abonos = indice % 5 === 0 ? [[1, efectivo], [2, total - efectivo]] : [[indice % 4 + 1, total]];
  const pagos = abonos.map(([metodo, monto], orden) => ({
    id_comprobante: id, id_metodo_pago: `MP0${metodo}`, monto,
    numero_operacion: metodo === 1 ? null : `RP-DEMO-${id}-${orden + 1}`,
    fecha_pago: new Date(Date.parse(fecha_emision) + (orden + 1) * 30000).toISOString(),
  }));
  return { pedido, detalle, comprobante, pagos };
});
