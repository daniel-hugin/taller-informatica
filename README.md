# Taller de informática

Itinerario de cinco años para acompañar a niños de 7-8 años desde la
navegación básica de un ordenador hasta escribir sus propios programas,
sobre hardware reciclado y software libre.

Este repositorio contiene dos cosas: los **scripts** que preparan una Debian
para el taller, y las **actividades** secuenciadas por edad. Las actividades
incluen detalles sobre acciones a llevar a cabo conforme al avance del niño,dónde se atascan y qué hacer cuando pasa.

## Estado

**Fase 0 — montaje.** El itinerario está diseñado pero no ejecutado. Las
fichas marcadas `borrador` no se han probado todavía con niños reales.
Ver `docs/` para el documento de diseño completo.

## Instalación

**¿Aún no tienes Debian instalada?** Empieza por
[`docs/INSTALACION-DEBIAN.md`](docs/INSTALACION-DEBIAN.md): descarga de la ISO,
particionado (con `/home` separado, que aquí no es opcional) y opciones del
instalador.

Sobre una Debian estable recién instalada:

```bash
git clone <url> taller-informatica
cd taller-informatica
cp config/taller.ejemplo.conf config/taller.conf   # tu copia local, no se versiona
$EDITOR config/taller.conf                          # nombres de los niños, rutas
sudo ./install.sh --dry-run                       # ver qué haría
sudo ./install.sh                                 # aplicarlo
```

**Todos los módulos son idempotentes.** Ejecutarlos cien veces deja el sistema
igual que ejecutarlos una vez. Ese es el modo previsto de trabajo: cuando
quieras añadir un tramo de edad, edita `config/taller.conf` y relanza.

```bash
sudo ./install.sh --lista        # módulos disponibles
sudo ./install.sh 20-usuarios    # solo uno
./probar.sh                      # validar el repo sin tocar nada
./probar.sh --vm                 # además, sobre una Debian limpia en contenedor
```

Para probar el ciclo completo antes de tocar la máquina de los niños, ver
[`docs/PRUEBAS-VM.md`](docs/PRUEBAS-VM.md). La VM con snapshots es el único sitio
donde se puede verificar de verdad que reejecutar no rompe nada.

## Estructura

```
install.sh          orquestador
probar.sh           validación (sintaxis, fichas, simulación, contenedor)
lib/comun.sh        helpers idempotentes y dry-run
scripts/            módulos numerados, se ejecutan en orden
config/             listas de paquetes y taller.conf  <- edita aquí
skel/               configuración de XFCE, se despliega a /etc/skel
skel-etc/           configuración del gestor de sesión, se despliega a /etc
actividades/        fichas por tramo de edad
plantillas/         bitácora imprimible, registro de tres columnas
docs/               diseño del proyecto y marco metodológico
```

La configuración vive en ficheros de datos, no dentro de los scripts. Para
adaptar el taller a otro caso deberías poder editar `config/` sin tocar bash.

## Actividades

Numeradas dentro de cada tramo: cada ficha responde a lo que un docente necesita y que no incluye la documentación de las herramientas: prerrequisito, duración real,
cómo arrancar (frases literales), dónde se atascan, qué hacer cuando pasa,
señal de que lo tienen, y variantes si se aburren o van rápido.

Muchas incluyen una sección **Fuera de la pantalla**: el paso corporal previo.
A los 7-8 años el cuerpo es donde se entiende el algoritmo; la pantalla solo lo
transcribe.

### Regla del repositorio

> Una actividad no se marca como `probado` hasta que se ha ejecutado al menos
> una vez con un niño real.

## Principios de diseño

- **Creación abierta por encima de catálogos.** Tux Paint no se acaba nunca;
  las actividades de GCompris apropiadas para 7-8 años se agotan en dos meses
  a media hora diaria.
- **Fricción cero.** Con sesiones de 30 minutos, 90 segundos de arranque son el
  5% del tiempo útil y el momento exacto de la distracción. Suspender, no apagar.
- **Sin mecánicas de refuerzo variable.** Nada de rachas, insignias ni puntos.
  La racha *es* la tragaperras, y enseña que la razón para programar es no
  romper un contador.
- **Lo que fabrican tiene que salir de la pantalla.** Impreso, jugado por otro,
  escuchado en el coche. Es la única ventaja estructural frente al scroll.
- **Sin recogida de datos.** Todo local. Sin cuentas, sin nube, sin telemetría.
  El respaldo al homelab es opcional y está desactivado por defecto.

## Hardware de referencia

Lenovo ThinkPad T430, 16 GB RAM, SSD + HDD. Nada de esto es obligatorio: los
scripts funcionan sobre cualquier Debian. El T430 aporta algo que sí importa —
se abre con un destornillador y tiene manual de servicio con despiece, así que
es material didáctico además de máquina.

Si tienes segundo disco: SSD para sistema y `/home`, HDD para Kiwix, archivo
histórico e imágenes de VM. El archivo vive en un soporte físico distinto a
propósito, para que una reinstalación no pueda tocarlo.

## Contribuir

Ver `CONTRIBUTING.md`. Se agradecen especialmente las **notas de campo**: qué
pasó de verdad al ejecutar una actividad, incluido lo que falló.

## Licencias

- **Código** (`install.sh`, `probar.sh`, `lib/`, `scripts/`): MIT — ver `LICENSE`
- **Contenido** (`actividades/`, `plantillas/`, `docs/`): CC BY-SA 4.0 — ver
  `LICENSE-CONTENT`

Adaptar y redistribuir las actividades está expresamente permitido, con
atribución y compartiendo bajo la misma licencia.
