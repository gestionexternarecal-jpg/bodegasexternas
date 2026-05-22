# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).
Versionado segun [Semantic Versioning](https://semver.org/lang/es/) y el numero de build en `pubspec.yaml` (`version: X.Y.Z+N`).

## [1.0.0] - 2026-05-22

Primera version publica de **Gestion Externa** (Bodegas XT).

### Anadido

- Login Odoo (URL, base de datos, usuario) con sesion cifrada.
- Transferencias internas: listado, detalle, confirmar, validar y escaneo de codigos.
- Creacion de transferencias internas con grilla de productos (codigo + cantidad).
- Carga masiva desde Excel.
- Modulo **Gestion Almacen** (estructura, documentacion, integracion Odoo + Firebase en memoria).
- Tema claro/oscuro, layout adaptado a pantallas de oficina y aviso de actualizaciones desde GitHub Releases.
- Instalador Windows (Inno Setup) y scripts de release.

### Mejorado

- Selector de bodega de origen: oculta *Bodega en Revision* y *Productos con Falla*; seleccion estable en el autocomplete.
- Ingreso manual: cantidad por defecto 0, aviso si queda en 0, Enter en codigo mueve el foco a cantidad.

### Corregido

- Comprobacion de actualizaciones leyendo `version.json` desde GitHub (`releases/latest/download`).
- Boton **Buscar actualizaciones** en Acerca de con mensajes claros.
