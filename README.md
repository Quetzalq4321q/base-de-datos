# Base de Datos · Red Pepper

Piloto de PostgreSQL para pedidos de salchipapería, catálogo especializado, comprobantes de demostración y pagos mixtos. El informe desarrolla el diagnóstico, las formas normales, el modelo lógico, la instalación y los resultados.

- [Informe técnico](informe/informe_red_pepper.pdf)
- [Portal de demostración](https://nexlabsgroup.com/basededatos/)
- [Diseño original en Stitch](https://stitch.withgoogle.com/projects/14029965516649664019)

## 1. Base de datos

Ejecutar desde la raíz del repositorio en una base de pruebas con acceso para crear el esquema `salchipaperia`.

```sh
psql -X -v ON_ERROR_STOP=1 -f sql/01_modelo.sql
psql -X -v ON_ERROR_STOP=1 -f sql/02_datos_demo.sql
psql -X -v ON_ERROR_STOP=1 -f sql/03_consultas.sql
psql -X -v ON_ERROR_STOP=1 -f sql/04_pruebas.sql
```

`psql` usa los parámetros de conexión del entorno. Para Supabase, tomar host, usuario y puerto de **Connect**, descargar su CA desde **Database Settings** y usar `sslmode=verify-full`. El pooler de sesión por IPv4 admite esta instalación. El esquema se creó en Supabase 17.12 y la misma batería pasó en PostgreSQL 18.4 local. Los scripts `01` y `02` se aplican una vez por esquema. `04` restaura las filas temporales en `ROLLBACK`. Los contadores de identidad pueden quedar con saltos.

### Resultados

| Boleta ficticia | Base | IGV del ejercicio | Total | Abonos | Saldo |
| --- | ---: | ---: | ---: | --- | ---: |
| B001-0000001 | S/ 17.80 | S/ 3.20 | S/ 21.00 | S/ 10.00 efectivo + S/ 11.00 Yape | S/ 0.00 |
| B001-0000002 | S/ 20.34 | S/ 3.66 | S/ 24.00 | S/ 24.00 Plin | S/ 0.00 |

Los importes comerciales incluyen el IGV de ejemplo. Los abonos y las boletas son datos ficticios para el curso.

## 2. Portal en cPanel

El directorio público es `public_html/basededatos`. Publicar allí los archivos de `web/`, incluido `.htaccess`, y una copia de `informe/informe_red_pepper.pdf` con el nombre `informe-red-pepper.pdf`. Las rutas de navegación son `/basededatos/` y `/basededatos/informe`. La interfaz puede abrirse en un servidor estático local desde la carpeta `web`. La ruta del informe utiliza el rewrite de Apache o LiteSpeed.

El portal trabaja con dos pedidos ficticios de ejemplo mientras `conexion` sea `null`. La simulación calcula la diferencia entre el efectivo y el total en céntimos. Se pueden cambiar el comprobante y el importe de efectivo desde el navegador.

`sql/05_consulta_web.sql` es la migración opcional para mostrar esos dos pedidos ficticios desde Supabase. Su aplicación habilita el resumen para visitantes. El resultado contiene productos, importes y métodos de pago. Los nombres de clientes, documentos y referencias de operación quedan en el esquema privado. La migración comprueba que el rol `anon` puede consultar el resumen y carece de acceso directo a las tablas de pedidos, clientes y pagos. Tras aplicarla, configurar `url` y `publishableKey` en `web/conexion.js`. El sitio hace una consulta inicial, reutiliza la respuesta durante dos minutos en la sesión y permite actualizar por solicitud.

## 3. Archivos y verificación

| Ruta | Contenido |
| --- | --- |
| `sql/` | Modelo, datos ficticios, vistas, consultas y pruebas |
| `diseno/stitch.html` | Exportación del diseño de Stitch, conservada como referencia |
| `web/` | Diseño adaptado a la interfaz real, mostrando el origen de los datos |
| `informe/` | PDF y fuente editable LaTeX |

Para regenerar el informe, ejecutar `xelatex -halt-on-error informe/informe_red_pepper.tex` con Calibri y Consolas disponibles. El proyecto de Stitch es el origen del diseño del portal. El HTML publicado usa las secciones, la retícula, la escala y los colores del prototipo, y reemplaza las cifras estáticas del diseño por la muestra SQL o su ejemplo local.
