import { conexion } from './conexion.js';

const ejemplo = [
  {
    comprobante: 'B001-0000001', base: 17.80, igv: 3.20, total: 21, cobrado: 21, saldo: 0,
    detalle: [
      { producto: 'Salchipapa Especial', presentacion: 'Personal Grande', cantidad: 2, total: 14 },
      { producto: 'Coca-Cola 500 ml', presentacion: '500 ml · Botella plástica', cantidad: 2, total: 7 },
    ],
    pagos: [{ metodo: 'Efectivo', monto: 10 }, { metodo: 'Yape', monto: 11 }],
  },
  {
    comprobante: 'B001-0000002', base: 20.34, igv: 3.66, total: 24, cobrado: 24, saldo: 0,
    detalle: [
      { producto: 'Salchipapa Familiar', presentacion: 'Familiar', cantidad: 1, total: 18 },
      { producto: 'Chicha Morada 1 L', presentacion: '1000 ml · Jarra de vidrio', cantidad: 1, total: 6 },
    ],
    pagos: [{ metodo: 'Plin', monto: 24 }],
  },
];

const id = (nombre) => document.getElementById(nombre);
const selector = id('comprobante');
const efectivo = id('efectivo');
const moneda = new Intl.NumberFormat('es-PE', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const soles = (importe) => `S/ ${moneda.format(importe)}`;
const centavos = (importe) => Math.round(Number(importe) * 100);
const claveCache = `red-pepper-demo-v1:${conexion?.url ?? ''}`;
let pedidos = ejemplo;

function nodo(etiqueta, texto = '', estilo = '') {
  const elemento = document.createElement(etiqueta);
  elemento.textContent = texto;
  if (estilo) elemento.className = estilo;
  return elemento;
}

function pedidoElegido() {
  return pedidos.find((pedido) => pedido.comprobante === selector.value);
}

function actualizarSimulacion() {
  const total = centavos(pedidoElegido().total);
  efectivo.max = (total / 100).toFixed(2);
  const valido = efectivo.validity.valid;
  id('yape').textContent = valido ? soles((total - centavos(efectivo.value)) / 100) : '—';
  id('simular').disabled = !valido;
  id('resultado').textContent = '';
}

function mostrarDetalle() {
  const pedido = pedidoElegido();
  for (const boton of id('conciliacion-filas').querySelectorAll('button')) {
    boton.setAttribute('aria-pressed', String(boton.dataset.comprobante === pedido.comprobante));
  }
  id('detalle-comprobante').textContent = pedido.comprobante;
  id('detalle-filas').replaceChildren(...pedido.detalle.map((linea) => {
    const fila = nodo('tr');
    const producto = nodo('td', linea.producto);
    producto.append(nodo('small', linea.presentacion));
    fila.append(producto, nodo('td', linea.cantidad, 'numero'), nodo('td', soles(linea.total), 'numero'));
    return fila;
  }));
  id('detalle-pagos').replaceChildren(...pedido.pagos.map((pago) => {
    const fila = nodo('li');
    fila.append(nodo('span', pago.metodo), nodo('span', soles(pago.monto), 'importe'));
    return fila;
  }));
  const importes = [['Base imponible', pedido.base], ['IGV del ejercicio', pedido.igv], ['Total', pedido.total]];
  id('detalle-importes').replaceChildren(...importes.map(([concepto, importe]) => {
    const fila = nodo('div');
    fila.append(nodo('dt', concepto), nodo('dd', soles(importe), 'importe'));
    return fila;
  }));
  actualizarSimulacion();
}

function presentar(datos, origen, conectado = false) {
  const seleccionado = selector.value;
  pedidos = datos;
  id('origen').textContent = origen;
  id('origen').dataset.conectado = String(conectado);
  id('pedidos').textContent = String(pedidos.length);
  for (const campo of ['cobrado', 'saldo']) {
    id(campo).textContent = soles(pedidos.reduce((suma, pedido) => suma + centavos(pedido[campo]), 0) / 100);
  }
  selector.replaceChildren(...pedidos.map((pedido) => new Option(pedido.comprobante, pedido.comprobante)));
  if (pedidos.some((pedido) => pedido.comprobante === seleccionado)) selector.value = seleccionado;

  id('conciliacion-filas').replaceChildren(...pedidos.map((pedido) => {
    const fila = nodo('tr');
    const documento = nodo('td');
    const boton = nodo('button', pedido.comprobante, 'elegir');
    boton.type = 'button';
    boton.dataset.comprobante = pedido.comprobante;
    boton.addEventListener('click', () => {
      selector.value = pedido.comprobante;
      mostrarDetalle();
    });
    documento.append(boton, nodo('small', pedido.pagos.map((pago) => pago.metodo).join(' + ')));
    fila.append(documento, ...['total', 'cobrado', 'saldo'].map((campo) => nodo('td', soles(pedido[campo]), 'numero')));
    return fila;
  }));
  mostrarDetalle();
}

function leerCache() {
  try {
    return JSON.parse(sessionStorage.getItem(claveCache));
  } catch {
    return null;
  }
}

async function cargarDatos(forzar = false) {
  if (!conexion) {
    presentar(ejemplo, 'Datos de demostración');
    return;
  }

  const cache = leerCache();
  if (!forzar && cache && Date.now() < cache.vence) {
    presentar(cache.pedidos, 'Datos recientes de Supabase', true);
    return;
  }

  const boton = id('actualizar');
  boton.disabled = true;
  id('origen').textContent = 'Consultando Supabase';
  id('origen').dataset.conectado = 'false';
  try {
    const endpoint = `${conexion.url}/rest/v1/rpc/red_pepper_demo_resumen`;
    const respuesta = await fetch(endpoint, {
      headers: { apikey: conexion.publishableKey },
      signal: AbortSignal.timeout(8000),
    });
    if (!respuesta.ok) throw new Error(`HTTP ${respuesta.status}`);
    const datos = await respuesta.json();
    if (!Array.isArray(datos.pedidos) || datos.pedidos.length !== 2) throw new Error('Muestra incompleta');
    presentar(datos.pedidos, 'PostgreSQL conectado', true);
    try {
      sessionStorage.setItem(claveCache, JSON.stringify({ pedidos: datos.pedidos, vence: Date.now() + 120000 }));
    } catch {
      // La consulta sigue disponible cuando el navegador desactiva el almacenamiento.
    }
  } catch {
    presentar(ejemplo, 'Supabase no disponible · Datos de demostración');
  } finally {
    boton.disabled = false;
  }
}

selector.addEventListener('change', mostrarDetalle);
efectivo.addEventListener('input', actualizarSimulacion);
id('actualizar').hidden = !conexion;
id('actualizar').addEventListener('click', () => cargarDatos(true));
id('pago').addEventListener('submit', (evento) => {
  evento.preventDefault();
  const pedido = pedidoElegido();
  const montoEfectivo = centavos(efectivo.value);
  const montoYape = centavos(pedido.total) - montoEfectivo;
  id('resultado').textContent = `Simulación conciliada · Efectivo ${soles(montoEfectivo / 100)} · Yape ${soles(montoYape / 100)}`;
});

presentar(ejemplo, 'Datos de demostración');
await cargarDatos();
