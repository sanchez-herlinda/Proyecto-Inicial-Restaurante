# 📋 Plan de Implementación Profesional: Aplicación "Restaurante" (Flutter + Firebase)

> 🎯 **Alcance:** Desarrollo multiplataforma (Android, iOS, Web, Windows) de alto rendimiento para gestión administrativa y operativa de restaurante. Arquitectura MVVM + Provider, backend Firestore + Auth, paleta tierra, navegación responsiva y control de accesos por roles.
> ⚠️ **Nota técnica:** Se utilizará **VS Code** como entorno principal (Antigravity no es un IDE estándar para Flutter; si se refiere a una herramienta específica de su ecosistema, el plan se adapta sin alterar la arquitectura).

---

## 🗺️ Índice de Fases
1. Configuración del Entorno y Estructura Base
2. Modelado de Datos Firestore (13 Entidades)
3. Configuración de Firebase Console y Seguridad RBAC
4. Diseño UI/UX y Estrategia de Navegación Responsiva
5. Implementación del Patrón MVVM con Provider
6. Secuencia de Desarrollo por Módulos
7. Capa de Servicios y Flujo de Datos Bidireccional
8. Pruebas, Optimización y Despliegue Multiplataforma
9. Monitorización, Mantenimiento y Documentación
10. Anexo: Estructura de Carpetas y Matriz de Dependencias

---

## 🔹 Fase 1: Configuración del Entorno y Estructura Base
| Paso | Acción |
|------|--------|
| 1.1 | Instalar Flutter SDK (canal estable), Dart y configurar variables de entorno. Verificar con `flutter doctor`. |
| 1.2 | Instalar VS Code y extensiones oficiales: `Flutter`, `Dart`, `Error Lens`, `Pubspec Assist`, `Firebase`, `Awesome Flutter Snippets`. |
| 1.3 | Crear repositorio Git, configurar `.gitignore` oficial de Flutter y ramificación protegida (`main`, `develop`, `feature/*`). |
| 1.4 | Inicializar proyecto: `flutter create restaurante_app --platforms=android,ios,web,windows`. |
| 1.5 | Configurar `pubspec.yaml` con las dependencias base (ver Anexo). Ejecutar `flutter pub get` y validar compatibilidad. |
| 1.6 | Estructurar carpetas siguiendo el patrón MVVM modular (ver Anexo: Árbol de directorios). |
| 1.7 | Configurar linter estricto (`analysis_options.yaml`), reglas de formato y scripts de pre-commit. |

---

## 🔹 Fase 2: Modelado de Datos Firestore (13 Entidades)
Se transforma el esquema relacional a un modelo documental NoSQL optimizado para consultas en tiempo real y operaciones atómicas.

| Colección | Propósito | Campos Clave | Estrategia NoSQL |
|-----------|-----------|--------------|------------------|
| `cliente` | Registro de comensales | `id`, `nombre`, `telefono`, `email`, `fecha_registro`, `notas` | Colección raíz. Indexar `email` y `telefono`. |
| `mesa` | Control de salón | `id`, `numero`, `capacidad`, `ubicacion`, `estado` | `estado` controlado por flujo de órdenes. |
| `reservacion` | Planificación de afluencia | `id`, `cliente_id`, `mesa_id`, `fecha_hora`, `num_personas`, `estado`, `notas` | Query compuesta por `fecha_hora` + `estado`. |
| `empleado` | Control de accesos y RRHH | `id`, `nombre`, `rol`, `turno`, `telefono`, `fecha_ingreso`, `activo` | Base para RBAC. `uid` de Auth vinculado al `id` documento. |
| `categoria` | Clasificación de menú | `id`, `nombre`, `descripcion`, `activa` | Colección ligera. Caché local si >50 items. |
| `platillo` | Catálogo gastronómico | `id`, `categoria_id`, `nombre`, `descripcion`, `precio`, `costo`, `tiempo_prep`, `disponible`, `imagen_url` | Subcolección `platillo_ingrediente` anidada para evitar joins. |
| `platillo_ingrediente` | Receta/Composición | `platillo_id`, `ingrediente_id`, `cantidad`, `unidad` | Subcolección dentro de `platillo` o colección independiente con índices dobles. |
| `ingrediente` | Inventario insumos | `id`, `nombre`, `unidad_medida`, `stock_actual`, `stock_minimo`, `costo_unitario`, `activo` | Alerta de stock bajo vía trigger lógico en Provider. |
| `proveedor` | Abastecimiento | `id`, `nombre`, `contacto`, `telefono`, `email`, `direccion`, `activo` | Colección estática. Vinculación por `proveedor_id`. |
| `compra` | Historial adquisiciones | `id`, `proveedor_id`, `ingrediente_id`, `fecha`, `cantidad`, `costo_unitario`, `total`, `factura_ref` | Transacción atómica al actualizar `stock_actual`. |
| `orden` | Ciclo de venta | `id`, `mesa_id`, `empleado_id`, `cliente_id`, `fecha_hora`, `estado`, `subtotal`, `impuesto`, `total` | Estado máquina: `pendiente` → `en_preparacion` → `servido` → `cerrado`. |
| `detalle_orden` | Líneas de venta | `id`, `orden_id`, `platillo_id`, `cantidad`, `precio_unitario`, `descuento`, `notas` | Subcolección de `orden` para consistencia transaccional. |
| `pago` | Cierre financiero | `id`, `orden_id`, `metodo_pago`, `monto`, `referencia`, `fecha_hora` | 1:1 con `orden`. Registro inmutable post-cierre. |

