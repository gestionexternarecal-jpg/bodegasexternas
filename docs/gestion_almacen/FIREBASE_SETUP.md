# Configuración Firebase (Windows)

## Requisitos

- Proyecto Firebase con **Firestore** habilitado.
- Flutter SDK 3.11+ (ya en el proyecto).
- **CMake 3.14+** (Visual Studio). El SDK Firebase C++ declara `cmake_minimum_required(3.1)` y CMake 4.x muestra *Deprecation Warning* (&lt; 3.10). El proyecto fija `CMAKE_POLICY_VERSION_MINIMUM 3.10` en `windows/CMakeLists.txt`. Si la advertencia sigue en el **primer** build, ejecuta `.\tool\patch_firebase_cmake.ps1` y vuelve a compilar (o haz un segundo `flutter build windows`).

## Pasos

```powershell
cd "d:\Desarollo de software\PC\Bodegas XT"
dart pub global activate flutterfire_cli
flutterfire configure
```

Selecciona el proyecto y la plataforma **windows** (y web si aplica).

Esto genera `lib/firebase_options.dart`.

## Activar en la app

1. `lib/core/constants/app_constants.dart` → `useFirebase = true`
2. `lib/core/firebase/firebase_bootstrap.dart` → descomentar `Firebase.initializeApp`
3. `lib/features/warehouse/presentation/providers/warehouse_providers.dart` → cambiar el provider a `FirestoreFirebaseBinRepository` (instrucciones en el archivo).

## Seguridad

- No subir claves privadas al repositorio.
- Ajustar `firebase/firestore.rules` antes de producción (plantilla incluida en modo desarrollo restrictivo).

## Sin Firebase

Con `useFirebase = false` (por defecto) la app compila y usa almacenamiento en memoria para desarrollar UI y validaciones.
