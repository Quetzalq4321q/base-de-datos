# Modelo entidad–relación de Red Pepper

El esquema `salchipaperia` tiene ocho tablas. **PK** identifica la clave primaria, **FK** marca una clave foránea y **UK** indica una restricción de unicidad.

```mermaid
erDiagram
    clientes ||..o{ pedidos : realiza
    pedidos ||--o{ detalle_pedido : contiene
    productos ||--o{ detalle_pedido : aparece_en
    categorias ||..o{ productos : agrupa
    productos ||--o| snacks : clasifica_como
    productos ||--o| bebidas : clasifica_como
    productos ||--o| hamburguesas : clasifica_como

    clientes {
        bigint id_cliente PK
        varchar nombres
        varchar apellidos
    }
    pedidos {
        bigint id_pedido PK
        bigint id_cliente FK
        timestamptz fecha_pedido
        text tipo_pedido
        text estado
    }
    detalle_pedido {
        bigint id_pedido PK, FK
        bigint id_producto PK, FK
        integer cantidad
        numeric precio_unitario
    }
    productos {
        bigint id_producto PK
        varchar id_categoria FK
        varchar nombre
        numeric precio
        boolean disponible
    }
    categorias {
        varchar id_categoria PK
        varchar nombre UK
        varchar descripcion
    }
    snacks {
        bigint id_producto PK, FK
        varchar porcion
        boolean incluye_cremas
    }
    bebidas {
        bigint id_producto PK, FK
        text tipo_bebida
        varchar envase
    }
    hamburguesas {
        bigint id_producto PK, FK
        text tipo_carne
        boolean incluye_papas
    }
```

- Cada pedido corresponde a un cliente y puede tener varias líneas. `detalle_pedido` conecta pedidos y productos. Su clave compuesta permite una fila por producto en cada pedido.
- Cada producto pertenece a una categoría. La combinación `id_categoria` y `nombre` es única en `productos`.
- Cada producto tiene exactamente un subtipo. Las tres relaciones opcionales del diagrama son excluyentes entre `snacks`, `bebidas` y `hamburguesas`.

Puedes seleccionar una entidad para ver sus claves y abrir sus filas en el [modelo interactivo](https://nexlabsgroup.com/basededatos/#modelo). El archivo [de consultas para DataGrip](sql/07_validar_datagrip.sql) incluye el inventario de tablas y ejemplos de detalle y totales.
