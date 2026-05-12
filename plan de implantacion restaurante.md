# 📋 Plan de Implementación: Aplicación "Restaurante" (Flutter + Firebase)

> 📌 **Nota preliminar:** "Antigravity" no es un IDE reconocido para Flutter. Se recomienda usar **VS Code** con las extensiones oficiales de Flutter y Dart. Si te referías a otra herramienta, indícalo y ajustaré el plan.

---

## 🎯 Objetivo General
Desarrollar una aplicación multiplataforma (Android, iOS, Web) para un restaurante, con autenticación por email/contraseña, gestión de catálogo/menu, carrito de compras, historial de pedidos y base de datos en tiempo real, utilizando Flutter, Firebase y Provider como gestor de estado.

---

## 🛠️ Fase 1: Configuración del Entorno de Desarrollo
1. Instalar Flutter SDK y Dart (versión estable más reciente).
2. Instalar VS Code y agregar extensiones: `Flutter`, `Dart`, `Firebase`, `Error Lens`, `Pubspec Assist`.
3. Verificar instalación con `flutter doctor` y corregir dependencias del sistema (Android SDK, Xcode si aplica, Chrome/Web).
4. Crear repositorio Git remoto y clonar localmente. Configurar `.gitignore` oficial de Flutter.
5. Inicializar proyecto: `flutter create restaurante_app`.
6. Definir estructura de carpetas inicial (ej: `lib/core/`, `lib/features/`, `lib/providers/`, `lib/models/`, `lib/services/`, `lib/screens/`, `assets/`).

---

## 🎨 Fase 2: Diseño UI/UX
1. Definir flujos de usuario: Registro → Login → Home/Menu → Detalle de plato → Carrito → Checkout → Perfil → Historial.
2. Crear wireframes y prototipo interactivo en **Figma** o **Adobe XD**.
3. Establecer sistema de diseño:
   - Paleta de colores (primario, secundario, fondo, texto, estados de error/éxito).
   - Tipografía (familia, pesos, tamaños para encabezados, cuerpo, botones).
   - Espaciado y radio de bordes coherentes.
   - Iconografía (Material Icons o set personalizado SVG).
4. Preparar assets: logo, imágenes de platos, splash screen, fuentes, iconos de app.
5. Definir criterios de responsividad (móvil, tablet, web) y accesibilidad (contraste, tamaños de toque, semántica).

---

## 🔥 Fase 3: Configuración de Firebase
1. Crear proyecto en Firebase Console.
2. Agregar aplicaciones: Android, iOS y Web. Descargar archivos de configuración (`google-services.json`, `GoogleService-Info.plist`, `firebase-config.js`).
3. Habilitar **Authentication** → Método `Email/Password`. Configurar verificación opcional por email.
4. Crear base de datos **Firestore** en modo producción. Definir estructura de colecciones inicial:
   - `users` (perfil, roles, direcciones)
   - `menu_items` (categorías, platos, precios, disponibilidad, imágenes)
   - `orders` (estado, items, total, fecha, usuario)
   - `cart` (temporal o persistente por sesión)
5. Configurar **Reglas de Seguridad** en Firestore y Auth (acceso por usuario, validación de roles, protección de datos sensibles).
6. Integrar Firebase CLI: `firebase login`, `firebase init` (solo para hosting/emuladores si se usan).

---

## 🏗️ Fase 4: Arquitectura y Gestión de Estado (Provider)
1. Adoptar arquitectura por características o limpia: separar `presentation`, `domain`, `data`.
2. Configurar `Provider` como gestor de estado global.
3. Crear providers base:
   - `AuthProvider` (estado de sesión, usuario actual, errores de auth)
   - `MenuProvider` (listado de platos, categorías, filtros, estado de carga)
   - `CartProvider` (agregar/eliminar, totales, persistencia local temporal)
   - `OrderProvider` (creación, seguimiento, historial)
4. Definir contratos de servicios (`AuthService`, `FirestoreService`, `StorageService` si aplica).
5. Implementar manejo de estados: `loading`, `success`, `error`, `empty`.
6. Configurar inyección de dependencias manual o mediante `get_it` si la complejidad lo requiere (opcional).

---

## 🔐 Fase 5: Autenticación de Usuarios
1. Implementar pantallas: Login, Registro, Recuperación de contraseña.
2. Validar formularios (email formato, contraseña ≥ 8 caracteres, confirmación, reglas de negocio).
3. Integrar `firebase_auth` para:
   - Crear cuenta con email/password
   - Iniciar sesión
   - Cerrar sesión
   - Escuchar cambios de estado (`authStateChanges`)
4. Gestionar errores de Firebase (cuentas duplicadas, credenciales inválidas, red, etc.) y traducirlos a mensajes UI.
5. Protecer rutas: redirigir a Login si no hay sesión, bloquear acceso a zonas admin si corresponde.
6. Implementar logout seguro y limpieza de estado local.

---

## 🗄️ Fase 6: Base de Datos Firestore
1. Definir modelos Dart (`UserModel`, `MenuItemModel`, `OrderModel`, `CartItemModel`) con serialización/deserialización (`fromJson`/`toJson`).
2. Crear capa de repositorios/servicios para Firestore:
   - Operaciones CRUD por colección
   - Consultas con filtros, ordenamiento y paginación
   - Listeners en tiempo real (`snapshots()`) para menú y pedidos
3. Implementar manejo de caché local (opcional: `shared_preferences` o `isar`/`hive` para carrito offline).
4. Configurar índices compuestos en Firebase Console según consultas planificadas.
5. Validar datos antes de enviar a Firestore (tipos, límites, campos obligatorios).
6. Implementar reintentos y manejo de fallos de red.