**🔍 Lógica de Relaciones en NoSQL:**
- Las relaciones 1:N se modelan con IDs de referencia.
- Las relaciones N:M (`platillo` ↔ `ingrediente`) se resuelven mediante subcolección o colección puente indexada.
- Se prioriza la **desnormalización controlada** para lecturas frecuentes (ej. `nombre_platillo` duplicado en `detalle_orden` para evitar joins en tiempo real).

---

## 🔹 Fase 3: Configuración de Firebase Console y Seguridad RBAC
1. **Proyecto Firebase:** Crear/Reutilizar `BDcrudrestaurante`. Registrar apps (Android, iOS, Web, Windows). Descargar configuraciones y colocarlas en rutas oficiales.
2. **Authentication:** Habilitar `Email/Password` y `Google Sign-In`. Configurar dominios autorizados para Web y callbacks de redirección.
3. **Firestore:** Modo nativo. Ubicación geográfica cercana a usuarios objetivo. Habilitar emuladores para desarrollo local.
4. **Firebase Storage:** Bucket configurado para `imagen_url`. Reglas de acceso: lectura pública, escritura solo con `auth != null` y rol `gerente`/`cocinero`.
5. **Reglas de Seguridad (Concepto):**
   - Validar `request.auth.uid` contra `empleados/{id}` donde `uid == request.auth.uid`.
   - Extraer `rol` del documento `empleado` en tiempo de evaluación.
   - Aplicar `allow read/write if:`:
     - `gerente`: acceso total a todas las colecciones.
     - `mesero`: `mesa`, `reservacion`, `cliente`, `orden` (creación/lectura), `detalle_orden`, `pago`.
     - `cocinero`: `platillo`, `categoria`, `ingrediente` (lectura), `detalle_orden` (actualización estado).
     - Restricción de campos sensibles: `costo_unitario`, `total`, `factura_ref` solo visibles para `gerente`.
   - Validación de tipos, rangos y campos obligatorios en `allow write`.

---

## 🔹 Fase 4: Diseño UI/UX y Estrategia de Navegación Responsiva
| Aspecto | Implementación |
|---------|----------------|
| **Paleta Tierra** | Variables de color definidas en `core/theme/`: Terracota (`#E27D60`), Ocre (`#D4A373`), Beige (`#F4F1DE`), Café Orgánico (`#5C4033`), Textos (`#2C2C2C`, `#F9F7F2`). |
| **Tipografía** | `google_fonts`: `Playfair Display` (títulos/encabezados), `Inter` o `Lato` (cuerpo/UI). Pesos 400, 500, 600, 700. |
| **Navegación Responsiva** | Breakpoint en `600px`/`900px`. Uso de `LayoutBuilder` + `MediaQuery`. Condicional: `NavigationRail` (desktop/web) vs `BottomNavigationBar` (mobile). |
| **Componentes Reusables** | `lib/views/shared/`: Botones primarios/secundarios, campos de texto con validación visual, tarjetas de menú/estadísticas, loaders (`flutter_spinkit`), diálogos de confirmación, snackbars temáticos. |
| **Prototipado** | Wireframes en Figma → Validación de flujos → Exportación de assets → Implementación en `ThemeData` global. |
| **Accesibilidad** | Contraste mínimo AA, tamaños de toque ≥48px, etiquetas semánticas, soporte para `TextScaler`. |

