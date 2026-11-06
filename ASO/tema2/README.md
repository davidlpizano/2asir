# Tema 2: Programación de tareas

## Índice

- [Tema 2: Programación de tareas](#tema-2-programación-de-tareas)
  - [Índice](#índice)
  - [1. Introducción](#1-introducción)
  - [2. Programar una tarea a una hora determinada](#2-programar-una-tarea-a-una-hora-determinada)
    - [El comando `at`](#el-comando-at)
  - [3. Programar una tarea periódicamente](#3-programar-una-tarea-periódicamente)
    - [El demonio `cron` y el comando `crontab`](#el-demonio-cron-y-el-comando-crontab)
  - [4. Programación de tareas como root](#4-programación-de-tareas-como-root)
  - [5. Aplicaciones gráficas](#5-aplicaciones-gráficas)
  - [6. Anacron](#6-anacron)
  - [7. Ejecutar aplicaciones gráficas](#7-ejecutar-aplicaciones-gráficas)
    - [7.1. Ejecutar aplicaciones gráficas con cron](#71-ejecutar-aplicaciones-gráficas-con-cron)
    - [7.2. Ejecutar aplicaciones gráficas con timers](#72-ejecutar-aplicaciones-gráficas-con-timers)
  - [8. Programación de tareas en GNOME: GNOME Schedule](#8-programación-de-tareas-en-gnome-gnome-schedule)
  - [Referencia](#referencia)

## 1. Introducción

La programación de tareas permite automatizar trabajos repetitivos, como copias
de seguridad, mantenimiento y actualizaciones.

- [`at`](#2-programar-una-tarea-a-una-hora-determinada) programa una tarea
  puntual para una fecha y hora futuras.
- [`cron`](#3-programar-una-tarea-periódicamente) ejecuta tareas con una
  periodicidad definida.
- [`anacron`](#6-anacron) ayuda a ejecutar tareas periódicas que no pudieron
  realizarse mientras el equipo estaba apagado.

## 2. Programar una tarea a una hora determinada

En Debian, instala el paquete e inicia el servicio antes de usar `at`:

```console
# apt update && apt install -y at
# systemctl enable --now atd
```

### El comando `at`

`at` recibe una fecha y hora y permite introducir los comandos que se ejecutarán
una sola vez. Al terminar de introducirlos, pulsa `Ctrl+D` para guardar el
trabajo:

```console
$ at 20:15
at> comando
at> Ctrl+D
```

También acepta expresiones relativas y fechas:

```console
$ at now + 3 minutes
$ at now + 4 days
$ at 10am tomorrow
$ at 14:30 jul 25
```

Comandos útiles para administrar los trabajos:

| Comando | Función |
| --- | --- |
| `atq` | Lista las tareas pendientes del usuario actual. Como `root`, permite consultar las de todos los usuarios. |
| `at -c ID` | Muestra los comandos de la tarea identificada. |
| `atrm ID` | Cancela una tarea pendiente. |

El acceso se puede restringir mediante `/etc/at.allow` y `/etc/at.deny`. Si
existe `at.allow`, solo los usuarios incluidos pueden usar `at`; si no existe,
se aplica la lista de denegación de `at.deny`.

## 3. Programar una tarea periódicamente

Una línea de `crontab` tiene cinco campos de tiempo, seguidos del comando que
se quiere ejecutar:

| Campo | Rango | Significado |
| --- | --- | --- |
| `m` | `0–59` | Minuto |
| `h` | `0–23` | Hora |
| `dom` | `1–31` | Día del mes |
| `mon` | `1–12` | Mes |
| `dow` | `0–6`* | Día de la semana |
| `command` | — | Comando que se ejecutará |

```cron
# m      h    dom       mon       dow         command
# minuto hora día[1-31] mes[1-12] semana[0-6] comando
* * * * * comando
```

En cron de Debian, el domingo también puede representarse con `7`. Los campos
aceptan valores separados por comas (`1,3,5`), intervalos (`1-5`) e incrementos
(`*/5`, cada cinco unidades).

Ejemplos:

```cron
# Cada minuto
* * * * * comando

# Cada cinco minutos
*/5 * * * * comando

# Todos los días a las 08:00
0 8 * * * comando

# Los viernes a las 20:30
30 20 * * 5 comando

# De lunes a viernes a las 08:00
0 8 * * 1-5 comando
```

Cuando se indican a la vez el día del mes y el día de la semana, cron puede
interpretar que basta con que coincida uno de esos campos. Conviene comprobar el
comportamiento en la documentación de la implementación instalada.

También existen abreviaturas:

| Abreviatura | Equivalencia |
| --- | --- |
| `@reboot` | Al arrancar el sistema |
| `@yearly` | `0 0 1 1 *` |
| `@monthly` | `0 0 1 * *` |
| `@weekly` | `0 0 * * 0` |
| `@daily` | `0 0 * * *` |
| `@hourly` | `0 * * * *` |

### El demonio `cron` y el comando `crontab`

`cron` es el demonio que comprueba periódicamente si hay trabajos pendientes.
Las tareas de cada usuario se editan con `crontab -e`; no se añaden directamente
al proceso:

| Comando | Función |
| --- | --- |
| `crontab -e` | Edita la tabla del usuario actual. |
| `crontab -l` | Muestra sus tareas programadas. |
| `crontab archivo` | Instala las tareas incluidas en un archivo. |
| `crontab -r` | Elimina todas las tareas del usuario actual. |

**Atención:** instalar un archivo con `crontab archivo` sustituye la tabla
actual del usuario. Antes de hacerlo, conserva las tareas existentes que quieras
mantener. `crontab -r` también es una operación destructiva: borra toda esa
tabla.

## 4. Programación de tareas como root

Además de su propia tabla, el administrador dispone del archivo
`/etc/crontab`. Sus líneas incluyen un campo adicional para indicar con qué
usuario se ejecuta el comando:

```cron
# minuto hora día-del-mes mes día-de-la-semana usuario comando
30 20 * * 5 root /etc/mantenimiento/copiasbd
30 20 * * 5 root /etc/mantenimiento/usuarios
```

`run-parts --report directorio` ejecuta los scripts válidos que contiene un
directorio. Por ejemplo, las tareas horarias del sistema suelen delegarse en
`/etc/cron.hourly`:

```cron
17 * * * * root cd / && run-parts --report /etc/cron.hourly
```

Para organizar tareas propias, se pueden guardar scripts ejecutables en un
directorio de mantenimiento y programar `run-parts` para que lo procese. En
Debian, los nombres deben ajustarse a las reglas de `run-parts`; normalmente se
usan nombres sencillos, sin extensión. Comprueba los requisitos de la
implementación instalada antes de desplegar scripts.

## 5. Aplicaciones gráficas

`at` y `cron` son herramientas de línea de comandos disponibles en GNU/Linux.
En GNOME también existen aplicaciones gráficas para crear tareas, aunque la
disponibilidad de cada aplicación depende de la distribución y su versión.

## 6. Anacron

`cron` no ejecuta una tarea si el equipo estaba apagado en el momento
programado. `anacron` está pensado para trabajos periódicos con una frecuencia
de un día o más: cuando vuelve a ejecutarse, puede detectar y ejecutar trabajos
que quedaron pendientes.

`anacron` **complementa a `cron`, no lo sustituye**:

- `cron` permite programar horas y frecuencias menores que un día.
- `anacron` no programa una hora exacta y no sirve para intervalos menores que
  un día.
- A diferencia de `cron`, normalmente no permanece ejecutándose como demonio:
  se invoca durante el inicio del sistema o desde tareas de `cron`.

La configuración se encuentra en `/etc/anacrontab`. Cada entrada tiene este
formato:

```text
periodo-en-días retraso-en-minutos identificador comando
```

Por ejemplo, una tarea diaria con cinco minutos de retraso:

```cron
1 5 mensaje-diario /usr/local/bin/cron.saludos
```

El identificador permite a `anacron` registrar cuándo se ejecutó por última
vez el trabajo. Así puede decidir si corresponde volver a ejecutarlo cuando el
sistema se inicia. En Debian, la información de seguimiento suele guardarse
bajo `/var/spool/anacron`.

## 7. Ejecutar aplicaciones gráficas

Las aplicaciones gráficas necesitan acceder a la sesión gráfica del usuario.
Una tarea que funciona desde un terminal puede fallar en `cron`, porque cron
se ejecuta en un entorno no interactivo y no hereda automáticamente las
variables de esa sesión. No es recomendable programar estas tareas como `root`
si deben abrir una aplicación en el escritorio de un usuario.

### 7.1. Ejecutar aplicaciones gráficas con cron

En una sesión X11, la aplicación suele necesitar `DISPLAY` y, según la
configuración, `XAUTHORITY`. Se pueden consultar desde el terminal gráfico:

```console
$ echo "$DISPLAY"
$ echo "$XAUTHORITY"
```

El material de clase muestra `xhost +SI:localuser:USUARIO` para autorizar
temporalmente a un usuario local a conectarse al servidor X. Esta autorización
reduce las protecciones de acceso de la sesión: úsala solo si hace falta y
retírala después con `xhost -SI:localuser:USUARIO`.

La tarea debe añadirse al `crontab` del usuario que tiene abierta la sesión
gráfica, no al de `root`. Ejemplo para lanzar Firefox a las 20:34 y guardar
salida y errores en un registro:

```cron
34 20 * * * DISPLAY=:0 firefox >> /tmp/cron_gui.log 2>&1
```

`>>` añade la salida al archivo; `2>&1` envía también los errores al mismo
archivo. El valor de `DISPLAY`, la autenticación y el ejecutable dependen de la
sesión y del sistema. Este ejemplo es para un entorno X11 y puede requerir
ajustes; no se debe asumir que `DISPLAY=:0` sirve para todas las sesiones,
especialmente con Wayland.

### 7.2. Ejecutar aplicaciones gráficas con timers

En sistemas con `systemd`, un timer de usuario permite vincular la ejecución al
gestor `systemd` del usuario. Es una alternativa más adecuada que `cron` para
tareas que dependen de una sesión gráfica, siempre que el entorno de la sesión
esté disponible cuando se ejecute el servicio.

Primero se crea el directorio de unidades de usuario:

```console
$ mkdir -p ~/.config/systemd/user
```

Ejemplo de servicio `~/.config/systemd/user/firefox.service`:

```ini
[Unit]
Description=Abrir Firefox desde systemd

[Service]
Type=oneshot
Environment=DISPLAY=:0
ExecStart=/usr/bin/firefox
```

Ejemplo de timer `~/.config/systemd/user/firefox.timer` para ejecutarlo a
diario a las 19:32:

```ini
[Unit]
Description=Programar la apertura diaria de Firefox

[Timer]
OnCalendar=*-*-* 19:32:00
Persistent=true
Unit=firefox.service

[Install]
WantedBy=timers.target
```

Después de guardar las unidades:

```console
$ systemctl --user daemon-reload
$ systemctl --user enable --now firefox.timer
$ systemctl --user list-timers
```

`Persistent=true` permite recuperar una ejecución del calendario que se perdió
mientras el timer no estaba activo. Cambia `/usr/bin/firefox` por la ruta real
del ejecutable y configura las variables gráficas según la sesión; `DISPLAY`
por sí sola puede no bastar.

## 8. Programación de tareas en GNOME: GNOME Schedule

GNOME Schedule fue una aplicación gráfica para crear tareas programadas, pero
según el material de clase ya no está disponible en los repositorios oficiales
de Debian desde Bookworm. En Debian 13 tampoco resulta práctico instalarla
desde repositorios antiguos por sus dependencias.

Para nuevas configuraciones, la alternativa recomendada en el material es usar
timers de `systemd` del usuario. Instalar paquetes `.deb` antiguos puede
provocar problemas de dependencias y no es la opción recomendada.

## Referencia

Apuntes elaborados a partir del material docente proporcionado para el tema
«Automatización de tareas del sistema».
