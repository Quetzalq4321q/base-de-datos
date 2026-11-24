import { clientes, comprobanteTexto, crearBase, estados, modalidades } from './datos.js?v=20261123c';
import { conciliar, dividirPago, documentoDe, esquema, lineasDe, operar, totalLineas } from './modelo.js?v=20261123c';

const pasos = [
  ['Modelo de datos', 'Sigue una venta desde la persona que pide hasta el último abono.', 'account_tree', 'modelo', 'Modelo'],
  ['Explorar tablas', 'Abre las 13 tablas, busca registros y sigue sus claves foráneas.', 'table_view', 'tablas', 'Explorar tablas'],
  ['Editar pedidos', 'Practica con una comanda y observa qué filas cambian en el modelo.', 'edit_note', 'editar', 'Editar pedidos'],
  ['Comprobantes y pagos', 'Emite un comprobante de práctica y reparte el saldo entre efectivo y Yape.', 'receipt_long', 'cobros', 'Comprobantes y pagos'],
];

const id = (nombre) => document.getElementById(nombre);
const moneda = new Intl.NumberFormat('es-PE', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const fechaLima = new Intl.DateTimeFormat('es-PE', { timeZone: 'America/Lima', dateStyle: 'short', timeStyle: 'short' });
const soles = (centavos) => `S/ ${moneda.format(centavos / 100)}`;
const camposMoneda = new Set(['precio', 'precio_unitario', 'monto']);
const claveLocal = 'red-pepper-laboratorio-v2';
const referencias = {
  id_cliente: 'clientes', id_categoria: 'categorias', id_producto: 'productos', id_pedido: 'pedidos',
  id_comprobante: 'comprobantes', id_tipo_comprobante: 'tipos_comprobante', serie: 'series_comprobante', id_metodo_pago: 'metodos_pago',
};

function cargar() {
  try {
    const anterior = JSON.parse(localStorage.getItem(claveLocal));
    if (anterior?.secuencias && Array.isArray(anterior.cambios) && Object.keys(esquema).every((tabla) => Array.isArray(anterior.tablas?.[tabla]))) {
      for (const cliente of anterior.tablas.clientes) {
        const ficha = clientes.find((muestra) => muestra.numero_documento === cliente.numero_documento && muestra.tipo_documento === cliente.tipo_documento);
        if (ficha) Object.assign(cliente, { nombres: ficha.nombres, apellidos: ficha.apellidos });
      }
      return anterior;
    }
  } catch {
    // El laboratorio puede iniciarse aunque el almacenamiento no esté disponible.
  }
  return crearBase();
}

let base = cargar();
let anterior = null;
let paso = 0;
let tablaModelo = 'pedidos';
let tablaDatos = 'pedidos';
let filtroClave = null;
let pagina = 0;
let pedidoActivo = base.tablas.pedidos.find((p) => p.id_pedido === 101)?.id_pedido ?? base.tablas.pedidos.at(-1).id_pedido;
let accionDialogo;

function nodo(etiqueta, texto = '', clase = '') {
  const elemento = document.createElement(etiqueta);
  elemento.textContent = texto;
  if (clase) elemento.className = clase;
  return elemento;
}

function icono(nombre) {
  const figura = nodo('span', nombre, 'icono');
  figura.setAttribute('aria-hidden', 'true');
  return figura;
}

function boton(texto, accion, nombreIcono, clase = 'boton secundario') {
  const control = nodo('button', '', clase);
  control.type = 'button';
  if (nombreIcono) control.append(icono(nombreIcono));
  control.append(document.createTextNode(texto));
  control.addEventListener('click', accion);
  return control;
}

function opciones(control, filas, valor, etiqueta, elegido) {
  control.replaceChildren(...filas.map((fila) => new Option(etiqueta(fila), valor(fila))));
  if (elegido !== undefined) control.value = String(elegido);
}

function registros(columnas, filas, titulo) {
  if (filas.length === 0) return nodo('p', 'No hay filas para esta consulta.', 'sin-lineas apagado');
  const marco = nodo('div', '', 'registros');
  marco.tabIndex = 0;
  marco.setAttribute('role', 'region');
  marco.setAttribute('aria-label', titulo);
  const tabla = nodo('table');
  tabla.createTHead().insertRow().append(...columnas.map((col) => {
    const encabezado = nodo('th', col.texto, col.clase);
    encabezado.scope = 'col';
    return encabezado;
  }));
  const cuerpo = tabla.createTBody();
  for (const fila of filas) {
    const renglon = cuerpo.insertRow();
    for (let indice = 0; indice < fila.length; indice++) {
      const celda = nodo('td', '', columnas[indice].clase);
      celda.append(fila[indice]);
      renglon.append(celda);
    }
  }
  marco.append(tabla);
  return marco;
}

function mostrarAviso(mensaje, error = false) {
  const aviso = id('aviso');
  aviso.hidden = !mensaje;
  aviso.textContent = mensaje;
  aviso.dataset.error = String(error);
}

function guardar(mensaje) {
  try {
    localStorage.setItem(claveLocal, JSON.stringify(base));
    mostrarAviso(mensaje);
  } catch {
    mostrarAviso(`${mensaje} Los cambios quedan disponibles hasta cerrar la página.`);
  }
}

function ir(indice, enfocar = true) {
  if (!pasos[indice]) return;
  paso = indice;
  const [titulo, descripcion, simbolo, ruta, resumen] = pasos[indice];
  document.querySelectorAll('[data-paso]').forEach((control, i) => {
    if (i === paso) control.setAttribute('aria-current', 'step');
    else control.removeAttribute('aria-current');
    id(pasos[i][3]).hidden = i !== paso;
  });
  id('paso-titulo').textContent = titulo;
  id('paso-descripcion').textContent = descripcion;
  id('hero-icono').textContent = simbolo;
  id('progreso').textContent = `Paso ${indice + 1} de ${pasos.length}`;
  id('paso-pie').textContent = resumen;
  id('anterior').disabled = paso === 0;
  id('siguiente').disabled = paso === pasos.length - 1;
  mostrarAviso('');
  if (enfocar) {
    history.replaceState(null, '', `#${ruta}`);
    id('paso-titulo').focus();
  }
  mostrarPantalla();
}

function mostrarPantalla() {
  [mostrarModelo, mostrarTablas, mostrarPedido, mostrarCobros][paso]();
}

function elegirTabla(tabla, clave = null) {
  tablaDatos = tabla;
  filtroClave = clave;
  id('buscar').value = clave ? String(clave.valor) : '';
  pagina = 0;
  if (paso === 1) {
    mostrarTablas();
    if (clave) id('tabla-titulo').focus();
  } else ir(1);
}

function mostrarModelo() {
  id('cantidad-tablas').textContent = Object.keys(esquema).length;
  id('cantidad-productos').textContent = base.tablas.productos.length;
  id('cantidad-ventas').textContent = base.tablas.comprobantes.length;
  for (const control of id('mapa').querySelectorAll('[data-tabla]')) {
    control.setAttribute('aria-pressed', String(control.dataset.tabla === tablaModelo));
  }
  const ficha = esquema[tablaModelo];
  const datos = nodo('dl', '', 'claves');
  datos.append(nodo('dt', 'Clave primaria'), nodo('dd', ficha.clave.join(' + '), 'codigo'));
  const relaciones = nodo('ul', '', 'enlaces-tabla');
  for (const relacion of ficha.relaciones) {
    const elemento = nodo('li');
    elemento.append(boton(esquema[relacion.tabla].titulo, () => {
      tablaModelo = relacion.tabla;
      mostrarModelo();
      id('inspector').querySelector('h2').focus();
    }, null, 'enlace-boton'), nodo('span', `${relacion.columna} · ${relacion.cardinalidad}`, 'codigo'));
    relaciones.append(elemento);
  }
  const titulo = nodo('h2', ficha.titulo);
  titulo.tabIndex = -1;
  id('inspector').replaceChildren(titulo, nodo('p', tablaModelo, 'codigo'), nodo('p', ficha.texto), datos,
    nodo('h3', 'Tablas relacionadas'), relaciones, boton('Ver filas', () => elegirTabla(tablaModelo), 'table_view'));
}

function crearMapa() {
  const grupos = [
    ['De la carta al pedido', ['clientes', 'pedidos', 'detalle_pedido', 'productos'], true],
    ['Del pedido al cobro', ['pedidos', 'comprobantes', 'pagos'], true],
    ['Catálogos y datos relacionados', ['telefonos_cliente', 'categorias', 'snacks', 'bebidas', 'tipos_comprobante', 'series_comprobante', 'metodos_pago'], false],
  ];
  for (const [titulo, tablas, cadena] of grupos) {
    const grupo = nodo('section', '', 'grupo-mapa');
    const lista = nodo('div', '', cadena ? 'lineas-flujo' : 'entidades');
    for (const tabla of tablas) {
      const f = esquema[tabla];
      const control = boton(f.titulo, () => { tablaModelo = tabla; mostrarModelo(); }, f.icono, 'opcion');
      control.dataset.tabla = tabla;
      if (cadena) {
        const celda = nodo('div');
        celda.append(control);
        lista.append(celda);
      } else lista.append(control);
    }
    grupo.append(nodo('h3', titulo), lista);
    id('mapa').append(grupo);
  }
}

function mostrarValor(campo, valor) {
  if (valor === null || valor === undefined) return '—';
  if (camposMoneda.has(campo)) return soles(valor);
  if (campo.startsWith('fecha_')) return fechaLima.format(new Date(valor));
  if (campo === 'tasa_igv') return `${valor}%`;
  if (typeof valor === 'boolean') return valor ? 'Sí' : 'No';
  return String(valor);
}

const simplificar = (texto) => texto.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLocaleLowerCase('es-PE');

function mostrarTablas() {
  const ficha = esquema[tablaDatos];
  id('tabla-elegida').value = tablaDatos;
  id('tabla-titulo').textContent = ficha.titulo;
  id('tabla-texto').textContent = filtroClave ? `Filtro de relación por ${filtroClave.campo}` : ficha.texto;
  const palabras = simplificar(id('buscar').value.trim()).split(/\s+/).filter(Boolean);
  const filas = base.tablas[tablaDatos].filter((registro) => {
    if (filtroClave) return registro[filtroClave.campo] === filtroClave.valor;
    const texto = simplificar(ficha.columnas.map((campo) => mostrarValor(campo, registro[campo])).join(' '));
    return palabras.every((palabra) => texto.includes(palabra));
  });
  const porPagina = 10;
  const paginas = Math.max(1, Math.ceil(filas.length / porPagina));
  pagina = Math.min(pagina, paginas - 1);
  const columnas = ficha.columnas.map((campo) => ({ texto: campo, clase: camposMoneda.has(campo) ? 'codigo numero' : 'codigo' }));
  const datos = filas.slice(pagina * porPagina, (pagina + 1) * porPagina).map((fila) => ficha.columnas.map((campo) => {
    const valor = fila[campo];
    const texto = mostrarValor(campo, valor);
    const destino = referencias[campo];
    if (destino && destino !== tablaDatos && valor !== null && valor !== undefined) {
      const enlace = boton(texto, () => elegirTabla(destino, { campo, valor }), null, 'enlace-boton codigo');
      enlace.setAttribute('aria-label', `Ver ${esquema[destino].titulo} con ${campo} ${texto}`);
      return enlace;
    }
    return texto;
  }));
  id('registros').replaceChildren(registros(columnas, datos, ficha.titulo));
  id('pagina-ant').disabled = pagina === 0;
  id('pagina-sig').disabled = pagina === paginas - 1;
  id('tabla-pagina').textContent = `${filas.length} ${filas.length === 1 ? 'fila' : 'filas'} · Página ${pagina + 1} de ${paginas}`;
}

const nombreProducto = (producto) => base.tablas.productos.find((fila) => fila.id_producto === producto).nombre;
const etiquetaPedido = (p) => `#${p.id_pedido} · ${p.tipo_pedido} · ${p.estado}`;
const pedidoVigente = () => base.tablas.pedidos.find((fila) => fila.id_pedido === pedidoActivo);

function selectorPedidos(control) {
  opciones(control, [...base.tablas.pedidos].reverse(), (p) => p.id_pedido, etiquetaPedido, pedidoActivo);
}

function formularioCampo(texto, control, nombre) {
  control.name = nombre;
  control.required = true;
  const etiqueta = nodo('label', texto);
  etiqueta.append(control);
  return etiqueta;
}

function dialogo(titulo, texto, confirmar, campos, accion) {
  accionDialogo = accion;
  id('dialogo-titulo').textContent = titulo;
  id('dialogo-info').textContent = texto;
  id('confirmar-dialogo').textContent = confirmar;
  id('dialogo-campos').replaceChildren(...campos);
  id('dialogo').showModal();
}

function confirmarBorrado(titulo, texto, accion) {
  dialogo(titulo, texto, 'Confirmar borrado', [], () => accion);
  id('cancelar-dialogo').focus();
}

function moverLinea(linea) {
  const disponibles = base.tablas.pedidos.filter((p) => p.id_pedido !== pedidoActivo && p.estado !== 'Anulado' && !documentoDe(base.tablas, p.id_pedido));
  if (!disponibles.length) {
    mostrarAviso('Crea otro pedido sin comprobante para recibir la línea.', true);
    return;
  }
  const control = nodo('select');
  opciones(control, disponibles, (p) => p.id_pedido, etiquetaPedido);
  dialogo('Mover línea', `El producto ${nombreProducto(linea.id_producto)} conserva la cantidad y su precio al cambiar de pedido.`,
    'Mover línea', [formularioCampo('Pedido de destino', control, 'destino')], (datos) => ({
      tipo: 'mover', id: linea.id_pedido, producto: linea.id_producto, destino: Number(datos.get('destino')),
    }));
}

function ajustarLinea(linea) {
  const control = nodo('input');
  Object.assign(control, { type: 'number', min: '1', max: '999', value: linea.cantidad });
  dialogo('Editar cantidad', `Modifica las unidades de ${nombreProducto(linea.id_producto)}.`, 'Guardar cantidad',
    [formularioCampo('Cantidad nueva', control, 'cantidad')], (datos) => ({
      tipo: 'cantidad', id: linea.id_pedido, producto: linea.id_producto, cantidad: Number(datos.get('cantidad')),
    }));
}

function mostrarPedido() {
  const pedido = pedidoVigente();
  const documento = documentoDe(base.tablas, pedidoActivo);
  const editable = !documento && pedido.estado !== 'Anulado';
  const lineas = lineasDe(base.tablas, pedidoActivo);
  const cliente = base.tablas.clientes.find((c) => c.id_cliente === pedido.id_cliente);
  selectorPedidos(id('pedido-editar'));
  id('agregar').hidden = !editable;
  id('borrar-pedido').disabled = Boolean(documento);
  opciones(id('estado'), documento ? estados.filter((estado) => estado !== 'Anulado') : estados, (x) => x, (x) => x, pedido.estado);

  const columnas = [{ texto: 'Producto' }, { texto: 'Cant.', clase: 'numero' }, { texto: 'Importe', clase: 'numero' }];
  if (editable) columnas.push({ texto: 'Acciones' });
  const filas = lineas.map((linea) => {
    const nombre = nombreProducto(linea.id_producto);
    const fila = [nombre, String(linea.cantidad), soles(linea.cantidad * linea.precio_unitario)];
    if (editable) {
      const acciones = nodo('div', '', 'acciones');
      acciones.append(boton('Editar', () => ajustarLinea(linea), 'edit'), boton('Mover', () => moverLinea(linea), 'swap_horiz'),
        boton('Borrar', () => confirmarBorrado('Borrar línea', `${nombre} se eliminará del pedido #${pedidoActivo} y su importe se recalculará.`,
          { tipo: 'borrar-linea', id: linea.id_pedido, producto: linea.id_producto }), 'delete'));
      fila.push(acciones);
    }
    return fila;
  });
  const pie = nodo('div', '', 'pie-tabla');
  const identificacion = nodo('div', '', 'estado-texto');
  if (cliente) identificacion.append(nodo('p', `${cliente.nombres} ${cliente.apellidos}`));
  identificacion.append(nodo('p', documento ? `Emitido · ${comprobanteTexto(documento)}` : `Estado · ${pedido.estado}`));
  pie.append(identificacion, nodo('strong', soles(totalLineas(lineas)), 'numero'));
  id('pedido-lineas').replaceChildren(registros(columnas, filas, 'Líneas del pedido'), pie);

  const lista = nodo('ul', '', 'cambios');
  for (const evento of base.cambios) {
    const fila = nodo('li');
    fila.append(nodo('code', evento.tabla, 'codigo'), nodo('span', evento.mensaje));
    lista.append(fila);
  }
  id('aprendizaje').replaceChildren(nodo('h2', 'Qué cambia'),
    nodo('p', 'Los traslados cambian el pedido de la línea. El comprobante emitido conserva su detalle.', 'apagado'),
    base.cambios.length ? lista : nodo('p', 'Los cambios de práctica aparecerán aquí.', 'apagado'));
  if (anterior) id('aprendizaje').append(boton('Deshacer último cambio', deshacer, 'undo'));
  id('aprendizaje').append(boton('Ver tabla de detalle', () => elegirTabla('detalle_pedido', { campo: 'id_pedido', valor: pedidoActivo }), 'table_view'));
}

function mostrarPartes() {
  const campo = id('efectivo');
  const { saldo, comprobante } = conciliar(base.tablas, pedidoActivo);
  campo.max = (saldo / 100).toFixed(2);
  campo.disabled = !comprobante || saldo === 0;
  id('registrar-pago').disabled = campo.disabled || !campo.validity.valid;
  let texto = comprobante ? soles(0) : 'Por emitir';
  if (!campo.disabled) {
    texto = campo.validity.valid ? soles(dividirPago(saldo, Math.round(Number(campo.value) * 100)).yape) : 'Importe fuera del saldo';
  }
  id('yape').textContent = texto;
}

function mostrarCobros() {
  const pedido = pedidoVigente();
  const { comprobante, pagos, saldo, base: importeBase, igv, total, cobrado } = conciliar(base.tablas, pedidoActivo);
  selectorPedidos(id('pedido-cobrar'));
  const detalle = nodo('dl', '', 'saldo-grid');
  const importes = [['Total de la venta', total], ['Total abonado', cobrado], ['Saldo pendiente', saldo]];
  if (comprobante) importes.splice(0, 0, ['Base imponible', importeBase], ['IGV del ejercicio', igv]);
  for (const [concepto, valor] of importes) {
    const fila = nodo('div');
    fila.append(nodo('dt', concepto), nodo('dd', soles(valor)));
    detalle.append(fila);
  }
  const titulo = comprobante ? comprobanteTexto(comprobante) : 'Por emitir';
  const contenedor = id('resumen-cobro');
  contenedor.replaceChildren(nodo('h3', titulo, 'cobro-titulo codigo'), detalle);
  if (pagos.length) {
    const filas = pagos.map((p) => [base.tablas.metodos_pago.find((m) => m.id_metodo_pago === p.id_metodo_pago).nombre, soles(p.monto)]);
    contenedor.append(registros([{ texto: 'Medio de pago' }, { texto: 'Abono', clase: 'numero' }], filas, 'Abonos registrados'));
  }
  id('emitir-zona').hidden = Boolean(comprobante);
  id('emitir').disabled = pedido.estado === 'Anulado' || lineasDe(base.tablas, pedidoActivo).length === 0;
  id('efectivo').value = '0.00';
  mostrarPartes();
}

function ejecutar(accion) {
  try {
    const cambio = operar(base, accion);
    anterior = { base, pedidoActivo };
    base = cambio.base;
    pedidoActivo = cambio.elegido;
    mostrarPantalla();
    guardar(cambio.mensaje);
  } catch (error) {
    mostrarAviso(error.message, true);
  }
}

function deshacer() {
  ({ base, pedidoActivo } = anterior);
  anterior = null;
  mostrarPantalla();
  guardar('Se deshizo el último cambio de práctica.');
}

document.querySelectorAll('[data-paso]').forEach((control, indice) => {
  control.addEventListener('click', () => ir(indice));
  control.addEventListener('keydown', (evento) => {
    if (!['ArrowLeft', 'ArrowRight'].includes(evento.key)) return;
    evento.preventDefault();
    ir(indice + (evento.key === 'ArrowLeft' ? -1 : 1));
  });
});
id('anterior').addEventListener('click', () => ir(paso - 1));
id('siguiente').addEventListener('click', () => ir(paso + 1));
id('tabla-elegida').addEventListener('change', (evento) => elegirTabla(evento.target.value));
id('buscar').addEventListener('input', () => { filtroClave = null; pagina = 0; mostrarTablas(); });
id('pagina-ant').addEventListener('click', () => { pagina--; mostrarTablas(); });
id('pagina-sig').addEventListener('click', () => { pagina++; mostrarTablas(); });
for (const control of ['pedido-editar', 'pedido-cobrar']) {
  id(control).addEventListener('change', (evento) => { pedidoActivo = Number(evento.target.value); mostrarPantalla(); });
}
id('nuevo-pedido').addEventListener('click', () => {
  const cliente = nodo('select');
  const modalidad = nodo('select');
  opciones(cliente, base.tablas.clientes, (c) => c.id_cliente, (c) => `${c.nombres} ${c.apellidos}`);
  opciones(modalidad, modalidades, (x) => x, (x) => x);
  dialogo('Nuevo pedido', 'Crea una cabecera para empezar a agregar productos.', 'Crear pedido',
    [formularioCampo('Cliente', cliente, 'cliente'), formularioCampo('Modalidad', modalidad, 'modalidad')],
    (datos) => ({ tipo: 'crear', cliente: Number(datos.get('cliente')), modalidad: datos.get('modalidad') }));
});
id('agregar').addEventListener('submit', (evento) => {
  evento.preventDefault();
  const datos = new FormData(evento.currentTarget);
  ejecutar({ tipo: 'agregar', id: pedidoActivo, producto: Number(datos.get('producto')), cantidad: Number(datos.get('cantidad')) });
});
id('cambiar-estado').addEventListener('submit', (evento) => {
  evento.preventDefault();
  ejecutar({ tipo: 'estado', id: pedidoActivo, estado: id('estado').value });
});
id('borrar-pedido').addEventListener('click', () => confirmarBorrado('Borrar pedido', `Se eliminará el pedido #${pedidoActivo} junto a todas sus líneas de práctica.`,
  { tipo: 'borrar-pedido', id: pedidoActivo }));
id('emitir').addEventListener('click', () => ejecutar({ tipo: 'emitir', id: pedidoActivo }));
id('pago').addEventListener('submit', (evento) => {
  evento.preventDefault();
  ejecutar({ tipo: 'abonar', id: pedidoActivo, efectivo: Math.round(Number(id('efectivo').value) * 100) });
});
id('efectivo').addEventListener('input', mostrarPartes);
id('dialogo-form').addEventListener('submit', (evento) => {
  evento.preventDefault();
  const accion = accionDialogo(new FormData(evento.currentTarget));
  id('dialogo').close();
  ejecutar(accion);
});
id('cancelar-dialogo').addEventListener('click', () => id('dialogo').close());

opciones(id('tabla-elegida'), Object.entries(esquema), ([tabla]) => tabla, ([tabla, ficha]) => `${ficha.titulo} (${tabla})`);
opciones(id('producto'), base.tablas.productos, (p) => p.id_producto, (p) => `${p.nombre} · ${soles(p.precio)}`);
crearMapa();
ir(Math.max(0, pasos.findIndex((etapa) => `#${etapa[3]}` === location.hash)), false);
