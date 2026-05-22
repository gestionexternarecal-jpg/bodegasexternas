# Roadmap — Gestión Almacén

## Fase 0 — Entorno (actual)

- [x] Estructura `lib/features/warehouse`
- [x] Documentación y modelo Firebase
- [x] Validador stock Odoo vs Firebase
- [x] Repositorios stub / memoria
- [x] Ruta `/warehouse` y entrada en menú
- [x] Dependencias `firebase_core`, `cloud_firestore`

## Fase 1 — Bodega y consulta Odoo

- [ ] Persistir bodega de trabajo seleccionada (`shared_preferences`)
- [ ] Pantalla stock: buscar producto, mostrar disponible Odoo + UoM
- [ ] Listar ubicaciones Firebase de esa bodega

## Fase 2 — Asignación Firebase

- [ ] CRUD ubicaciones (`bin_locations`)
- [ ] Asignar / editar cantidades (`bin_stock`) con validación en tiempo real
- [ ] Vista resumen: asignado / sin ubicar / excedente

## Fase 3 — Firestore producción

- [ ] `flutterfire configure` + `FirestoreFirebaseBinRepository`
- [ ] Reglas Firestore y sincronización offline opcional

## Fase 4 — Movimientos internos integrados

- [ ] Desde `/warehouse/transfers` abrir flujo existente con bodega preseleccionada
- [ ] Historial de movimientos filtrado por bodega

## Fase 5 — Reportes

- [ ] Exportar mapa de ubicaciones vs stock
- [ ] Alertas productos sin ubicar o sobre-asignados
