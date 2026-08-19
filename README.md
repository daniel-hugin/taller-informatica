# Taller de informática

Itinerario de cinco años para acompañar a niños de 7-8 años desde la
navegación básica de un ordenador hasta escribir sus propios programas,
sobre hardware reciclado y software libre.

Este repositorio contiene dos cosas: los **scripts** que preparan una Debian
para el taller, y las **actividades** secuenciadas por edad. Las actividades
incluen detalles sobre acciones a llevar a cabo conforme al avance del niño,dónde se atascan y qué hacer cuando pasa.

## Estado

**Fase 0 — montaje.** El itinerario está diseñado pero no ejecutado. Las
fichas marcadas `borrador` no se han probado todavía con niños reales. Ver
la sección [Principios de diseño](#principios-de-diseño) para los criterios
que sostienen las decisiones del itinerario.

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
docs/               instalación en Debian y pruebas en VM
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

- **Progresión por tramos de edad.** Cada salto sigue el desarrollo
  cognitivo, no el calendario: a los 7-8 años, en estadio operatorio
  concreto, las herramientas trabajan sobre lo tangible (secuencias,
  luego bucles); hacia los 8-9 llegan los eventos, el paralelismo y los
  ficheros reales; hacia los 10-11, el texto y la terminal. El calendario
  orienta, no frena — si un niño pide antes lo que toca después, dáselo.
- **Turtle Blocks antes que Scratch.** A los 7-8 años el niño razona sobre
  lo tangible: puede *ser* la tortuga, caminar el cuadrado por el pasillo,
  contar los giros con el cuerpo y traducirlo después a bloques. Scratch,
  con múltiples objetos, eventos concurrentes y coordenadas, es ruido a los
  7 años pero el escalón natural a los 9. Turtle Blocks es además el
  puente: son bloques, pero generan Logo y exportan Python, así que el niño
  ve que sus bloques *son* código.
- **Creación abierta por encima de catálogos.** Tux Paint no se acaba nunca;
  las actividades de GCompris apropiadas para 7-8 años se agotan en unos dos
  meses a media hora diaria, y Blockly Games se completa en semanas. Los
  catálogos son complemento, no columna vertebral.
- **Fricción cero.** Con sesiones de 30 minutos, 90 segundos de arranque son el
  5% del tiempo útil y el momento exacto de la distracción. Suspender, no apagar.
- **Sin mecánicas de refuerzo variable.** Nada de rachas, insignias ni puntos.
  La racha *es* la tragaperras, y enseña que la razón para programar es no
  romper un contador.
- **Lo que fabrican tiene que salir de la pantalla.** Impreso, jugado por otro,
  escuchado en el coche. Es la única ventaja estructural frente al scroll: el
  scroll es consumo puro y nunca da "esto lo hice yo".
- **Sin recogida de datos.** Todo local. Sin cuentas, sin nube, sin telemetría.
  El respaldo al homelab es opcional y está desactivado por defecto.
- **Contraseña sí, pero trivial.** Las cuentas infantiles no se dejan sin
  contraseña — `adduser --disabled-password` la bloquea, no la abre, y
  LightDM rechazaría el login — así que llevan un PIN de cuatro dígitos
  configurable en `taller.conf` (`CONTRASENA_NINOS`). La contraseña de
  verdad llega en el tramo 11-12, junto con la entrega de `sudo`.

### Decisiones descartadas

| Descartado | Motivo |
|---|---|
| Sugar como sistema único | Elimina el sistema de ficheros, y navegar uno es parte del objetivo; techo pedagógico en ~10-11 años |
| NixOS para este equipo | Empaquetado de software educativo irregular fuera de Debian/Fedora; el público que adoptaría este kit no lo usa |
| ISO propio, de entrada | Coste de mantenimiento insostenible para pocas personas y menos adaptable que un repo de texto — nadie forkea una imagen, cualquiera edita un fichero |
| Gamificación con rachas | Refuerzo variable — importa el mecanismo del adversario (la racha *es* la tragaperras) |
| Reinstalar entre versiones | La continuidad *es* el objetivo; por eso `/home` va en partición aparte y sobrevive a un salto de versión mayor |
| Presentarlo como alternativa al móvil | En el momento en que es "lo que te hacen hacer en vez del teléfono", pierde: tiene que ser bueno en sus propios términos |

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
