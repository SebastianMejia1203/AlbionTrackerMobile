# Albion Tracker Mobile

App móvil Flutter para visualizar en tiempo real las estadísticas capturadas por SAT (AlbionOnline Statistics Analysis Tool) en PC.

## Estado Del Proyecto

- Plataforma principal: Android
- Idiomas UI: Español e Inglés
- Integraciones de anuncios: Deshabilitadas
- Integraciones Firebase: Deshabilitadas
- Función Party compartida (cloud): No disponible en esta versión

## Características

- Dashboard de sesión (fama, plata, progresión, KPIs)
- DPS meter (daño, DPS, curación, HPS)
- Historial de dungeons
- Historial de trades
- Gathering stats
- Party local (datos SAT)
- Guild, logging e historial de mapas
- Tema claro/oscuro
- Persistencia de IP/puerto de conexión

## Requisitos

- Flutter SDK compatible con Dart `>=3.2.0 <4.0.0`
- Android Studio o VS Code con toolchain Flutter
- Dispositivo Android o emulador
- SAT ejecutándose en PC dentro de la misma red local

## Instalación

1. Clona el repositorio.
2. Instala dependencias:

```bash
flutter pub get
```

3. Ejecuta la app:

```bash
flutter run
```

4. Para validar el proyecto:

```bash
flutter analyze
```

## Flujo De Uso

1. Abre la app.
2. Conéctate al host SAT por detección automática o modo manual.
3. Navega por tabs para ver métricas en tiempo real.
4. Ajusta filtros/opciones desde Ajustes y Logging.

## Estructura Del Proyecto

```text
lib/
	models/        # Modelos de datos
	providers/     # Estado global y lógica de presentación
	screens/       # Pantallas principales y tabs
	services/      # Servicios de red y acceso a SAT
	theme/         # Tema visual
	utils/         # Helpers y formateadores
	widgets/       # Componentes reutilizables
```

## Configuración

- La app está preparada para conexión local con SAT.
- No requiere claves de Firebase o AdMob.
- La política de privacidad se mantiene en `privacy_policy.html`.

## Solución De Problemas

- No conecta al host:
	- Verifica que PC y móvil estén en la misma red.
	- Confirma IP/puerto del servidor SAT.
	- Revisa firewall en PC.

- No llegan datos:
	- Confirma que SAT esté recibiendo eventos del juego.
	- Prueba refrescar desde Dashboard/Logging.

- Build falla en Android:
	- Ejecuta `flutter clean` y luego `flutter pub get`.
	- Reintenta con `flutter run`.

## Privacidad

- No se recopilan datos personales.
- No hay sincronización cloud activa en esta versión.
- No hay anuncios activos en esta versión.

## Contribución

Si vas a contribuir:

1. Crea una rama de feature.
2. Mantén estilo y arquitectura actual (providers + servicios).
3. Ejecuta análisis antes de abrir PR.

## Licencia

Proyecto privado. Todos los derechos reservados.
