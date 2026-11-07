# Tema 0: Repaso de Linux y PowerShell

## Índice

- [1. Terminal y comandos básicos](#1-terminal-y-comandos-básicos)
- [2. Archivos y directorios](#2-archivos-y-directorios)
- [3. Búsqueda y procesamiento de texto](#3-búsqueda-y-procesamiento-de-texto)
- [4. Usuarios, grupos y permisos](#4-usuarios-grupos-y-permisos)
- [5. Procesos y servicios](#5-procesos-y-servicios)
- [6. Paquetes, almacenamiento y red](#6-paquetes-almacenamiento-y-red)
- [7. Repaso de PowerShell](#7-repaso-de-powershell)

## 1. Terminal y comandos básicos

La shell interpreta los comandos y permite combinarlos mediante tuberías,
redirecciones y variables. En GNU/Linux, Bash es una de las shells más
habituales.

```console
$ whoami
$ hostname
$ date
$ pwd
$ man ls
$ comando --help
```

En una orden, las opciones modifican el comportamiento del comando y los
argumentos indican sobre qué elemento debe actuar. Usa comillas para mantener
un texto con espacios como un único argumento:

```console
$ printf '%s\n' "texto con espacios"
```

La salida estándar se puede guardar con `>` (sobrescribe) o `>>` (añade). Los
errores se envían por defecto a la salida de error; `2>` los redirige. La
tubería `|` conecta la salida de un comando con la entrada del siguiente:

```console
$ comando > resultado.txt
$ comando >> resultado.txt
$ comando 2> errores.txt
$ comando1 | comando2
```

## 2. Archivos y directorios

Rutas que conviene distinguir:

- `/`: directorio raíz del sistema.
- `~`: directorio personal del usuario.
- `.` y `..`: directorio actual y directorio padre.
- Una ruta que empieza por `/` es absoluta; las demás son relativas al
  directorio actual.

Comandos frecuentes:

| Comando | Uso |
| --- | --- |
| `pwd` | Muestra el directorio actual. |
| `ls -la` | Lista también archivos ocultos y muestra detalles. |
| `cd ruta` | Cambia de directorio. |
| `mkdir -p ruta` | Crea directorios intermedios si hacen falta. |
| `touch archivo` | Crea un archivo vacío o actualiza su fecha. |
| `cp origen destino` | Copia archivos. |
| `mv origen destino` | Mueve o renombra archivos. |
| `rm archivo` | Elimina un archivo. |
| `rmdir directorio` | Elimina un directorio vacío. |
| `file archivo` | Identifica el tipo de archivo. |

Comprueba siempre la ruta antes de borrar o sobrescribir archivos. `rm -r`
elimina directorios y su contenido; úsalo solo cuando hayas verificado
cuidadosamente qué ruta has indicado.

## 3. Búsqueda y procesamiento de texto

`cat` muestra archivos; `less` permite recorrerlos; `head` y `tail` muestran
el principio y el final. Para seguir un registro mientras crece, se puede usar
`tail -f`.

```console
$ less /var/log/syslog
$ head -n 20 archivo.txt
$ tail -n 20 archivo.txt
$ grep -n "error" archivo.txt
$ grep -Rni "texto" directorio/
$ find directorio/ -type f -name "*.conf"
```

`grep` busca texto; `find` busca elementos según propiedades de la ruta, el
tipo o el nombre. Las opciones `-i` y `-n` de `grep` ignoran mayúsculas y
muestran números de línea. La opción `-R` recorre subdirectorios.

## 4. Usuarios, grupos y permisos

`id` muestra la identidad y los grupos del usuario. `sudo` permite ejecutar
una orden con privilegios administrativos cuando la cuenta está autorizada.
Usa privilegios elevados solo para las operaciones que los necesiten.

Cada archivo tiene permisos para el propietario, el grupo y el resto de
usuarios. En modo simbólico, `r` significa lectura, `w` escritura y `x`
ejecución o acceso a un directorio:

```console
$ ls -l archivo
$ chmod u+x script.sh
$ chmod 640 archivo
$ chown usuario:grupo archivo
$ id
```

En modo numérico, `r=4`, `w=2` y `x=1`; los valores se suman para cada clase
de usuario. Por ejemplo, `640` da lectura y escritura al propietario, lectura
al grupo y ningún permiso al resto. Cambiar propietario con `chown` suele
requerir permisos administrativos.

## 5. Procesos y servicios

Un proceso en primer plano puede interrumpirse con `Ctrl+C`; `Ctrl+Z` lo
suspende. `jobs`, `bg` y `fg` permiten consultar y gestionar trabajos de la
shell actual.

```console
$ ps aux
$ pgrep -a nombre
$ top
$ kill PID
$ systemctl status nombre-servicio
$ sudo systemctl restart nombre-servicio
$ systemctl list-units --type=service
```

`kill` envía una señal al proceso; la señal predeterminada solicita que
termine de forma ordenada. Identifica el PID antes de enviar señales y evita
usar terminaciones forzadas salvo que sea imprescindible. `systemctl` permite
consultar y administrar servicios en sistemas que usan `systemd`.

## 6. Paquetes, almacenamiento y red

En Debian y derivados, `apt` gestiona paquetes:

```console
$ sudo apt update
$ apt search nombre
$ apt show paquete
$ sudo apt install paquete
$ sudo apt remove paquete
```

`apt update` actualiza el índice de paquetes; no actualiza por sí solo los
paquetes instalados.

Comandos útiles para consultar el sistema:

```console
$ df -h
$ du -sh directorio/
$ lsblk
$ free -h
$ ip address
$ ip route
$ ping -c 4 ejemplo.org
$ ss -tulpn
```

`df` muestra el espacio de los sistemas de archivos montados y `du` estima el
espacio ocupado por rutas. `ip` consulta interfaces y rutas; `ss` muestra
conexiones y sockets. Algunos detalles pueden requerir privilegios
administrativos.

## 7. Repaso de PowerShell

PowerShell trabaja con objetos en la tubería, no solo con líneas de texto. Los
cmdlets suelen seguir el patrón `Verbo-Sustantivo`. `Get-Help` muestra ayuda y
`Get-Command` permite localizar comandos.

```powershell
Get-Help Get-ChildItem
Get-Command *Process*
Get-Location
Get-ChildItem
Set-Location C:\Users
```

Las variables empiezan por `$`. La tubería pasa objetos al siguiente cmdlet;
por ejemplo, `Where-Object` filtra objetos y `Select-Object` elige propiedades:

```powershell
$ruta = "C:\Temp"
Get-ChildItem -Path $ruta -File |
    Where-Object Length -gt 1MB |
    Select-Object Name, Length
```

Operaciones habituales con archivos:

```powershell
New-Item -Path .\prueba -ItemType Directory
Get-Content .\datos.txt
Set-Content -Path .\salida.txt -Value "Primera línea"
Add-Content -Path .\salida.txt -Value "Línea añadida"
Copy-Item .\origen.txt .\copia.txt
Move-Item .\copia.txt .\archivo.txt
Remove-Item .\archivo.txt
```

Antes de ejecutar `Remove-Item`, revisa la ruta y los parámetros. El proveedor
de sistema de archivos también permite usar `Get-ChildItem`, `Copy-Item` y
otros cmdlets sobre rutas; para mostrar la ruta actual, usa `Get-Location`.

Consulta procesos y servicios con cmdlets específicos:

```powershell
Get-Process
Get-Service
Get-Process | Where-Object CPU -gt 10 | Sort-Object CPU -Descending
```

Para scripts locales, PowerShell puede aplicar una directiva de ejecución.
Consulta la configuración con `Get-ExecutionPolicy -List` y sigue la política
de seguridad del equipo o centro; no cambies la directiva ni la eludas sin
autorización.