---

## 🔹 Fase 5: Implementación del Patrón MVVM con Provider
| Capa | Responsabilidad | Implementación en Flutter |
|-----------------------|---------------------------|
| **Model** | Representación de datos puros. | Clases Dart con `id`, campos tipados, `toJson()` / `fromJson()`. Null-safety estricta. |
| **View** | Interfaz de usuario. | Widgets sin estado lógico. Solo escuchan y renderizan. Uso de `Consumer` o `Selector`. |
| **ViewModel** | Lógica de presentación y estado. | Clases `ChangeNotifier` o `StateNotifier`. Expone `State`, `load()`, `create()`, `update()`, `delete()`. Maneja loading/error. |
| **Service** | Comunicación externa. | Métodos asíncronos que interactúan con `FirebaseFirestore`, `FirebaseAuth`, `FirebaseStorage`. Retornan `Future` o `Stream`. |

**Flujo Reactivo:**
1. `View` invoca método en `ViewModel` (ej. `crearOrden()`).
2. `ViewModel` actualiza estado a `loading`.
3. `ViewModel` delega en `Service`.
4. `Service` realiza operación Firestore/Auth y retorna resultado.
5. `ViewModel` actualiza estado (`data` o `error`) y notifica a `View`.
6. `View` se reconstruye solo donde se usa `context.watch`/`context.select`.

---

## 🔹 Fase 6: Secuencia de Desarrollo por Módulos
| Orden | Módulo | Entidades Involucradas | Hitos de Entrega |
|-------|--------|------------------------|------------------|
| 1 | **Autenticación y Sesión** | `empleado`, `FirebaseAuth` | Login, registro, Google Auth, recuperación, listener de estado, redirección por rol. |
| 2 | **Salón y Reservas** | `mesa`, `reservacion`, `cliente` | CRUD mesa, calendario de reservas, asignación dinámica, cambio de estado en tiempo real. |
| 3 | **Menú y Cocina** | `platillo`, `categoria`, `platillo_ingrediente` | Listado por categorías, alta/edición de platillos, composición de receta, toggle disponibilidad. |
| 4 | **Inventario y Compras** | `ingrediente`, `proveedor`, `compra` | Dashboard de stock, alertas mínimas, registro de compras, actualización atómica de inventario. |
| 5 | **Ventas y Finanzas** | `orden`, `detalle_orden`, `pago` | Creación de orden, agregado de items, cálculo de impuestos/descuentos, cierre con pago, historial filtrable. |
| 6 | **Administración y Roles** | `empleado`, Reglas Firestore | Gestión de personal, asignación de turnos, validación de permisos, auditoría básica. |
| 7 | **Integración Final y QA** | Todas las entidades | Flujos cruzados (reserva → orden → pago → inventario), pruebas de estrés, optimización de renders. |

---

## 🔹 Fase 7: Capa de Servicios y Flujo de Datos Bidireccional
1. **`auth_service.dart`**: Métodos para `signIn`, `signUp`, `signInWithGoogle`, `signOut`, `resetPassword`, `getCurrentUser`, `streamAuthState`.
2. **`firestore_service.dart`**: Clase genérica `<T>` con `getCollection()`, `getDocument()`, `add()`, `update()`, `delete()`, `stream()`, `batchWrite()`. Manejo de `Timestamp`, `DocumentReference`, errores de red.
3. **`storage_service.dart`**: Upload con compresión previa, generación de URL expirable, limpieza de archivos huérfanos.
4. **Sincronización Offline/Online**: Habilitar `FirebaseFirestore.instance.enableNetwork()` y persistencia en disco nativa de Firestore. Manejo de colas locales para operaciones en red intermitente.
5. **Manejo de Errores**: Clase `AppException` con tipos (`network`, `auth`, `permission`, `validation`). Traducción a mensajes UI amigables.

---

