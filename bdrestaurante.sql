-- ============================================================
--  BASE DE DATOS: RESTAURANTE
--  Archivo: bdrestaurante.sql
--  Motor:    MySQL 8.0+
--  Entidades: 13
-- ============================================================

CREATE DATABASE IF NOT EXISTS bdrestaurante
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bdrestaurante;

-- ============================================================
-- 1. MÓDULO: ATENCIÓN AL CLIENTE
-- ============================================================

CREATE TABLE cliente (
  id              INT             NOT NULL AUTO_INCREMENT,
  nombre          VARCHAR(100)    NOT NULL,
  telefono        VARCHAR(15)     NULL,
  email           VARCHAR(100)    NULL,
  fecha_registro  DATE            NOT NULL DEFAULT (CURRENT_DATE),
  notas           TEXT            NULL,
  CONSTRAINT pk_cliente PRIMARY KEY (id),
  CONSTRAINT uq_cliente_email UNIQUE (email)
);

CREATE TABLE mesa (
  id          INT          NOT NULL AUTO_INCREMENT,
  numero      INT          NOT NULL,
  capacidad   INT          NOT NULL,
  ubicacion   VARCHAR(50)  NULL COMMENT 'Ej: terraza, interior, barra',
  estado      ENUM('libre','ocupada','reservada','fuera_servicio')
              NOT NULL DEFAULT 'libre',
  CONSTRAINT pk_mesa PRIMARY KEY (id),
  CONSTRAINT uq_mesa_numero UNIQUE (numero),
  CONSTRAINT chk_mesa_capacidad CHECK (capacidad > 0)
);

