# Integracion con Odoo y CORS (Web)

## Resumen por plataforma

| Plataforma | CORS al llamar Odoo | Recomendacion |
|------------|---------------------|---------------|
| **Windows** | No aplica (app nativa) | Llamada directa a JSON-RPC / XML-RPC de Odoo |
| **Android** | No aplica (app nativa) | Llamada directa a JSON-RPC / XML-RPC de Odoo |
| **Web** | Si aplica (navegador) | Requiere proxy o configuracion en el servidor |

En **Windows y Android** el cliente HTTP de Flutter (`package:http` o `dio`) habla con Odoo sin restricciones CORS del navegador. Es la via mas simple para **Gestion Externa**.

## Por que Web tiene CORS

Flutter Web se ejecuta en el navegador. Si la app esta en `https://app.tu-dominio.com` y Odoo en `https://odoo.tu-dominio.com`, el navegador bloquea peticiones cross-origin salvo que Odoo (o un proxy) envie cabeceras `Access-Control-Allow-*` correctas.

## Opciones para habilitar Web sin bloqueos

### 1. Proxy reverso (recomendado en produccion)

Colocar nginx (o similar) delante de Odoo y de la app web bajo el **mismo origen**:

```
https://tu-dominio.com/          -> Flutter Web (build)
https://tu-dominio.com/odoo/     -> proxy_pass al servidor Odoo
```

La app llama a `/odoo/...` (mismo dominio) y nginx reenvia a Odoo. El navegador no ve cross-origin.

### 2. API intermedia (backend propio)

Un servicio Dart (shelf), Node, Python, etc. que:

- Recibe peticiones de Flutter Web (mismo dominio o CORS controlado).
- Se comunica con Odoo en el servidor (sin CORS).
- Centraliza autenticacion, logs y reglas de negocio.

Util si no puedes modificar Odoo y quieres ocultar credenciales.

### 3. CORS en Odoo / reverse proxy

Si controlas el servidor Odoo, configurar en nginx cabeceras como:

```
add_header Access-Control-Allow-Origin "https://app.tu-dominio.com";
add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
add_header Access-Control-Allow-Headers "Content-Type, Authorization";
```

Menos flexible que un proxy unificado; hay que mantener origenes permitidos.

### 4. Solo escritorio + movil (fase actual)

Priorizar **Windows + Android** y posponer Web hasta tener URL de Odoo y decision de infraestructura.

## Autenticacion Odoo (referencia)

- **JSON-RPC**: `/web/session/authenticate` y luego llamadas con cookie de sesion (mas natural en servidor/proxy).
- **API externa / API keys** (segun version y modulos instalados en Odoo).

Cuando definas el giro del negocio, conviene fijar:

- URL base de Odoo (dev / prod).
- Base de datos.
- Modulos Odoo a usar (inventario, ventas, etc.).
- Si habra usuarios solo en red local o tambien desde internet.

## Siguiente paso tecnico (cuando confirmes negocio)

1. Crear `lib/core/config/odoo_config.dart` con URL y base de datos por entorno.
2. Anadir paquete `http` o `dio` + capa `OdooClient`.
3. Probar login en Windows; despues Android.
4. Evaluar Web solo si necesitas acceso desde navegador y con proxy definido.