## 🔹 Fase 8: Pruebas, Optimización y Despliegue Multiplataforma
| Etapa | Acciones |
|-------|----------|
| **Pruebas Unitarias** | Lógica de `ViewModels`, validaciones de formularios, mapeo `fromJson/toJson`, cálculo de totales/impositivos. |
| **Pruebas de Widget** | Renderizado de componentes reutilizables, estados `loading`/`error`/`empty`, navegación básica. |
| **Pruebas de Integración** | Flujos completos con Firebase Emulators (Auth + Firestore). Validación de reglas de seguridad. |
| **Optimización** | Uso de `ListView.builder`, `RepaintBoundary`, `const` constructors, `Selector` para evitar rebuilds, paginación con `startAfterDocument`. |
| **Configuración Multiplataforma** | Iconos adaptativos, splash screen nativo, permisos (red, internet), versión semántica, firma de builds. |
| **Despliegue** | Android: `appbundle` → Play Console. iOS: `ipa` → App Store Connect. Web: `build web --web-renderer canvaskit` → Hosting. Windows: `msix` o `exe` → Microsoft Store / distribuidor directo. |
| **CI/CD** | Pipeline GitHub Actions/Codemagic: lint → test → build → deploy automático en ramas `release/*`. |

---

## 🔹 Fase 9: Monitorización, Mantenimiento y Documentación
1. **Firebase Crashlytics**: Integración para captura de excepciones no manejadas en producción.
2. **Analytics**: Eventos de negocio (`orden_creada`, `platillo_agregado`, `stock_bajo`, `login_fallido`).
3. **Backup & Export**: Scripts periódicos de exportación de Firestore a Cloud Storage o BigQuery.
4. **Documentación Técnica**: README con setup, guía de arquitectura, diagrama de flujo de datos, glosario de entidades, instrucciones de despliegue.
5. **Roadmap Post-Lanzamiento**: Modo offline robusto, notificaciones push para cocineros/meseros, reportes PDF, integración con impresoras térmicas, IA para predicción de demanda.

---

## 📦 Anexo: Estructura de Carpetas y Dependencias

### 🗂️ Árbol de Directorios (`lib/`)
```text
lib/
├── core/
│   ├── theme/            # app_colors.dart, app_text_styles.dart, app_theme.dart
│   ├── constants/        # routes.dart, app_strings.dart, firestore_collections.dart
│   └── utils/            # currency_formatter.dart, date_formatter.dart, validators.dart
├── models/               # 13 archivos: cliente_model.dart, mesa_model.dart, etc.
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── salon_provider.dart
│   ├── menu_provider.dart
│   ├── inventario_provider.dart
│   ├── orden_provider.dart
│   └── personal_provider.dart
├── views/
│   ├── auth/             # login_view.dart, register_view.dart
│   ├── home/             # dashboard_view.dart, responsive_scaffold.dart
│   ├── salon/            # mesas_view.dart, reservas_view.dart
│   ├── cocina/           # menu_view.dart, detalle_platillo_view.dart
│   ├── inventario/       # ingredientes_view.dart, compras_view.dart, proveedores_view.dart
│   ├── finanzas/         # ordenes_view.dart, pagos_view.dart, reportes_view.dart
│   ├── personal/         # empleados_view.dart, roles_view.dart
│   └── shared/           # custom_button.dart, app_input.dart, loading_overlay.dart, etc.
└── main.dart             # inicialización Firebase, MultiProvider, runApp()
```

### 📦 `pubspec.yaml` (Matriz de Dependencias)
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  
  # Firebase
  firebase_core: ^3.x.x
  firebase_auth: ^5.x.x
  cloud_firestore: ^5.x.x
  firebase_storage: ^12.x.x
  google_sign_in: ^6.x.x
  
  # Estado y Arquitectura
  provider: ^6.x.x
  
  # UI y Experiencia
  google_fonts: ^6.x.x
  flutter_spinkit: ^5.x.x
  intl: ^0.19.x
  image_picker: ^1.x.x
  cached_network_image: ^3.x.x
  shimmer: ^3.x.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.x.x
  mocktail: ^1.x.x
  integration_test:
    sdk: flutter
