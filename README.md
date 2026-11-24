# Base de Datos · Red Pepper

Laboratorio de base de datos para la carta de Red Pepper, sus pedidos, comprobantes de práctica y pagos mixtos. El informe documenta la normalización, el catálogo, la instalación y los resultados.

- [Informe técnico](informe/informe_red_pepper.pdf)
- [Portal de demostración](https://nexlabsgroup.com/basededatos/)
- [Identidad y brief de diseño](BRANDING.md)
- [Diseño de las cuatro pantallas en Stitch](https://stitch.withgoogle.com/projects/14029965516649664019)

## 1. Base de datos

Ejecutar desde la raíz del repositorio en una base de pruebas con acceso para crear el esquema `salchipaperia`.

```sh
psql -X -v ON_ERROR_STOP=1 -f sql/01_modelo.sql
psql -X -v ON_ERROR_STOP=1 -f sql/02_datos_demo.sql
psql -X -v ON_ERROR_STOP=1 -f sql/03_consultas.sql
psql -X -v ON_ERROR_STOP=1 -f sql/04_pruebas.sql
psql -X -v ON_ERROR_STOP=1 -f sql/06_catalogo_y_ventas.sql
psql -X -v ON_ERROR_STOP=1 -f sql/07_validar_datagrip.sql
```

`psql` usa los parámetros de conexión del entorno. Para Supabase, tomar host, usuario y puerto de **Connect**, descargar su CA desde **Database Settings** y usar `sslmode=verify-full`. Los scripts `01` y `02` se aplican una vez por esquema. `04` restaura sus filas temporales en `ROLLBACK`. El script `06` añade la carta y las ventas de la serie `RP01`. Una segunda ejecución conserva las mismas 100 ventas. Los contadores de identidad pueden quedar con saltos.

### Resultados en PostgreSQL local y Supabase

| Muestra | Productos de carta | Ventas | Cobrado | Saldo |
| --- | ---: | ---: | ---: | ---: |
| `RP01`, del 24 de octubre al 22 de noviembre de 2026 | 38 | 100 | S/ 2,303.50 | S/ 0.00 |

La carta adjunta aporta los nombres y precios de venta. Los ocho rellenos de empanadas y las opciones de res y pollo cuentan como variantes individuales. El ejemplo usa precios de venta sin membresía. Se usa `NULL` para atributos que la carta no especifica, como volumen y envase. Los importes incluyen el IGV del ejercicio.

`web/datos.js` contiene la muestra reproducible. Ejecutar `node scripts/generar_muestra.mjs` desde la raíz para reconstruir la migración `06` a partir de esa fuente. Las 100 ventas se cargaron en el esquema `salchipaperia` de Supabase 17.12. Las pruebas de carga, repetición y compatibilidad se ejecutaron en PostgreSQL local 18.4.

### Ver el esquema en DataGrip

En **Database Explorer**, abrir **Data Sources and Drivers**, seleccionar la conexión Supabase de NexLabs y marcar `salchipaperia` en **Schemas**. Aplicar y sincronizar la conexión. La base es `postgres`. Abrir una consola de esa conexión y ejecutar `sql/07_validar_datagrip.sql` por bloques. La primera consulta confirma la conexión aunque la consola use `public` de esquema activo. Las demás usan nombres calificados y muestran las tablas, el catálogo, las ventas y el recorrido de un comprobante. El bloque de `RP01` debe devolver 100 ventas, S/ 2,303.50 y saldo S/ 0.00.

## 2. Portal en cPanel

El directorio público es `public_html/basededatos`. Publicar allí los archivos de `web/`, incluido `.htaccess`, y una copia de `informe/informe_red_pepper.pdf` con el nombre `informe-red-pepper.pdf`. Las rutas de navegación son `/basededatos/` y `/basededatos/informe`. La interfaz puede abrirse en un servidor estático local desde la carpeta `web`. La ruta del informe utiliza el rewrite de Apache o LiteSpeed.

El portal carga la muestra como parte de su aplicación estática. Los borradores de práctica 101 y 102 permiten ensayar operaciones inmediatamente. Los cambios se guardan en el almacenamiento local del navegador. Para volver a la muestra inicial se puede usar un navegador o perfil nuevo. Supabase conserva su carga independiente en PostgreSQL.

El recorrido incluye cuatro pasos. **Modelo** explica las relaciones de las 13 tablas. **Explorar tablas** permite buscar y seguir claves foráneas. **Editar pedidos** permite crear comandas, agregar o ajustar líneas, moverlas entre pedidos, cambiar su estado y borrarlas. **Comprobantes y pagos** permite emitir un comprobante y conciliar con efectivo y Yape en céntimos. Los comprobantes emitidos protegen sus líneas. El script `05` corresponde a una API opcional de la versión anterior y la publicación actual funciona con los datos de práctica incluidos.

## 3. Archivos y verificación

| Ruta | Contenido |
| --- | --- |
| `sql/` | Modelo, datos ficticios, vistas, consultas y pruebas |
| `BRANDING.md` | Tokens de color, tipografía, iconos y brief usado en Stitch |
| `diseno/stitch/` | Exportaciones de referencia de las cuatro pantallas de Stitch |
| `web/` | Portal, operaciones del laboratorio y datos de práctica |
| `scripts/generar_muestra.mjs` | Generador reproducible de la carga PostgreSQL |
| `informe/` | PDF y fuente editable LaTeX |

Para regenerar el informe, ejecutar `xelatex -halt-on-error informe/informe_red_pepper.tex` con Calibri y Consolas disponibles. Las pantallas de Stitch derivan de `BRANDING.md`. El HTML publicado adopta su navegación, retícula y componentes, con etiquetas y datos vinculados a las operaciones del laboratorio.
