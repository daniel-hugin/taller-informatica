# Instalar Debian antes del taller

Los scripts del repositorio **no instalan Debian**: la preparan una vez instalada.
Esta guía cubre el paso previo.

## 1. Descargar la imagen

**Debian 13 "trixie"** es la versión estable actual. Soporte completo hasta agosto
de 2028 y LTS hasta junio de 2030 — cinco años, que es exactamente el horizonte
del taller. No hará falta reinstalar en todo el proyecto.

Descarga desde <https://www.debian.org/download>. Para el T430 (64 bits, Ivy
Bridge) necesitas la imagen `amd64`.

**Usa la imagen netinst**, no la completa de varios GB: son unos 700 MB y descarga
lo necesario durante la instalación, así que ya instalas con paquetes al día.

Desde 2022 la imagen oficial incluye firmware no libre, así que la WiFi del T430
funciona durante la instalación sin trucos.

### Verificar la descarga

No es paranoia: es la primera lección de seguridad que podrás enseñarles dentro
de unos años, y conviene tener el hábito.

```bash
# Descarga también SHA256SUMS y SHA256SUMS.sign del mismo directorio
sha256sum -c SHA256SUMS --ignore-missing
```

## 2. Escribir el USB

```bash
# Identifica el dispositivo. COMPRUEBA DOS VECES: dd no pregunta.
lsblk

sudo dd if=debian-13.6.0-amd64-netinst.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

En Windows o macOS, [balenaEtcher](https://etcher.balena.io/) hace lo mismo sin
riesgo de equivocarse de disco.

## 3. Arrancar el T430 desde USB

1. Enciende y pulsa **F12** para el menú de arranque puntual
   (**F1** entra en la BIOS si necesitas cambiar el orden permanente)
2. Elige el USB
3. Si el equipo venía de Windows, en la BIOS: `Startup > UEFI/Legacy Boot`.
   Cualquiera de los dos modos vale, pero **anótalo**: tiene que coincidir con
   cómo particiones

## 4. Particionado — la decisión que importa

**`/home` va en partición separada.** No es opcional en este proyecto.

La continuidad *es* el taller: dentro de tres años querrás saltar a Debian 14 sin
que los niños pierdan nada de lo que hicieron a los siete. Con `/home` aparte,
esa migración no toca su trabajo. Sin ella, cada actualización mayor es una
negociación con el miedo a perderlo todo.

Esquema recomendado con SSD + HDD:

| Punto | Disco | Tamaño | Notas |
|---|---|---|---|
| `/boot/efi` | SSD | 512 MB | solo si instalas en modo UEFI |
| `/` | SSD | 30–40 GB | sistema |
| `/home` | SSD | resto del SSD | su trabajo diario, respuesta instantánea |
| `swap` | SSD | 2–4 GB | con 16 GB de RAM no se usa casi nunca |
| `/srv/hdd` | HDD | todo | Kiwix, archivo histórico, VMs |

En el instalador: **Particionado manual**. Es el único punto de la instalación
donde el modo guiado no sirve.

> **Antes de tocar el HDD, comprueba su salud.** Si es el disco original, puede
> llevar diez mil horas encima:
> ```bash
> sudo smartctl -a /dev/sdX
> ```
> Mira `Power_On_Hours`, `Reallocated_Sector_Ct` y `Current_Pending_Sector`.
> No le confíes nada que sea copia única hasta saberlo.

## 5. Opciones durante la instalación

| Pantalla | Qué elegir |
|---|---|
| Idioma / país / teclado | Español, España, es |
| Nombre de máquina | el que quieras |
| Contraseña de root | **déjala vacía** — así tu usuario entra en `sudo` automáticamente |
| Usuario | el tuyo, el del adulto. Los de los niños los crea `install.sh` |
| Réplica de red | `deb.debian.org` |
| **Selección de software** | ver abajo |

En **Selección de software**, desmarca todo excepto:

- ☑ **Utilidades estándar del sistema**
- ☐ Entorno de escritorio — **desmarcado**, lo instala `install.sh`
- ☐ Servidor SSH — opcional, cómodo si administras desde otra máquina

Dejar el escritorio sin marcar es intencionado: quieres que el repositorio sea
la única fuente de verdad sobre qué hay instalado. Si el instalador mete un
escritorio por su cuenta, el repo deja de describir la máquina real.

## 6. Después del primer arranque

```bash
sudo apt update && sudo apt full-upgrade
sudo apt install -y git

git clone https://github.com/daniel-hugin/taller-informatica
cd taller-informatica
cp config/taller.ejemplo.conf config/taller.conf   # tu copia local, no se versiona
$EDITOR config/taller.conf     # nombres de los niños, rutas, respaldo
sudo ./install.sh --dry-run    # revisa qué va a hacer
sudo ./install.sh
```

Reinicia y entra en la sesión de uno de los niños para comprobar el escritorio.

## 7. Después de instalar: contenido offline

Los `.zim` de Kiwix no vienen en el repositorio porque pesan demasiado.
Descárgalos desde <https://library.kiwix.org> a `/srv/hdd/kiwix/`:

- **Wikipedia en español** — la versión escolar ocupa pocos GB; la completa sin
  imágenes ronda los 50 GB, que en el HDD no es problema
- **Vikidia** — Wikipedia con registro infantil, muy adecuada para 7-10 años
- **Wikcionario**, colecciones de libros libres

Esto es lo que convierte el portátil en algo que se puede consultar de verdad
sin internet abierto y sin problema de filtrado.

## Notas sobre el T430

- **BIOS al día** antes de empezar. Lenovo publicó actualizaciones hasta 2018 y
  algunas corrigen problemas de suspensión
- **Batería**: cualquier batería original tiene ya trece años y no aguanta nada.
  Una de tercero ronda los 30–40 €
- **Pasta térmica**: el disipador es de acceso trivial en este modelo
- **Ratón externo obligatorio**: el TrackPoint exige presión sostenida y
  calibración fina, y a los 7 años es frustrante. Desactiva el touchpad si les
  molesta al escribir
- **Manual de servicio**: Lenovo publica el despiece completo en PDF. Vale la pena
  tenerlo a mano, y vale aún más la pena abrir el portátil delante de ellos