```
> ✅ **Nota:** Las versiones `^x.x.x` deben alinearse con la versión estable de Flutter utilizada. Ejecutar `flutter pub outdated` antes de fijar versiones.

---

## ✅ Checklist de Validación Pre-Desarrollo
- [ ] Flutter SDK y VS Code listos con extensiones activas.
- [ ] Repositorio Git con ramas y `.gitignore` configurados.
- [ ] Proyecto `BDcrudrestaurante` creado en Firebase Console.
- [ ] Apps registradas y archivos de configuración descargados.
- [ ] Auth (Email/Password + Google) habilitado.
- [ ] Firestore en modo nativo con estructura de colecciones documentada.
- [ ] Reglas de seguridad RBAC definidas conceptualmente.
- [ ] Paleta tierra y tipografía seleccionadas y exportadas.
- [ ] Prototipos responsivos (Rail vs Bottom) validados.
- [ ] Estructura `lib/` creada según MVVM.
- [ ] Dependencias en `pubspec.yaml` instaladas y verificadas.
- [ ] Plan de pruebas y estrategia de despliegue definido.

---

🔜 **Próximo paso:** Una vez valides esta hoja de ruta, puedo generar:
1. Los archivos `model` con serialización completa para las 13 entidades.
2. La configuración exacta de `FirebaseOptions` y `main.dart`.
3. Los `Provider` base con gestión de estados y manejo de errores.
4. El sistema de navegación responsiva (`responsive_scaffold.dart`).
5. Las reglas de Firestore estructuradas por rol.

¿Deseas que proceda con la **Fase 1 (Estructura de Carpetas + Configuración Inicial)** o prefieres profundizar primero en el **Modelado de Datos + Proveedores**?
## Prompt
El proyecto consiste en el desarrollo de una aplicación multiplataforma de alto rendimiento totalmente funcional utilizando Flutter y Dart, con despliegue garantizado en Android, iOS, Web y Windows. La ingeniería se centrará en el uso de VS Code o Antigravity, estableciendo una conexión directa con el proyecto de Firebase Console BDcrudrestaurante. El núcleo del backend será Cloud Firestore para la persistencia de datos en tiempo real y Firebase Authentication para el control de accesos, asegurando una base sólida para la gestión administrativa del restaurante.
La aplicación adoptará una estética basada en una paleta de colores tierra (terracotas, ocres, beige y café orgánico), diseñada para transmitir calidez y una conexión con el mundo gastronómico de Italia. El layout administrativo será responsivo, utilizando un Navigation Rail para escritorio (Windows/Web) y una barra de navegación inferior optimizada para móviles (Android/iOS), garantizando que la administración sea intuitiva en cualquier pantalla.
Se implementa el patrón de diseño MVVM (Model-View-ViewModel) integrado con el paquete Provider. La estructura se organiza de forma modular en la carpeta lib, integrando lógicamente las 13 entidades del esquema original mediante modelos Dart con métodos de serialización toJson/fromJson. El mapeo de datos se distribuye de la siguiente manera:
Gestión de Ventas y Finanzas: El flujo comienza en la Orden, la cual vincula a un Empleado, un Cliente y una Mesa. Cada orden se desglosa en un Detalle_Orden conectado a la entidad Platillo. El ciclo cierra con el Pago, que registra el método, monto y referencia de la transacción.
Logística de Salón y Clientes: Se gestiona la disponibilidad mediante la entidad Mesa (capacidad y ubicación) y la Reservación, que asegura el control de afluencia vinculando al Cliente con un horario específico.
Ingeniería de Menú e Inventario: Los Platillos (con sus categorías y costos de preparación) se vinculan a sus componentes mediante Platillo_Ingrediente. El inventario se controla a través de la entidad Ingrediente (stock actual vs mínimo), el cual se abastece mediante la entidad Compra vinculada directamente a la tabla de Proveedor.
Administración de Personal: La tabla Empleado es el eje del control de accesos, almacenando roles, turnos y estado activo.
El módulo de autenticación integral (Email/Password y Google Auth) validará los roles de usuario basándose en la entidad Empleado (gerente, mesero, cocinero, etc.). El acceso al CRUD de platillos, la gestión de inventarios y la administración de personal estará protegido por reglas de seguridad de Firestore que reflejan la jerarquía del restaurante, asegurando que solo el personal autorizado pueda visualizar o editar datos sensibles como el costo_unitario de los ingredientes o el total de las ventas.
El archivo pubspec.yaml integrará las dependencias: firebase_core, cloud_firestore, firebase_auth, google_sign_in, provider y google_fonts. Esta infraestructura técnica garantiza que la integración entre las vistas, los servicios de Firebase y los modelos de datos sea totalmente funcional, logrando un flujo de datos bidireccional, reactivo y transparente para la operación diaria del restaurante.
Con todo esto realiza un plan de implementación completo y profesional donde me des toda la organización de dicho proyecto.
1. Esquema de Base de Datos (Colecciones Firestore)
Aunque en Firestore hablamos de colecciones y documentos, mantendremos la estructura lógica de las 13 entidades para garantizar la integridad de los datos.
A. Gestión de Ventas y Finanzas
Colección
Campos Principales
orden
id, mesa_id, empleado_id, cliente_id, fecha_hora, estado, subtotal, impuesto, total
detalle_orden
id, orden_id, platillo_id, cantidad, precio_unitario, descuento, notas
pago
id, orden_id, metodo_pago, monto, referencia, fecha_hora

B. Logística de Salón y Clientes
Colección
Campos Principales
mesa
id, numero, capacidad, ubicacion, estado (libre/ocupada/reservada)
reservacion
id, cliente_id, mesa_id, fecha_hora, num_personas, estado, notas
cliente
id, nombre, telefono, email, fecha_registro, notas

C. Menú e Inventario
Colección
Campos Principales
platillo
id, categoria_id, nombre, descripcion, precio, costo, tiempo_prep, disponible, imagen_url
categoria
id, nombre, descripcion, activa
ingrediente
id, nombre, unidad_medida, stock_actual, stock_minimo, costo_unitario, activo
platillo_ingrediente
platillo_id, ingrediente_id, cantidad, unidad
compra
id, proveedor_id, ingrediente_id, fecha, cantidad, costo_unitario, total, factura_ref
proveedor
id, nombre, contacto, telefono, email, direccion, activo

D. Recursos Humanos
Colección
Campos Principales
empleado
id, nombre, rol, turno, telefono, fecha_ingreso, activo

2. Estructura del Proyecto (Diagrama de Carpetas)
Siguiendo el patrón MVVM y la modularidad solicitada, la carpeta lib se organizará de la siguiente manera:
Plaintext
lib/
├── core/
│   ├── theme/              # Colores tierra (terracota, ocre, café)
│   ├── constants/          # Strings y rutas de navegación
│   └── utils/              # Validadores y formateadores de moneda
├── models/                 # Clases con toJson() y fromJson()
│   ├── empleado_model.dart
│   ├── platillo_model.dart
│   └── (13 archivos de modelos...)
├── services/               # Comunicación directa con Firebase
│   ├── auth_service.dart   # Login, Google Auth, Password Recovery
│   ├── firestore_service.dart # CRUD genérico
│   └── storage_service.dart   # Para subir fotos de platillos
├── providers/              # Gestión de estado reactivo (Lógica de negocio)
│   ├── orden_provider.dart
│   ├── inventario_provider.dart
│   └── auth_provider.dart
├── views/                  # Interfaces de Usuario (UI)
│   ├── auth/               # Login, Registro
│   ├── home/               # Dashboard principal
│   ├── salon/              # Gestión de Mesas y Reservas
│   ├── cocina/             # Gestión de Platillos y Categorías
│   ├── inventario/         # Gestión de Ingredientes y Compras
│   └── shared/             # Widgets reutilizables (Botones, Inputs)
└── main.dart               # Punto de entrada y configuración de Providers
3. Configuración de Librerías (pubspec.yaml)
Para que el proyecto funcione con la potencia de Firebase y el diseño reactivo, estas son las dependencias clave:
YAML
dependencies:
  flutter:
    sdk: flutter
  # Firebase
  firebase_core: ^2.x.x
  cloud_firestore: ^4.x.x
  firebase_auth: ^4.x.x
  google_sign_in: ^6.x.x
  # Gestión de Estado
  provider: ^6.x.x

  # UI y Estética
  google_fonts: ^6.x.x
  flutter_spinkit: ^5.x.x # Para loaders elegantes
  # Utilidades
  intl: ^0.19.x           # Formato de fechas y moneda
  image_picker: ^1.x.x    # Para fotos de platillos
4. Entorno de Base de Datos
El proyecto operará exclusivamente bajo el ecosistema de Google Cloud, centralizado en:
Plataforma: Firebase Console
ID del Proyecto: BDcrudrestaurante
Servicios Activos:
Authentication: Habilitado para Email/Password y Google Sign-In.
Cloud Firestore: Configurado en modo nativo con reglas de seguridad basadas en el campo rol del documento en la colección empleado.
Firebase Storage: (Opcional pero recomendado) Para almacenar las imágenes de los platillos definidas en imagen_url.
Nota de implementación: Al trabajar con Firestore (NoSQL), recuerda que la tabla intermedia platillo_ingrediente puede implementarse como una subcolección dentro de platillo para mejorar el rendimiento de las consultas, o como una colección independiente si necesitas reportes de uso de ingredientes globales.


