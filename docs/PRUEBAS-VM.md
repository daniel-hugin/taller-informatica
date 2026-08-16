# Probar el taller en una máquina virtual

La VM no es solo comodidad: **es el único sitio donde puedes probar la
idempotencia de verdad**. En la máquina real solo ejecutas el script una primera
vez; el segundo intento ya parte de un sistema modificado. Con snapshots vuelves
al estado virgen en segundos y compruebas que la primera pasada y la quinta
dejan el sistema igual.

## Preparar el anfitrión

```bash
# Si devuelve 0, activa VT-x en la BIOS (Security > Virtualization)
grep -Ec '(vmx|svm)' /proc/cpuinfo

sudo apt install -y qemu-system-x86 libvirt-daemon-system virt-manager virtinst
sudo usermod -aG libvirt,kvm "$USER"
newgrp libvirt
```

## Crear la VM

```bash
virt-install \
  --name taller-pruebas \
  --memory 4096 \
  --vcpus 2 \
  --disk size=25,format=qcow2 \
  --cdrom ~/Descargas/debian-13.6.0-amd64-netinst.iso \
  --os-variant debian13 \
  --graphics spice \
  --network network=default
```

4 GB y 25 GB bastan. No repliques los 16 GB del anfitrión: quieres iterar rápido,
no ser fiel al hardware final.

Instala Debian siguiendo `INSTALACION-DEBIAN.md`: mínima, sin escritorio, con
`/home` en partición separada (aquí también, para que la comprobación de
`05-sistema` se valide de verdad).

## El snapshot base

**Antes de clonar el repositorio:**

```bash
virsh snapshot-create-as taller-pruebas base "Debian recién instalada, sin taller"
virsh snapshot-list taller-pruebas
```

Ese snapshot es tu suelo. Para volver a él:

```bash
virsh snapshot-revert taller-pruebas base
```

## Compartir el repositorio sin copiarlo

Para no hacer `scp` en cada iteración:

```bash
virt-xml taller-pruebas --add-device \
  --filesystem source=/ruta/a/taller-informatica,target=taller,driver.type=virtiofs
```

Dentro de la VM:

```bash
sudo mount -t virtiofs taller /mnt/taller
cd /mnt/taller
```

Editas en el anfitrión con tu editor de siempre, ejecutas en la VM al instante.

## El ciclo de prueba

```bash
# 1. Suelo limpio
virsh snapshot-revert taller-pruebas base

# 2. Revisar sin aplicar
sudo ./install.sh --dry-run

# 3. Aplicar
sudo ./install.sh

# 4. LA PRUEBA QUE IMPORTA: repetir
sudo ./install.sh
sudo ./install.sh
```

En las pasadas 4 y 5 **todo debe salir en gris** (`--`). Si algo se vuelve a
instalar, si una línea aparece duplicada en un fichero de configuración, o si un
`sed` se aplica dos veces, tienes un fallo de idempotencia. Ese es exactamente
el bug que no puedes detectar en la máquina real.

Para iterar más rápido, sáltate la actualización inicial:

```bash
OMITIR_UPGRADE=1 sudo -E ./install.sh
```

## Comprobaciones visuales

Reinicia, entra en la sesión de un niño y verifica:

- [ ] Fuente notablemente más grande de lo normal (Sans 14, DPI 120)
- [ ] Iconos de escritorio grandes (96 px)
- [ ] Panel de 48 px, con reloj legible y poco más
- [ ] Lanzador **Cambiar de niño** visible en el panel
- [ ] Cursor grande (48 px)
- [ ] Pantalla de login con fuente grande y los iconos de los dos usuarios
- [ ] Tux Paint y Turtle Blocks arrancan
- [ ] `/srv/taller` existe, con grupo `taller` y bit setgid (`ls -ld /srv/taller` → `drwxrwsr-x`)

## Guardar una plantilla limpia

```bash
virt-clone --original taller-pruebas --name taller-base --auto-clone
```

Sobrevive aunque destroces la VM de trabajo, y te da VMs nuevas al instante
cuando quieras probar el tramo de 9-10 años sin arrastrar lo anterior.

## Lo que la VM NO valida

Tenerlo claro para no confiarse:

| No se puede probar aquí | Por qué |
|---|---|
| Suspensión al cerrar la tapa (`50-energia`) | No hay tapa |
| Spindown del HDD (`40-almacenamiento`) | El módulo se salta solo, sin `/srv/hdd` |
| Firmware WiFi / gráficos Intel (`05-sistema`) | La detección por `lspci` no encuentra hardware Intel |
| Rendimiento gráfico real | Driver virtual, no la HD 4000 |
| **La fricción real** | Los dos segundos de abrir la tapa no se miden aquí, y son el criterio de diseño central |

Todo lo demás —repositorios, paquetes, usuarios, permisos, escritorio, XML de
xfconf, idempotencia— sí se valida.

Que un módulo se salte solo en la VM **es el comportamiento correcto** y merece
la pena verlo funcionar: significa que el repositorio degrada con elegancia en
hardware que no es el de referencia, que es lo que le va a pasar a cualquier
docente que lo use.
