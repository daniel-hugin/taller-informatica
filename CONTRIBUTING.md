# Contribuir

Este taller mejora sobre todo con experiencia de campo, no con código.

## Lo más útil que puedes aportar

**Notas de campo.** Ejecutaste una actividad y pasó algo. Duró la mitad de lo
previsto. Se atascaron en un sitio que no está documentado. Una frase de arranque
no funcionó y otra sí. Abre un issue o un PR añadiendo a la sección
*Notas de campo* de la ficha correspondiente.

Esto vale más que una actividad nueva, porque es lo que convierte una ficha en
conocimiento en vez de en una intención.

## Actividades nuevas

1. Copia `actividades/PLANTILLA.md` a `actividades/<tramo>/<NN>-<nombre>/README.md`
2. Rellena **todas** las secciones. Si no puedes rellenar *Dónde se atascan*,
   probablemente no la has ejecutado todavía
3. Márcala `borrador` hasta haberla hecho con un niño real
4. Numérala según su posición en la secuencia, no por orden de llegada

**Una actividad no se marca `probado` sin ejecución real.** Es la única regla
innegociable del repositorio y lo que lo diferencia de cualquier lista de
software educativo.

## Scripts

- `set -euo pipefail` en cabecera
- **Idempotencia obligatoria.** Comprobar antes de actuar. Nunca `>>` a ciegas;
  usa `linea_en_fichero`
- Todo cambio pasa por `ejecuta`, para que `--dry-run` funcione
- Nada de configuración incrustada: va en `config/`
- `./probar.sh` en verde antes del PR

Se prefiere bash legible sobre bash elegante. El público objetivo son docentes
que necesitan poder leer lo que van a ejecutar en el ordenador de sus alumnos.

## Traducciones

El taller está en castellano. Las traducciones son bienvenidas como directorios
paralelos (`actividades/en/`, etc.). Las frases de arranque **no se traducen
literalmente**: se reescriben para que funcionen con niños de esa lengua.

## Qué no encaja aquí

- Gamificación: rachas, puntos, insignias, notificaciones
- Cualquier forma de monitorización del niño
- Telemetría, analítica, o envío de datos fuera del equipo
- Dependencias de servicios en la nube o cuentas de terceros
