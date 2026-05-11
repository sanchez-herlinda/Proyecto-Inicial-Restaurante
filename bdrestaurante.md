## Actúa como un administrador de base de datos: proyecto restaurante, que entidades se necesitan para su gestion

Para la gestión de un restaurante necesitas las siguientes entidades principales:

<img width="801" height="644" alt="image" src="https://github.com/user-attachments/assets/143946c0-b679-4180-9744-6dc23111bd27" />

**Núcleo operativo**: mesas, reservaciones, órdenes, y los ítems de cada orden. **Personal**: empleados con sus roles (mesero, cocinero, cajero). **Menú**: categorías, platillos e ingredientes con sus costos. **Proveedores e inventario**: para control de existencias y compras. **Clientes y pagos**: para fidelización y cierre de caja.

Aquí el diagrama entidad-relación:Las entidades se agrupan en 5 módulos:

**Atención al cliente**: `CLIENTE`, `RESERVACION`, `MESA` — controlan la disponibilidad de mesas y el historial del cliente.

**Operación de cocina**: `ORDEN`, `DETALLE_ORDEN` — el corazón del sistema; cada orden tiene sus ítems con cantidad y precio al momento de la venta.

**Menú e inventario**: `PLATILLO`, `CATEGORIA`, `INGREDIENTE`, `PLATILLO_INGREDIENTE` — permiten calcular el costo real de cada platillo y disparar alertas de stock bajo.

**Recursos humanos**: `EMPLEADO` — vinculado a órdenes para medir desempeño por mesero y turno.

**Finanzas y proveedores**: `PAGO`, `PROVEEDOR`, `COMPRA` — cierran el ciclo con los métodos de cobro y la trazabilidad de insumos.

¿Quieres profundizar en alguna entidad, agregar módulos como **fidelización de clientes**, **delivery**, o generar el script SQL de creación?

## Las entidades con sus atributos y tipo en forma de tabla para cada una de las entidades
**Tablas**
<img width="667" height="589" alt="image" src="https://github.com/user-attachments/assets/3a5b170c-328e-48ca-93c9-01539ecc0b7f" />
<img width="667" height="612" alt="image" src="https://github.com/user-attachments/assets/0b0f9a8b-a331-4bed-8286-d6ed875c7ccc" />
<img width="675" height="558" alt="image" src="https://github.com/user-attachments/assets/ceb13c60-9801-45d0-acb5-e130c9863294" />
<img width="665" height="299" alt="image" src="https://github.com/user-attachments/assets/ecd01ca5-066f-4816-9982-7f295417cc90" />

## De acuerdo a tu respuesta anterior puedes generar un script en sql para descargar con el nombre bdrestaurante.sql para las 13 entidades con sus relaciones
El script está listo para descargar. Incluye:

- Las 13 tablas con todos sus atributos, tipos y constraints (`NOT NULL`, `CHECK`, `UNIQUE`).
- Llaves primarias y foráneas con sus políticas de `ON UPDATE` y `ON DELETE`.
- 12 índices para optimizar las consultas más frecuentes (búsqueda por fecha, estado, mesa, etc.).
- Datos iniciales de ejemplo: 6 categorías, 5 empleados, 7 mesas y 3 proveedores.
- Compatible con MySQL 8.0+.

Para ejecutarlo basta con correr `mysql -u usuario -p < bdrestaurante.sql` o importarlo desde MySQL Workbench / phpMyAdmin.

¿Quieres agregar también datos de prueba más completos (platillos, ingredientes, órdenes de ejemplo)?
