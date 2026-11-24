# Base de Datos · Red Pepper

Laboratorio de base de datos para la carta de Red Pepper y el recorrido de sus pedidos. El informe documenta la normalización, el catálogo, la instalación y los resultados.

- [Tablas y relaciones](#tablas-y-relaciones)
- [Guía paso a paso y comandos](#paso-a-paso)
- [Informe técnico](informe/informe_red_pepper.pdf)
- [Excel de los 100 pedidos de muestra](outputs/red-pepper/ventas_red_pepper.xlsx)
- [Portal de demostración](https://nexlabsgroup.com/basededatos/)
- [Identidad y brief de diseño](BRANDING.md)
- [Diseño original del laboratorio en Stitch](https://stitch.withgoogle.com/projects/14029965516649664019)

## Tablas y relaciones

El [modelo entidad–relación](MODELO_ENTIDAD_RELACION.md) reúne el diagrama de las ocho tablas, las claves y las cardinalidades. También puedes abrir el [modelo interactivo del portal](https://nexlabsgroup.com/basededatos/#modelo).

## Paso a paso

### 1. Clonar el repositorio

El repositorio es privado. Usa una cuenta de GitHub con acceso y ejecuta estos comandos en PowerShell o en una terminal con Git.

```sh
git clone https://github.com/Quetzalq4321q/base-de-datos.git
cd base-de-datos
```

Si ya lo clonaste, ejecuta este comando dentro del proyecto para traer los cambios.

```sh
git pull --ff-only
```

### 2. Abrir el portal en tu equipo

Desde la carpeta del proyecto, inicia el servidor con Python 3.

```sh
python -m http.server 8000 --bind 127.0.0.1 --directory web
```

En Windows también puedes usar `py -3` en lugar de `python`. Abre la [guía local](http://127.0.0.1:8000/) o el [modelo entidad–relación local](http://127.0.0.1:8000/#modelo). Para detener el servidor pulsa Ctrl+C.

### 3. Crear una base local de prueba

Con PostgreSQL iniciado y las herramientas `createdb` y `psql` instaladas, crea una base nueva. Usa tu usuario de PostgreSQL si es distinto de `postgres`.

```sh
createdb -h localhost -U postgres red_pepper_prueba
psql -X -h localhost -U postgres -d red_pepper_prueba -v ON_ERROR_STOP=1
```

Dentro de `psql`, ejecuta los siguientes comandos desde la carpeta del proyecto. Los primeros scripts preparan la muestra y el `10` deja el esquema vigente.

```text
\encoding UTF8
\i sql/01_modelo.sql
\i sql/02_datos_demo.sql
\i sql/03_consultas.sql
\i sql/04_pruebas.sql
\i sql/06_catalogo_y_ventas.sql
\i sql/08_nombres_ficticios.sql
\i sql/09_presentaciones_y_celulares.sql
\i sql/10_simplificar_pedidos.sql
\i sql/07_validar_datagrip.sql
```

Para actualizar una copia histórica que ya tiene las cargas hasta `09`, respalda `salchipaperia` y ejecuta solo `10` antes de consultar con `07`.

### 4. Consultar tablas y relaciones

En `psql`, `\dt` lista las tablas y `\d` muestra las columnas y claves de una tabla.

```text
\dt salchipaperia.*
\d salchipaperia.detalle_pedido
\q
```

En **DataGrip**, abre la conexión a Supabase, selecciona el esquema `salchipaperia` y sincronízalo. Ejecuta en la consola SQL la consulta de inventario.

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'salchipaperia' AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

Ejecuta por bloques [07_validar_datagrip.sql](sql/07_validar_datagrip.sql) para ver el catálogo, las líneas y el total de los pedidos. La base de Supabase ya contiene el esquema vigente. Para configurar una conexión nueva, toma el host, el usuario y el puerto de **Connect** y usa la CA descargada de **Database Settings** con `sslmode=verify-full`.

## Resultados en PostgreSQL local y Supabase

| Muestra | Productos de carta | Pedidos | Líneas | Importe |
| --- | ---: | ---: | ---: | ---: |
| Del 24 de octubre al 22 de noviembre de 2026 | 38 | 100 | 186 | S/ 2,303.50 |

El esquema tiene ocho tablas y cero vistas. Conserva `clientes`, `categorias`, `productos`, `pedidos`, `detalle_pedido`, `snacks` y `bebidas`, y añade `hamburguesas` con las ocho variantes de res y pollo. Cada producto tiene un solo subtipo. La columna `tipo_bebida` acepta `Gaseosa` o `Chicha`. Agua y maracuyá conservan un valor `NULL` en esa columna.

La carta aporta los precios de venta sin membresía. El total se calcula multiplicando la cantidad por el precio aplicado a cada línea. `web/datos.js` contiene la muestra reproducible y `scripts/muestra_historica.mjs` completa los datos requeridos por las cargas anteriores. Ejecutar `node scripts/generar_muestra.mjs` desde la raíz para regenerar las cargas históricas `06`, `08` y `09`.

El Excel enlaza las hojas Ventas y Detalle por su código de muestra y la hoja Clientes por el identificador interno de cada cliente. Sus códigos de pedido identifican filas de la muestra de Excel. DataGrip usa la identidad de cada pedido de PostgreSQL.

## Portal en cPanel

El directorio público es `public_html/basededatos`. Publicar allí los archivos de `web/`, incluido `.htaccess`, y una copia de `informe/informe_red_pepper.pdf` con el nombre `informe-red-pepper.pdf`. Las rutas de navegación son `/basededatos/` y `/basededatos/informe`. La interfaz puede abrirse en un servidor estático local desde la carpeta `web`. La ruta del informe utiliza el rewrite de Apache o LiteSpeed.

El portal carga la muestra como parte de su aplicación estática. Los borradores de práctica 101 y 102 permiten ensayar operaciones inmediatamente. Los cambios se guardan en el almacenamiento local del navegador. Para volver a la muestra inicial se puede usar un navegador o perfil nuevo. Supabase conserva su carga independiente en PostgreSQL.

La cabecera permite alternar entre tema claro y oscuro. El portal sigue la preferencia del sistema hasta elegir un modo y guarda la elección en el navegador. La pantalla de carga aparece mientras se prepara el laboratorio. El movimiento reducido del sistema desactiva el pulso y las transiciones.

El recorrido abre en **Guía de ventas**. Las tarjetas muestran el cliente, el pedido, el detalle y su total. Para practicar, pulsa **Nuevo pedido**, elige cliente y modalidad, agrega un producto y edita su cantidad. El panel **Qué cambió en los datos** compara las filas antes y después de la última operación. Puedes mover una línea, borrarla o deshacer el último cambio durante la sesión.

**Modelo entidad–relación** muestra un mapa interactivo de las ocho tablas y sus siete conexiones. Selecciona una entidad para resaltar sus relaciones y consultar sus claves. **Explorar tablas** permite buscar y seguir claves foráneas. **Editar pedidos** permite cambiar los datos de una comanda, sus líneas y su estado. **Resumen del pedido** muestra las unidades y el total. En `diseno/stitch/` se conserva el diseño histórico.

## Archivos y verificación

| Ruta | Contenido |
| --- | --- |
| `MODELO_ENTIDAD_RELACION.md` | Diagrama y reglas de las ocho entidades |
| `sql/` | Esquema, migraciones, datos ficticios, consultas y pruebas |
| `BRANDING.md` | Tokens de color, tipografía, iconos y brief usado en Stitch |
| `diseno/stitch/` | Exportaciones de las pantallas y de los dos temas de Stitch |
| `web/` | Portal, operaciones del laboratorio y datos de práctica |
| `scripts/generar_muestra.mjs` | Generador reproducible de la carga PostgreSQL |
| `informe/` | PDF y fuente editable LaTeX |

Para regenerar el informe, ejecutar `xelatex -halt-on-error informe/informe_red_pepper.tex` con Calibri y Consolas disponibles. Las pantallas de Stitch derivan de `BRANDING.md`. El HTML publicado adopta su navegación, retícula y componentes, con etiquetas y datos vinculados a las operaciones del laboratorio.
