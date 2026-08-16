# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A five-year curriculum + provisioning system to turn recycled Debian laptops
into a computing workshop for 7-8 year olds, growing with them toward writing
their own programs. Two halves: **scripts** that provision the Debian machine
idempotently, and **actividades** (activity cards) sequenced by age. Per the
project's own README, the activities are the important half — anyone can
`apt install gcompris`; the value is knowing what comes next, where kids get
stuck, and what to do about it.

Everything is in Spanish (code comments, variable/function names, docs,
commit-worthy prose). Keep new code and docs in Spanish to match.

## Current state — read this before running anything

The repo is at **Fase 0 (montaje)**: designed but not yet executed with real
kids, and the on-disk layout does not yet match what the docs and scripts
assume. `install.sh`, `probar.sh`, and `taller-informatica.md` all reference a
structure that doesn't exist in this checkout yet:

```
lib/comun.sh          scripts/NN-*.sh        config/taller.conf
config/paquetes-*.txt skel/ (+ skel-etc/)    actividades/<tramo>/<n>/README.md
plantillas/           docs/
```

What actually exists right now is a flat set of files at repo root that
correspond to pieces of that eventual tree:

| File at root now | Destined path |
|---|---|
| `comun.sh` | `lib/comun.sh` |
| `sistema.sh` | `scripts/05-sistema.sh` (see its own header comment) |
| `xsettings.xml` | somewhere under `skel/` (XFCE xsettings channel) |
| `instalacion-debian.md` | `docs/INSTALACION-DEBIAN.md` |
| `pruebas-vm.md` | `docs/PRUEBAS-VM.md` |
| `taller-informatica.md` | the project README |

Because of this, **`install.sh` and `probar.sh` will fail as-is** — `comun.sh`
sources `config/taller.conf`, which does not exist, and `install.sh` looks for
modules under `scripts/`, which also does not exist. Before running either,
check whether the expected directories have been created; don't assume a
failure is a bug in the script itself without first checking whether the
surrounding scaffolding (`config/taller.conf`, `scripts/`, `lib/`) is actually
in place.

## Commands

```bash
./probar.sh                 # static validation: no root, no Debian needed
./probar.sh --vm            # same, plus a clean-container dry-run (needs podman or docker)

sudo ./install.sh --dry-run # show what would happen, touches nothing
sudo ./install.sh           # apply all modules
sudo ./install.sh --lista   # list available modules (scripts/[0-9][0-9]-*.sh)
sudo ./install.sh 20-usuarios   # run a single module by name
```

There is no separate unit test suite — `probar.sh` *is* the test suite. It
checks: bash syntax (`bash -n`) on every script, `shellcheck` if installed,
that package lists are non-empty, that XML under `skel/` parses, that every
activity card under `actividades/**/README.md` has the required sections
(`## Objetivo`, `## Cómo arrancar`, `## Dónde se atascan`, `## Señal de que lo
tienen`) and counts how many are marked `` `probado` ``, and finally a real
`install.sh --dry-run` pass. To exercise a single check, read the relevant
`titulo "..."` block in `probar.sh` and run its commands directly.

## Architecture

**`install.sh` is the orchestrator.** It sources `lib/comun.sh`, then finds
`scripts/[0-9][0-9]-*.sh` and **sources** each one in numeric order (not
`exec`s — modules share the parent shell's environment and the helper
functions from `comun.sh`). The two-digit prefix is the execution order and
matters: e.g. `05-sistema` must run before `10-paquetes` because it enables
apt components (`contrib`, `non-free-firmware`) that later package installs
depend on. `apt-get update` is run once up front by the orchestrator, not per
module.

**Idempotency is the central contract**, not a nice-to-have. Every module must
leave the system unchanged on a second run. This is enforced structurally:
all state-mutating commands must go through `ejecuta()` in `lib/comun.sh`,
which is the single point that respects `DRY_RUN` — this is what makes
`--dry-run` uniformly correct across every module without each one
special-casing it. When adding to a module, never call `apt-get`, `sed -i`,
`mkdir`, etc. directly — use the helpers below (or wrap new mutations in
`ejecuta`) so dry-run and re-run safety keep working.

**`lib/comun.sh` helper vocabulary** (all idempotent, all dry-run aware):
- `ejecuta <cmd...>` — the only path mutations should take
- `info` / `ok` / `salta` / `avisa` / `muere` — leveled output (blue/green/gray/amber/red); `muere` exits 1
- `requiere_root`, `requiere_debian` — preconditions checked once in `install.sh`
- `lee_lista`, `paquete_instalado`, `paquete_existe`, `instala_lista` — package installs that skip what's present and warn (not fail) on package names that don't exist in the current Debian version, so one renamed package can't abort the whole run
- `linea_en_fichero`, `copia_si_distinto`, `crea_directorio` — idempotent file/line/directory operations, all check current state before touching anything
- `usuario_existe`, `grupo_existe`, `crea_usuario_nino` — kid accounts are created passwordless (by design — see comment in `comun.sh`) and added to the `taller` group; sudo comes later in a separate phase

**Configuration lives in data, not code**: `config/taller.conf` (sourced by
`comun.sh`) and `config/paquetes-*.txt` (package lists, `#`-comments and
blank lines ignored, read via `lee_lista`). Adapting the workshop to a
different setup should mean editing `config/`, not the scripts.
`config/taller.conf` is gitignored — it can hold real children's names and
backup destinations. `config/taller.ejemplo.conf` is the tracked template;
`comun.sh` fails fast with a pointer to it if `config/taller.conf` is
missing, and `probar.sh` skips the install dry-run (rather than failing) in
that case.

**`sistema.sh` (→ `scripts/05-sistema.sh`)** is representative of what a
module looks like: handles both the deb822 (`debian.sources`) and classic
(`sources.list`) apt formats, detects hardware via `lspci` rather than
assuming a ThinkPad T430 (so the repo still works on other machines), sets
locale/timezone/keyboard from `config/taller.conf` variables
(`LOCALE_TALLER`, `ZONA_HORARIA`), and ends with checks that only warn and
never mutate (separate `/home` partition, UEFI vs BIOS, RAM, free disk space,
SMART health) — mutating vs. advisory logic within a module is intentionally
separated this way.

**Hardware/software assumptions baked into the design**: Debian stable
(currently "trixie"), XFCE desktop with oversized fonts/icons/cursor for
young readers (`xsettings.xml`: `Sans 14`, 120 DPI, 48px cursor — destined
for `skel/`), `/home` on its own partition (treated as a near-hard
requirement, not a suggestion, because multi-year continuity across Debian
upgrades is a project goal), and no telemetry/cloud/accounts anywhere.

**Licensing split** (once `LICENSE`/`LICENSE-CONTENT` exist): code
(`install.sh`, `probar.sh`, `lib/`, `scripts/`) is MIT; content
(`actividades/`, `plantillas/`, `docs/`) is CC BY-SA 4.0. Keep that
distinction in mind when adding files — which license applies depends on
which side of the split a new file lands on.

**Activity cards** (`actividades/<tramo-de-edad>/<n>-*/README.md`) are numbered
within each age bracket because sequence order is itself pedagogical content;
don't alphabetize or renumber casually. Required sections are enforced by
`probar.sh`: `## Objetivo`, `## Cómo arrancar`, `## Dónde se atascan`, `##
Señal de que lo tienen`. A card is only marked `` `probado` `` after it has
actually been run with a real child — don't mark or unmark that tag without
that having happened.
