# Gestión Almacén

Módulo para consultar stock en Odoo, repartirlo en **ubicaciones internas** (solo Firebase) y ejecutar **movimientos internos** reutilizando el flujo de transferencias existente.

## Regla de oro del stock

| Fuente | Rol |
|--------|-----|
| **Odoo** | Stock real y única fuente de verdad (cantidad disponible en la bodega elegida). |
| **Firebase** | Distribución por ubicación interna (ej. `101-A12`, `102-A14`). |

La suma de cantidades en Firebase **no puede superar** el disponible en Odoo para ese producto en esa bodega.

```
Odoo:     150 UND  (bodega PHSA/Casa de la moneda)
Firebase: 100 UND → 101-A12
          50 UND  → 102-A14
          ─────────
          150 UND  ✓

Inválido: 100 + 100 = 200 > 150  ✗
```

## Documentos

- [ARQUITECTURA.md](./ARQUITECTURA.md) — capas, flujos y rutas
- [MODELO_FIREBASE.md](./MODELO_FIREBASE.md) — colecciones Firestore
- [FIREBASE_SETUP.md](./FIREBASE_SETUP.md) — configurar FlutterFire
- [ROADMAP.md](./ROADMAP.md) — fases de implementación

## Código

```
lib/features/warehouse/
  domain/          # entidades y validación
  data/            # Odoo + Firebase
  presentation/    # pantallas Riverpod
```

## Activar Firebase

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com).
2. `dart pub global activate flutterfire_cli`
3. `flutterfire configure` en la raíz del proyecto.
4. En `lib/core/constants/app_constants.dart` poner `useFirebase = true`.
5. Descomentar inicialización en `lib/core/firebase/firebase_bootstrap.dart`.

Hasta entonces la app usa `InMemoryFirebaseBinRepository` (sin datos persistentes).
