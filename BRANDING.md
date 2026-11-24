# Red Pepper | Identidad del laboratorio

Red Pepper es un local peruano de comida rápida. Su carta reúne salchipapas, hamburguesas, sánguches, empanadas y bebidas. El laboratorio usa su catálogo para enseñar cómo se registra y calcula el importe de un pedido. El nombre visible es **Red Pepper** y el descriptor es **Laboratorio de base de datos**.

## Color

| Rol | Token | Modo claro | Modo oscuro |
| --- | --- | --- | --- |
| Marca y acciones primarias | `brand` | `#1648FF` | `#1648FF` |
| Texto dentro del azul | `on-brand` | `#FFFFFF` | `#FFFFFF` |
| Enlaces, íconos en superficies y foco | `accent` | `#1648FF` | `#A5B8FF` |
| Texto principal | `ink` | `#131B32` | `#F0F3FF` |
| Texto secundario | `muted` | `#525E77` | `#B3BED6` |
| Superficie | `paper` | `#FFFFFF` | `#192338` |
| Fondo de página | `canvas` | `#F5F7FC` | `#101827` |
| Borde | `line` | `#D9E0F0` | `#394866` |
| Fondo de selección | `tint` | `#EEF2FF` | `#25345F` |
| Superficie de carga | `placeholder` | `#E3E9F7` | `#30405F` |

El azul eléctrico es el único acento cromático. Usar bloques sólidos, bordes finos y espacio en blanco. El texto, el icono y el estado de foco deben comunicar los cambios sin depender del color. Para acciones destructivas usar el icono Papelera, el texto de la acción y una confirmación con el registro a eliminar.

## Tipografía

- **Manrope** 700 y 800 para títulos. **Inter** 400, 500 y 600 para texto, navegación y controles. **JetBrains Mono** 500 para claves, nombres SQL y código. Usar alternativas del sistema cuando la fuente no esté disponible.
- Título principal 42 px en escritorio y 32 px en móvil, ajustable al ancho. Subtítulos 22 a 26 px. Texto base 16 px. Etiquetas y columnas de datos 14 px como mínimo. Usar números tabulares en importes y cantidades.
- Alinear el texto de las tablas a la izquierda y los importes a la derecha. Formato monetario `S/ 8.00`. Mostrar los nombres SQL con guiones bajos y la terminología de la carta en español peruano.

## Iconos, superficies y contenido

- Iconos lineales de 20 px con trazo consistente y texto visible para acciones. Utilizar base de datos, relaciones, tabla, edición, transferencia, papelera y resumen. La cabecera y la pestaña usan una [bandeja de salchipapas blanca sobre azul eléctrico](web/icono-red-pepper.svg), acompañada del nombre Red Pepper en la cabecera.
- Superficies definidas por el tema, borde gris azulado y radio medio de 12 px. Evitar gradientes, sombras pesadas, fotografías genéricas, logotipos inventados del restaurante y elementos que aparenten telemetría.
- La carta es la referencia para nombres y precios. Mantener las variantes cuando están explícitas y marcar como desconocidos los atributos ausentes. Los pedidos y clientes del ejercicio son ficticios.

## Navegación y pantallas

El portal tiene cinco apartados y abre en **Guía de ventas**. La navegación es lateral en escritorio y compacta en móvil. El apartado activo se distingue por el fondo azul. Cada pantalla presenta su título, una instrucción breve y los controles necesarios para trabajar con los datos.

- **Guía de ventas** muestra Cliente → Pedido → Detalle → Total con controles y enlaces a las filas del pedido activo. Un borde azul indica la acción siguiente. El panel de cambios presenta el campo y sus valores antes y después.
- **Modelo entidad–relación** presenta ocho tarjetas conectadas en horizontal o en vertical, según el ancho disponible. Las líneas indican la cardinalidad y se resaltan al seleccionar una entidad. El inspector muestra los campos, las marcas PK y FK y la clave de cada relación. En pantallas estrechas, **Volver al mapa** lleva a la tarjeta seleccionada.
- **Explorar tablas** muestra el selector de las ocho tablas, búsqueda, filas con claves e importes, y paginación.
- **Editar pedidos** incluye un selector, líneas, cantidades y acciones para agregar, mover, cambiar estado o borrar. Los avisos explican qué relaciones cambian.
- **Resumen del pedido** muestra las líneas, las unidades y el total calculado desde el detalle.

Cada control interactivo tiene un nombre legible, foco visible y un resultado comprensible. Usar una columna en móvil y conservar las tablas desplazables dentro de su contenedor cuando las columnas no entren. Mantener accesos a **Anterior**, **Siguiente** e **Informe técnico**. El portal utiliza la ruta `/basededatos/`.

## Tema y movimiento

- Mantener idéntica jerarquía, geometría y navegación en ambos modos. Mostrar en la cabecera el icono de sol o luna y nombrar el modo que activa el control. Respetar la preferencia del sistema en la primera visita y recordar la elección manual en el navegador.
- Mientras arranca el laboratorio, usar esqueletos que mantengan el espacio del encabezado, los indicadores y los paneles. El blanco o azul oscuro más suave marca las zonas de carga. Terminar la animación en cuanto el contenido esté listo y dar una opción de recarga si falla el inicio.
- Usar una entrada breve de opacidad y desplazamiento para cada diapositiva y el diálogo. Mantener la lectura durante el cambio de tema. Con `prefers-reduced-motion`, mostrar directamente el estado final y dejar los esqueletos estáticos.