---

## 📱 Fase 7: Desarrollo de Interfaz e Integración
1. Construir pantallas siguiendo wireframes y sistema de diseño.
2. Conectar UI a Providers mediante `Consumer` o `Provider.of`.
3. Implementar navegación:
   - Estructura de rutas (login → home → menú → detalle → checkout → perfil)
   - Transiciones y deep links si aplica
4. Agregar estados visuales:
   - Indicadores de carga (`CircularProgressIndicator`, shimmer)
   - Mensajes de error con reintentos
   - Vistas vacías con llamadas a la acción
5. Optimizar imágenes: `cached_network_image`, compresión, formatos WebP.
6. Asegurar responsividad: `LayoutBuilder`, `MediaQuery`, breakpoints, `Flexible`/`Expanded`.
7. Implementar accesibilidad: `Semantics`, `ExcludeSemantics`, contraste, tamaños de texto dinámicos.

---

## 🧪 Fase 8: Pruebas y Optimización
1. **Pruebas unitarias:** Lógica de providers, validación de formularios, mapeo de modelos, servicios mock.
2. **Pruebas de widgets:** Componentes reutilizables, estados de carga/error, navegación básica.
3. **Pruebas de integración:** Flujos completos (registro → login → agregar al carrito → crear pedido).
4. **Rendimiento:**
   - Reducir rebuilds innecesarios (`Selector`, `context.watch` vs `context.read`)
   - Lazy loading de listas (`ListView.builder`, paginación)
   - Perfilado con Flutter DevTools (CPU, memoria, red)
5. **Seguridad:** Validar reglas de Firestore, sanitizar inputs, no exponer claves.
6. Preparar para localización (`intl`, archivos `.arb`) si se planea multilenguaje.

---

## 🚀 Fase 9: Despliegue y Mantenimiento
1. Configurar metadatos de app: nombre, paquete, versión, iconos, splash, permisos.
2. Generar builds de release:
   - Android: `flutter build appbundle`
   - iOS: `flutter build ipa`
   - Web: `flutter build web`
3. Firmar aplicaciones, generar keystores/certificados, configurar almacenes (Play Console, App Store Connect).
4. Integrar Firebase Crashlytics y Analytics para monitoreo post-lanzamiento.
5. Establecer pipeline CI/CD básico (GitHub Actions, Codemagic o Fastlane) opcional.
6. Plan de actualizaciones: backlog, hotfixes, feedback de usuarios, métricas de retención.

---

## 📦 Dependencias Requeridas (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  
  # Firebase
  firebase_core: ^3.x.x
  firebase_auth: ^5.x.x
  cloud_firestore: ^5.x.x
  firebase_storage: ^12.x.x  # si se suben imágenes
  firebase_analytics: ^11.x.x
  firebase_crashlytics: ^4.x.x

  # Estado y Navegación
  provider: ^6.x.x
  go_router: ^14.x.x  # o auto_route

  # UI y Utilidades
  cached_network_image: ^3.x.x
  intl: ^0.19.x
  flutter_native_splash: ^2.x.x
  flutter_launcher_icons: ^0.14.x
  google_fonts: ^2.x.x  # si se usan fuentes externas
  shimmer: ^3.x.x  # placeholders de carga

  # Formularios y Validación (opcional)
  flutter_form_builder: ^9.x.x
  formz: ^0.7.x  # validaciones type-safe

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.x.x
  build_runner: ^2.x.x
  flutter_lints: ^4.x.x
```
> ⚠️ Actualiza las versiones a las más estables al momento de desarrollo. Usa `flutter pub get` y verifica compatibilidad con tu versión de Flutter.

---

## 🧰 Herramientas Recomendadas
| Categoría        | Herramienta(s)                          |
|------------------|------------------------------------------|
| IDE              | VS Code + Extensiones Flutter/Dart       |
| Diseño UI/UX     | Figma, Adobe XD, Penpot                  |
| Control de versiones | Git, GitHub/GitLab                  |
| Backend/DB       | Firebase Console, Firebase Emulators     |
| Debug/Perf       | Flutter DevTools, Chrome DevTools        |
| CI/CD            | GitHub Actions, Codemagic, Fastlane      |
| Gestión de tareas | Jira, Trello, Notion, Linear           |

---

## 📌 Buenas Prácticas y Notas Clave
- 🔒 **Seguridad primero:** Nunca exponer claves de API, validar entradas en cliente y servidor, aplicar reglas estrictas en Firestore.
- 🧱 **Arquitectura escalable:** Separar responsabilidades, evitar lógica en widgets, usar repositorios para acceso a datos.
- 🔄 **Provider bien usado:** `context.watch` solo en UI que necesita rebuild, `context.read` para acciones únicas, `Selector` para optimizar.
- 📱 **Experiencia de usuario:** Feedback inmediato en acciones, manejo elegante de errores offline, indicadores de progreso claros.
- 📊 **Métricas desde el inicio:** Crashlytics, Analytics, logs estructurados para diagnóstico rápido.
- 📝 **Documentación:** README con pasos de setup, decisiones de arquitectura, guía de contribución, diagramas de flujo si es necesario.

---

✅ **Siguiente paso:** Una vez valides y ajustes este plan a tus necesidades, puedo generar la estructura de carpetas, configuración de `pubspec.yaml`, o el código paso a paso de cualquier fase (autenticación, Firestore, Provider, UI, etc.). ¿Deseas que profundice en alguna fase específica antes de continuar?
