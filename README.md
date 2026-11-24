# Red Pepper · Base de datos

Laboratorio de pedidos para la carta de Red Pepper. El proyecto reúne un esquema PostgreSQL, una muestra de ventas ficticias y un portal para consultar tablas, recorrer sus relaciones y practicar con los datos.

## Documentación

| Recurso | Contenido |
| --- | --- |
| [Modelo entidad–relación](MODELO_ENTIDAD_RELACION.md) | Diagrama de las ocho tablas, claves y cardinalidades. |
| [Informe técnico](informe/informe_red_pepper.pdf) | Normalización, integridad y verificación del esquema. |
| [Libro de ventas](outputs/red-pepper/ventas_red_pepper.xlsx) | Resumen, pedidos, líneas de venta, clientes y catálogo. |
| [Consultas para DataGrip](sql/07_validar_datagrip.sql) | Inventario de tablas, clasificación del catálogo, detalle y totales de pedidos. |
| [Identidad visual](BRANDING.md) | Colores, tipografía, navegación y comportamiento del portal. |

## Paso a paso

### 1. Descargar el proyecto

Necesitas Git y acceso al repositorio privado. Ejecuta estos comandos en una terminal.

```sh
git clone https://github.com/Quetzalq4321q/base-de-datos.git
cd base-de-datos
```

Si ya tienes una copia, actualízala desde su carpeta.

```sh
git pull --ff-only
```

### 2. Abrir el portal en tu equipo

Con Python 3 instalado, ejecuta este comando desde la raíz del proyecto.

```sh
python -m http.server 8000 --bind 127.0.0.1 --directory web
```

En Windows puedes sustituir `python` por `py -3`. Abre la [guía de ventas](http://127.0.0.1:8000/) o el [modelo interactivo](http://127.0.0.1:8000/#modelo). Pulsa **Ctrl+C** en la terminal para detener el servidor.

El portal incluye su propia muestra. Puedes crear un pedido, editar su cliente y modalidad, añadir o mover líneas y revisar qué cambió. El **Resumen del pedido** calcula el total con el precio aplicado a cada línea. Las operaciones de práctica se guardan en el navegador.

### 3. Cargar la muestra en PostgreSQL local

Inicia PostgreSQL y comprueba que tengas `createdb` y `psql`. Estos comandos crean una base de prueba vacía. Sustituye `postgres` por tu usuario si corresponde.

```sh
createdb -h localhost -U postgres red_pepper_prueba
psql -X -h localhost -U postgres -d red_pepper_prueba -v ON_ERROR_STOP=1
```

Ejecuta los siguientes comandos dentro de `psql`, desde una sesión iniciada en la raíz del repositorio. Los scripts anteriores a `10` preparan la carga histórica y `10` aplica el esquema vigente.

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

Si tu base ya tiene la carga hasta `09`, respalda el esquema `salchipaperia` y aplica la [migración `10`](sql/10_simplificar_pedidos.sql) antes de ejecutar las consultas.

### 4. Consultar las tablas

En la consola de `psql`, `\dt` lista las tablas del esquema, `\d` muestra las columnas y claves de una tabla, y `\q` cierra la sesión.

```text
\dt salchipaperia.*
\d salchipaperia.detalle_pedido
\q
```

Para consultar Supabase desde **DataGrip**, crea o abre una conexión PostgreSQL. Usa el host, puerto y usuario del panel **Connect**, la base `postgres` y el modo `verify-full` con el certificado CA del proyecto. Selecciona el esquema `salchipaperia` en **Schemas** y sincroniza el explorador.

Ejecuta este bloque en una consola SQL para verificar el inventario.

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'salchipaperia'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

El resultado esperado es **8 tablas**. Los bloques de [07_validar_datagrip.sql](sql/07_validar_datagrip.sql) también permiten consultar el catálogo, calcular los importes y ver las líneas de un pedido.

## Datos de referencia

La muestra cubre del **24 de octubre al 22 de noviembre de 2026**, hora de Lima. Contiene **100 pedidos**, **186 líneas** y **38 productos de la carta**. El importe de la muestra suma **S/ 2,303.50**. Los dos pedidos de la carga inicial de PostgreSQL quedan fuera de ese periodo.

El total de un pedido se calcula como la suma de `cantidad × precio_unitario` de sus líneas. El precio unitario se conserva en el detalle, mientras que `productos.precio` representa el precio vigente. Los códigos de pedido del Excel identifican filas del libro. En DataGrip, las consultas usan `id_pedido`.

## Estructura y publicación

| Ruta | Contenido |
| --- | --- |
| [`web/`](web/) | Portal, mapa adaptable y datos de práctica. |
| [`sql/`](sql/) | Esquema PostgreSQL, migraciones, carga y consultas. |
| [`informe/`](informe/) | Informe en PDF y fuente LaTeX. |
| [`outputs/red-pepper/`](outputs/red-pepper/) | Libro de ventas de la muestra. |

En cPanel, publica el contenido de `web/`, incluido `.htaccess`, en `public_html/basededatos`. Copia el PDF de `informe/` como `informe-red-pepper.pdf` en esa carpeta. La ruta `/basededatos/informe` usa las reglas de Apache o LiteSpeed. [Portal publicado](https://nexlabsgroup.com/basededatos/)

Para regenerar las cargas históricas `06`, `08` y `09`, usa Node.js desde la raíz del proyecto.

```sh
node scripts/generar_muestra.mjs
```

Para compilar el informe, usa XeLaTeX con Calibri y Consolas instaladas.

```sh
xelatex -halt-on-error informe/informe_red_pepper.tex
```
