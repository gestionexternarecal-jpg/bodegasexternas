/// Indice del NavigationRail segun ruta.
int shellRailIndexForPath(String path) {
  if (path.startsWith('/warehouse')) return 2;
  if (path == '/create-transfer' ||
      path == '/transfer/new' ||
      path == '/transfers/create') {
    return 1;
  }
  return 0;
}
