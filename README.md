# Optimizador para jugar (PowerShell)

Deja el PC liviano antes de abrir un juego **con un solo clic**, y después devuelve todo a la normalidad. Cierra de forma ordenada las aplicaciones que consumen recursos en segundo plano, cambia el plan de energía a **Alto rendimiento**, mide cuánta memoria RAM se liberó y guarda qué cerró para poder **restaurarlo** cuando termines de jugar.

Pensado para Windows, en Windows PowerShell 5.1 (el que trae Windows) o PowerShell 7. No necesita instalar nada.

---

## Tabla de contenidos
- [Para qué sirve](#para-qué-sirve)
- [Qué hace, paso a paso](#qué-hace-paso-a-paso)
- [Instalación](#instalación)
- [Uso](#uso)
- [Cómo deshacer los cambios (Restaurar)](#cómo-deshacer-los-cambios-restaurar)
- [Configuración (Config.psd1)](#configuración-configpsd1)
- [Cómo saber el nombre de un proceso](#cómo-saber-el-nombre-de-un-proceso)
- [Seguridad: qué NO toca nunca](#seguridad-qué-no-toca-nunca)
- [Cómo funciona por dentro](#cómo-funciona-por-dentro)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Preguntas frecuentes y problemas](#preguntas-frecuentes-y-problemas)
- [Conceptos aplicados](#conceptos-aplicados)
- [Aviso](#aviso)

---

## Para qué sirve

Cuando vas a jugar, muchos programas siguen corriendo en segundo plano y se comen la RAM y el CPU: Discord, Spotify, el navegador con 20 pestañas, OneDrive sincronizando, los launchers de Epic o Battle.net, Teams, etc. Este script los cierra de una, deja el equipo con más memoria libre y lo pone en modo de máximo rendimiento. Cuando terminas, un segundo clic vuelve a abrir todo y devuelve la configuración como estaba.

Todo es **reversible**: el script anota qué cerró y en qué plan de energía estaba tu PC, así que no es un cambio de ida sin vuelta.

---

## Qué hace, paso a paso

1. **Mide la RAM libre** antes de empezar (y el total del equipo).
2. **Muestra los 8 programas** que más memoria están usando en ese momento, para que veas de dónde viene el consumo.
3. **Cierra las aplicaciones** de la lista `AppsACerrar`:
   - Primero les pide cerrarse de forma ordenada (como si apretaras la X).
   - Si en ~0,7 s no responden, las fuerza.
   - Guarda la ruta del programa para poder reabrirlo después.
4. **Cambia el plan de energía** a *Alto rendimiento* (si está activado en el Config).
5. **Guarda el estado** (qué cerró + plan anterior) en `datos\Estado.json`.
6. **Vuelve a medir la RAM** y te dice cuánta se liberó.
7. Te recuerda que, al terminar de jugar, uses **Restaurar.cmd**.

Ejemplo de lo que verás:

```
RAM libre antes: 3120 MB de 16312 MB (en uso: 81%)

Lo que mas memoria usa ahora:
  chrome                         1840 MB
  Discord                         540 MB
  Spotify                         310 MB
  ...

  Cerre Discord
  Cerre Spotify
  Cerre OneDrive
  (protegido, no se cierra) steam

Plan de energia: Alto rendimiento
RAM libre despues: 5460 MB  (liberada: +2340 MB)
Listo: cerre 3 aplicacion(es). Ya puedes abrir tu juego.
```

---

## Instalación

No hay instalación. Solo necesitas la carpeta con estos archivos. Windows ya trae PowerShell.

1. Descarga o clona el repositorio.
2. Abre la carpeta.
3. Doble clic en `Optimizar.cmd`.

> Si Windows muestra "Windows protegió tu PC" (SmartScreen) la primera vez, es porque el `.cmd` no está firmado. Haz clic en **Más información → Ejecutar de todas formas**. Puedes revisar el contenido: son archivos de texto que puedes abrir con el Bloc de notas.

---

## Uso

| Acción | Qué hace |
| --- | --- |
| Doble clic en **`Optimizar.cmd`** | Deja el PC liviano y te dice cuánta RAM liberó. |
| Doble clic en **`Restaurar.cmd`** | Reabre lo que cerró y devuelve el plan de energía. |
| **`Optimizar.cmd navegadores`** (desde la consola) | Además cierra los navegadores en esa corrida. |

También por línea de comandos (PowerShell):

```powershell
.\Optimizar.ps1                    # optimiza
.\Optimizar.ps1 -CerrarNavegadores # optimiza y además cierra navegadores
.\Optimizar.ps1 -Restaurar         # restaura
.\Optimizar.ps1 -SinPausa          # no espera un Enter al final (para tareas programadas)
```

---

## Cómo deshacer los cambios (Restaurar)

Cuando cierres el juego, haz doble clic en **`Restaurar.cmd`**. Eso:

- Vuelve a abrir cada aplicación que se había cerrado (usando la ruta que guardó).
- Devuelve el plan de energía al que tenías antes.
- Borra el archivo de estado.

**Importante sobre las pestañas:** restaurar reabre los programas, pero no puede recuperar las pestañas exactas del navegador. Por eso el cierre de navegadores está desactivado por defecto; si lo activas, guarda tu sesión o usa "restaurar pestañas" del propio navegador.

---

## Configuración (`Config.psd1`)

Ábrelo con el Bloc de notas. Es texto plano.

| Opción | Qué controla |
| --- | --- |
| **`AppsACerrar`** | Lista de programas a cerrar, por nombre de proceso **sin `.exe`**. Agrega o quita a tu gusto. |
| **`CerrarNavegadores`** | `$true` cierra siempre los navegadores (pierdes pestañas). Por defecto `$false`. |
| **`Navegadores`** | Qué cuenta como navegador (chrome, msedge, firefox, opera, opera_gx, brave, vivaldi). |
| **`CambiarPlanEnergia`** | `$true` cambia a Alto rendimiento mientras juegas. Restaurar lo devuelve. |
| **`MostrarTopConsumo`** | `$true` muestra los 8 programas que más RAM usan antes de cerrar nada. |
| **`NoCerrarJamas`** | Procesos que **nunca** se tocan, aunque los pongas en `AppsACerrar`. |

Ejemplo para agregar un programa propio (por ejemplo el launcher de Riot):

```powershell
AppsACerrar = @(
    'Discord', 'Spotify', 'OneDrive',
    'RiotClientServices'   # <- agregado por ti
)
```

---

## Cómo saber el nombre de un proceso

1. Abre el **Administrador de tareas** (Ctrl + Shift + Esc).
2. Ve a la pestaña **Detalles**.
3. En la columna *Nombre* verás algo como `Discord.exe`. El nombre que va en `AppsACerrar` es **sin `.exe`**: `Discord`.

Un mismo programa puede tener varios procesos con el mismo nombre; el script los cierra todos.

---

## Seguridad: qué NO toca nunca

El script tiene una lista de protección (`NoCerrarJamas`) que se respeta **aunque alguien agregue esos nombres a la lista de cerrar**. Incluye:

- Procesos esenciales de Windows: `explorer`, `dwm`, `csrss`, `winlogon`, `services`, `lsass`, `svchost`, `System`, etc.
- **Steam** y `steamwebhelper`, para que puedas abrir tus juegos.
- La propia consola de PowerShell.
- El antivirus de Windows: `MsMpEng`, `SecurityHealthService`, `NisSrv`.

El script **no** desactiva el antivirus, el firewall, ni cambia configuraciones de seguridad. Solo cierra aplicaciones de usuario y cambia el plan de energía (algo que puedes hacer a mano desde el Panel de control).

---

## Cómo funciona por dentro

- **Medir RAM:** usa `Get-CimInstance Win32_OperatingSystem` (`FreePhysicalMemory`, `TotalVisibleMemorySize`).
- **Top de consumo:** `Get-Process` ordenado por `WorkingSet64`.
- **Cerrar ordenado:** `CloseMainWindow()` y, si el proceso sigue vivo, `Stop-Process -Force`.
- **Plan de energía:** `powercfg /getactivescheme` para leer el actual y `powercfg /setactive` para cambiarlo. El GUID de Alto rendimiento es `8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c`.
- **Estado para restaurar:** se guarda en JSON (`datos\Estado.json`) con la fecha, el plan anterior y la lista de apps cerradas con su ruta.
- **Registro:** cada corrida escribe en `Optimizador.log`.

---

## Estructura del proyecto

```
OptimizadorJuegos/
├─ Optimizar.ps1      # script principal
├─ Optimizar.cmd      # lanzador: doble clic para optimizar
├─ Restaurar.cmd      # lanzador: doble clic para restaurar
├─ Config.psd1        # lista de apps y opciones (editable)
├─ README.md
├─ .gitignore
└─ datos/             # se crea solo: Estado.json (no se sube)
```

---

## Preguntas frecuentes y problemas

**No liberó mucha RAM.** Depende de lo que tengas abierto. Si el que más consume es el navegador, actívalo con `Optimizar.cmd navegadores` o cierra las pestañas tú.

**Cerró algo que no quería.** Quítalo de `AppsACerrar` en `Config.psd1`. Mientras tanto, `Restaurar.cmd` lo vuelve a abrir.

**No cambió el plan de energía.** Algunos equipos (sobre todo notebooks con planes del fabricante) no tienen "Alto rendimiento". En ese caso el script lo avisa y deja el plan actual, sin romper nada.

**Restaurar no reabrió un programa.** Si el proceso no entregaba su ruta (permisos), el script lo dice y lo abres tú. Es poco común.

**Quiero que corra solo.** Puedes crear una tarea en el Programador de tareas que ejecute `powershell -File Optimizar.ps1 -SinPausa`, aunque normalmente conviene lanzarlo a mano justo antes de jugar.

---

## Conceptos aplicados

Gestión de procesos en Windows, consultas WMI/CIM, manejo seguro con lista de exclusión de procesos críticos, persistencia de estado en JSON para operaciones reversibles, planes de energía con `powercfg` y lanzadores `.cmd`.

---

## Aviso

Úsalo solo en tu propio equipo. Cerrar aplicaciones puede hacerte perder cambios sin guardar (documentos, pestañas); guarda tu trabajo antes de optimizar.