CREATE TABLE reservacion (
  id           INT       NOT NULL AUTO_INCREMENT,
  cliente_id   INT       NOT NULL,
  mesa_id      INT       NOT NULL,
  fecha_hora   DATETIME  NOT NULL,
  num_personas INT       NOT NULL,
  estado       ENUM('pendiente','confirmada','cancelada','completada')
               NOT NULL DEFAULT 'pendiente',
  notas        TEXT      NULL,
  CONSTRAINT pk_reservacion PRIMARY KEY (id),
  CONSTRAINT fk_reservacion_cliente FOREIGN KEY (cliente_id)
    REFERENCES cliente (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reservacion_mesa FOREIGN KEY (mesa_id)
    REFERENCES mesa (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_reservacion_personas CHECK (num_personas > 0)
);

-- ============================================================
-- 2. MÓDULO: RECURSOS HUMANOS
-- ============================================================

CREATE TABLE empleado (
  id            INT          NOT NULL AUTO_INCREMENT,
  nombre        VARCHAR(100) NOT NULL,
  rol           ENUM('gerente','mesero','cocinero','cajero','bartender','host')
                NOT NULL,
  turno         ENUM('matutino','vespertino','nocturno')
                NOT NULL,
  telefono      VARCHAR(15)  NULL,
  fecha_ingreso DATE         NOT NULL DEFAULT (CURRENT_DATE),
  activo        BOOLEAN      NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_empleado PRIMARY KEY (id)
);

-- ============================================================
-- 3. MÓDULO: MENÚ E INVENTARIO
-- ============================================================

CREATE TABLE categoria (
  id          INT          NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(60)  NOT NULL,
  descripcion TEXT         NULL,
  activa      BOOLEAN      NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_categoria PRIMARY KEY (id),
  CONSTRAINT uq_categoria_nombre UNIQUE (nombre)
);

CREATE TABLE platillo (
  id              INT            NOT NULL AUTO_INCREMENT,
  categoria_id    INT            NOT NULL,
  nombre          VARCHAR(100)   NOT NULL,
  descripcion     TEXT           NULL,
  precio          DECIMAL(10,2)  NOT NULL,
  costo           DECIMAL(10,2)  NULL COMMENT 'Costo de producción estimado',
  tiempo_prep_min INT            NULL COMMENT 'Tiempo de preparación en minutos',
  disponible      BOOLEAN        NOT NULL DEFAULT TRUE,
  imagen_url      VARCHAR(255)   NULL,
  CONSTRAINT pk_platillo PRIMARY KEY (id),
  CONSTRAINT fk_platillo_categoria FOREIGN KEY (categoria_id)
    REFERENCES categoria (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_platillo_precio CHECK (precio >= 0),
  CONSTRAINT chk_platillo_costo  CHECK (costo  >= 0 OR costo IS NULL)
);

CREATE TABLE ingrediente (
  id             INT            NOT NULL AUTO_INCREMENT,
  nombre         VARCHAR(100)   NOT NULL,
  unidad_medida  VARCHAR(20)    NOT NULL COMMENT 'kg, lt, pza, gr, ml...',
  stock_actual   DECIMAL(10,3)  NOT NULL DEFAULT 0,
  stock_minimo   DECIMAL(10,3)  NOT NULL DEFAULT 0,
  costo_unitario DECIMAL(10,2)  NULL,
  activo         BOOLEAN        NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_ingrediente PRIMARY KEY (id),
  CONSTRAINT uq_ingrediente_nombre UNIQUE (nombre),
  CONSTRAINT chk_ingrediente_stock CHECK (stock_actual >= 0)
);

CREATE TABLE platillo_ingrediente (
  platillo_id    INT            NOT NULL,
  ingrediente_id INT            NOT NULL,
  cantidad       DECIMAL(10,3)  NOT NULL,
  unidad         VARCHAR(20)    NOT NULL,
  CONSTRAINT pk_platillo_ingrediente PRIMARY KEY (platillo_id, ingrediente_id),
  CONSTRAINT fk_pi_platillo FOREIGN KEY (platillo_id)
    REFERENCES platillo (id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pi_ingrediente FOREIGN KEY (ingrediente_id)
    REFERENCES ingrediente (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_pi_cantidad CHECK (cantidad > 0)
);

-- ============================================================
-- 4. MÓDULO: OPERACIÓN (ÓRDENES)
-- ============================================================

CREATE TABLE orden (
  id           INT            NOT NULL AUTO_INCREMENT,
  mesa_id      INT            NOT NULL,
  empleado_id  INT            NOT NULL,
  cliente_id   INT            NULL,
  fecha_hora   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado       ENUM('abierta','en_cocina','lista','cerrada','cancelada')
               NOT NULL DEFAULT 'abierta',
  subtotal     DECIMAL(10,2)  NOT NULL DEFAULT 0,
  impuesto     DECIMAL(10,2)  NOT NULL DEFAULT 0,
  total        DECIMAL(10,2)  NOT NULL DEFAULT 0,
  CONSTRAINT pk_orden PRIMARY KEY (id),
  CONSTRAINT fk_orden_mesa FOREIGN KEY (mesa_id)
    REFERENCES mesa (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_orden_empleado FOREIGN KEY (empleado_id)
    REFERENCES empleado (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_orden_cliente FOREIGN KEY (cliente_id)
    REFERENCES cliente (id) ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE detalle_orden (
  id              INT            NOT NULL AUTO_INCREMENT,
  orden_id        INT            NOT NULL,
  platillo_id     INT            NOT NULL,
  cantidad        INT            NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2)  NOT NULL,
  descuento       DECIMAL(5,2)   NOT NULL DEFAULT 0,
  notas           TEXT           NULL,
  CONSTRAINT pk_detalle_orden PRIMARY KEY (id),
  CONSTRAINT fk_do_orden FOREIGN KEY (orden_id)
    REFERENCES orden (id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_do_platillo FOREIGN KEY (platillo_id)
    REFERENCES platillo (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_do_cantidad  CHECK (cantidad > 0),
  CONSTRAINT chk_do_descuento CHECK (descuento BETWEEN 0 AND 100)
);

-- ============================================================
-- 5. MÓDULO: FINANZAS Y PROVEEDORES
-- ============================================================

CREATE TABLE pago (
  id          INT            NOT NULL AUTO_INCREMENT,
  orden_id    INT            NOT NULL,
  metodo_pago ENUM('efectivo','tarjeta_credito','tarjeta_debito',
                   'transferencia','vales','otro')
              NOT NULL,
  monto       DECIMAL(10,2)  NOT NULL,
  referencia  VARCHAR(100)   NULL COMMENT 'Nro. de autorización, folio, etc.',
  fecha_hora  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_pago PRIMARY KEY (id),
  CONSTRAINT fk_pago_orden FOREIGN KEY (orden_id)
    REFERENCES orden (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_pago_monto CHECK (monto > 0)
);

CREATE TABLE proveedor (
  id        INT          NOT NULL AUTO_INCREMENT,
  nombre    VARCHAR(100) NOT NULL,
  contacto  VARCHAR(100) NULL,
  telefono  VARCHAR(15)  NULL,
  email     VARCHAR(100) NULL,
  direccion TEXT         NULL,
  activo    BOOLEAN      NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_proveedor PRIMARY KEY (id),
  CONSTRAINT uq_proveedor_nombre UNIQUE (nombre)
);

CREATE TABLE compra (
  id             INT            NOT NULL AUTO_INCREMENT,
  proveedor_id   INT            NOT NULL,
  ingrediente_id INT            NOT NULL,
  fecha          DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  cantidad       DECIMAL(10,3)  NOT NULL,
  costo_unitario DECIMAL(10,2)  NOT NULL,
  total          DECIMAL(10,2)  NOT NULL,
  factura_ref    VARCHAR(60)    NULL COMMENT 'Número de factura del proveedor',
  CONSTRAINT pk_compra PRIMARY KEY (id),
  CONSTRAINT fk_compra_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedor (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_compra_ingrediente FOREIGN KEY (ingrediente_id)
    REFERENCES ingrediente (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_compra_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_compra_total    CHECK (total    >= 0)
);

-- ============================================================
-- ÍNDICES DE RENDIMIENTO
-- ============================================================

CREATE INDEX idx_reservacion_fecha    ON reservacion  (fecha_hora);
CREATE INDEX idx_reservacion_cliente  ON reservacion  (cliente_id);
CREATE INDEX idx_orden_fecha          ON orden        (fecha_hora);
CREATE INDEX idx_orden_estado         ON orden        (estado);
CREATE INDEX idx_orden_mesa           ON orden        (mesa_id);
CREATE INDEX idx_detalle_orden        ON detalle_orden(orden_id);
CREATE INDEX idx_pago_orden           ON pago         (orden_id);
CREATE INDEX idx_compra_fecha         ON compra       (fecha);
CREATE INDEX idx_compra_proveedor     ON compra       (proveedor_id);
CREATE INDEX idx_platillo_categoria   ON platillo     (categoria_id);
CREATE INDEX idx_platillo_disponible  ON platillo     (disponible);
CREATE INDEX idx_ingrediente_stock    ON ingrediente  (stock_actual);

-- ============================================================
-- DATOS INICIALES DE EJEMPLO
-- ============================================================

INSERT INTO categoria (nombre, descripcion) VALUES
  ('Entradas',      'Platillos para iniciar la comida'),
  ('Sopas y caldos','Sopas, cremas y consomés'),
  ('Platos fuertes','Platos principales de la carta'),
  ('Postres',       'Dulces y pasteles'),
  ('Bebidas',       'Refrescos, jugos y agua'),
  ('Bebidas alcohólicas', 'Cervezas, vinos y cócteles');

INSERT INTO empleado (nombre, rol, turno, telefono, fecha_ingreso) VALUES
  ('Ana García',     'gerente',    'matutino',    '6561000001', '2022-01-10'),
  ('Luis Martínez',  'cocinero',   'matutino',    '6561000002', '2022-03-15'),
  ('María López',    'mesero',     'matutino',    '6561000003', '2023-06-01'),
  ('Carlos Ruiz',    'cajero',     'vespertino',  '6561000004', '2023-07-20'),
  ('Sofía Torres',   'mesero',     'vespertino',  '6561000005', '2024-01-05');

INSERT INTO mesa (numero, capacidad, ubicacion, estado) VALUES
  (1,  2, 'interior',  'libre'),
  (2,  4, 'interior',  'libre'),
  (3,  4, 'interior',  'libre'),
  (4,  6, 'terraza',   'libre'),
  (5,  6, 'terraza',   'libre'),
  (6,  2, 'barra',     'libre'),
  (7,  8, 'privado',   'libre');

INSERT INTO proveedor (nombre, contacto, telefono, email) VALUES
  ('Distribuidora Norte S.A.',  'Pedro Soto',   '6561111111', 'ventas@dnorte.mx'),
  ('Frutas y Verduras Del Campo','Rosa Medina',  '6561222222', 'pedidos@dvcampo.mx'),
  ('Carnes Premium Juárez',      'Jorge Blanco', '6561333333', 'carnes@cpjuarez.mx');

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
