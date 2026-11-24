# Red Pepper | Identidad del laboratorio

Red Pepper es un local peruano de comida rápida. Su carta reúne salchipapas, hamburguesas, sánguches, empanadas y bebidas. El laboratorio usa su catálogo para enseñar cómo se registra, recorre y concilia una venta. El nombre visible es **Red Pepper** y el descriptor es **Laboratorio de base de datos**.

## Color

| Rol | Token | Valor |
| --- | --- | --- |
| Marca, acciones primarias y selección | `brand` | `#1648FF` |
| Texto dentro del azul | `on-brand` | `#FFFFFF` |
| Texto principal | `ink` | `#131B32` |
| Texto secundario | `muted` | `#525E77` |
| Superficie | `paper` | `#FFFFFF` |
| Fondo de página | `canvas` | `#F5F7FC` |
| Borde | `line` | `#D9E0F0` |
| Fondo de selección | `tint` | `#EEF2FF` |

El azul eléctrico es el único acento cromático. Usar bloques sólidos, bordes finos y espacio en blanco. El texto, el icono y el estado de foco deben comunicar los cambios sin depender del color. Para acciones destructivas usar el icono Papelera, el texto de la acción y una confirmación con el registro a eliminar.

## Tipografía

- **Manrope** 700 y 800 para títulos. **Inter** 400, 500 y 600 para texto, navegación y controles. **JetBrains Mono** 500 para claves, nombres SQL y código. Usar alternativas del sistema cuando la fuente no esté disponible.
- Título principal 42 px en escritorio y 32 px en móvil, ajustable al ancho. Subtítulos 22 a 26 px. Texto base 16 px. Etiquetas y columnas de datos 14 px como mínimo. Usar números tabulares en importes y cantidades.
- Alinear el texto de las tablas a la izquierda y los importes a la derecha. Formato monetario `S/ 8.00`. Mostrar los nombres SQL con guiones bajos y la terminología de la carta en español peruano.

## Iconos, superficies y contenido

- Iconos lineales de 20 px con trazo consistente y texto visible para acciones. Utilizar base de datos, relaciones, tabla, edición, transferencia, papelera y recibo. El símbolo de Red Pepper en el portal es el icono del laboratorio, acompañado de su nombre.
- Superficies blancas, borde gris azulado y radio medio de 12 px. Evitar gradientes, sombras pesadas, fotografías genéricas, logotipos inventados del restaurante y elementos que aparenten telemetría.
- La carta es la referencia para nombres y precios. Mantener las variantes cuando están explícitas y marcar como desconocidos los atributos ausentes. Las ventas, clientes y referencias de pago de ejercicio son ficticios.

## Brief para Stitch

Diseñar un portal tipo presentación interactiva con navegación lateral en escritorio y navegación compacta en móvil. Crear cuatro pasos: **Modelo**, **Explorar tablas**, **Editar pedidos** y **Comprobantes y pagos**. El paso activo usa el azul de marca. El área principal presenta el título, una frase que indica qué hacer y una superficie de trabajo. El contenido real de datos debe pasar por los mismos componentes en todos los pasos.

- **Modelo** muestra el recorrido Clientes → Pedidos → Detalle → Productos y el de Pedidos → Comprobantes → Pagos. Las entidades tienen un inspector con su clave primaria, foráneas y cardinalidad.
- **Explorar tablas** muestra el selector de las 13 tablas, búsqueda, filas con claves e importes, y paginación.
- **Editar pedidos** incluye un selector, líneas, cantidades y acciones para agregar, mover, cambiar estado o borrar. Los avisos explican qué relaciones cambian.
- **Comprobantes y pagos** muestra la emisión de prueba, total, abonos y saldo. El simulador usa efectivo y Yape y mantiene visible el contexto ficticio.

Cada control interactivo tiene un nombre legible, foco visible y un resultado comprensible. Usar una columna en móvil y conservar las tablas desplazables dentro de su contenedor cuando las columnas no entren. Mantener accesos a **Anterior**, **Siguiente** e **Informe técnico**. El portal utiliza la ruta `/basededatos/`.
