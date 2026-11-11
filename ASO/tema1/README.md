# Tema 1: Lenguajes de scripting en sistemas operativos

## Índice

- [1. Qué es un script](#1-qué-es-un-script)
- [2. Creación, ejecución y depuración](#2-creación-ejecución-y-depuración)
- [3. Salida y comillas](#3-salida-y-comillas)
- [4. Variables y entrada](#4-variables-y-entrada)
- [5. Argumentos y variables especiales](#5-argumentos-y-variables-especiales)
- [6. Redirecciones y composición de órdenes](#6-redirecciones-y-composición-de-órdenes)
- [7. Condiciones](#7-condiciones)
- [8. Selección de opciones](#8-selección-de-opciones)
- [9. Operaciones aritméticas](#9-operaciones-aritméticas)
- [10. Bucles](#10-bucles)
- [11. Funciones](#11-funciones)
- [12. Códigos de salida y estructura segura](#12-códigos-de-salida-y-estructura-segura)
- [13. Automatización de tareas administrativas](#13-automatización-de-tareas-administrativas)
- [14. Menús con `dialog`](#14-menús-con-dialog)
- [15. Ejercicios propuestos](#15-ejercicios-propuestos)
- [16. Errores frecuentes](#16-errores-frecuentes)
- [17. Lista de comprobación](#17-lista-de-comprobación)
- [Material complementario](#material-complementario)

## 1. Qué es un script

Un script Bash es un fichero de texto con órdenes que el intérprete ejecuta
secuencialmente. Permite automatizar tareas repetitivas del sistema operativo.
La primera línea indica qué intérprete debe ejecutarlo:

```bash
#!/bin/bash

echo "Hola, $USER"
```

La línea `#!` se llama *shebang*. También es habitual encontrar `#!/bin/bash`.
Guarda el fichero con extensión `.sh` y ejecútalo con Bash o dale permiso de
ejecución:

```console
$ bash saludo.sh
$ chmod u+x saludo.sh
$ ./saludo.sh
```

`./` indica que el script está en el directorio actual. Para lanzarlo solo por
su nombre, tendría que estar en un directorio de `PATH`. No es necesario mover
scripts de prácticas a directorios del sistema ni darles permisos `777`.

## 2. Creación, ejecución y depuración

Un script legible suele incluir una cabecera breve con su propósito, autor o
versión, y una indicación de uso. Divide las tareas en pasos claros y evita
órdenes innecesarias.

Antes de ejecutar un script, comprueba su sintaxis:

```console
$ bash -n script.sh
```

Para analizar su ejecución:

```console
$ bash -x script.sh argumento
```

`-x` muestra las órdenes y expansiones antes de ejecutarlas. También se puede
activar temporalmente desde el propio script con `set -x` y desactivar con
`set +x`. La opción `-v` muestra las líneas leídas por Bash; `-n` comprueba la
sintaxis sin ejecutar las órdenes.

Depurar implica predecir el resultado, comprobarlo y explicar las diferencias.
Cuando algo falla, revisa primero la sintaxis, los valores de las variables,
los argumentos y el código de salida de cada orden.

## 3. Salida y comillas

`echo` muestra texto y añade un salto de línea:

```bash
echo "Usuario: $USER"
echo "Fichero: $fichero"
echo "Líneas: $lineas"
```

Utiliza comillas dobles para mostrar variables y conservar los espacios de su
contenido.

Las comillas cambian cómo interpreta Bash el contenido:

| Forma | Efecto |
| --- | --- |
| `'texto literal'` | Conserva literalmente el contenido; no expande variables. |
| `"texto $variable"` | Expande variables y sustituciones, pero conserva el texto como una palabra. |
| `$(orden)` | Ejecuta una orden y sustituye la expresión por su salida. |
| `\` | Protege el carácter siguiente o permite continuar una orden en otra línea. |

Ejemplo:

```bash
nombre="Ana Pérez"
echo 'Hola, $nombre'
echo "Hola, $nombre"
fecha=$(date '+%d/%m/%Y')
echo "Fecha: $fecha"
```

La primera línea imprime `$nombre` literalmente; la segunda imprime su valor.
Usa comillas dobles al expandir variables, especialmente en rutas y argumentos:
`"$fichero"` evita que los espacios dividan una ruta en varias palabras.

## 4. Variables y entrada

Asigna valores sin espacios alrededor del signo `=`:

```bash
nombre="Ana Pérez"
numero=12
directorio="/var/log"
```

Para utilizar el contenido de una variable, escribe `$nombre` o
`${nombre}`. Las llaves delimitan el nombre cuando va seguido de más texto:

```bash
fichero="informe"
echo "${fichero}.txt"
```

La sustitución de órdenes `$(...)` guarda su salida en una variable:

```bash
equipo=$(hostname)
ahora=$(date '+%H:%M')
```

`read` obtiene datos de la entrada estándar. `-r` evita que las barras
invertidas se interpreten como escapes y `-p` muestra una pregunta:

```bash
read -r -p 'Introduce tu nombre: ' nombre
echo "Hola, $nombre"
```

Las variables definidas dentro del script solo están disponibles en ese
proceso. `export NOMBRE=valor` las convierte en variables de entorno que
heredan los procesos hijos. Algunas variables de entorno frecuentes son
`HOME`, `USER`, `PATH`, `PWD`, `SHELL` y `HOSTNAME`. `unset nombre` elimina
una variable.

## 5. Argumentos y variables especiales

Los valores escritos después del nombre del script son sus argumentos
posicionales:

| Variable | Significado |
| --- | --- |
| `$0` | Nombre o ruta con la que se invocó el script. |
| `$1`, `$2`, ... | Primer argumento, segundo argumento, etc. |
| `$#` | Número de argumentos recibidos. |
| `"$@"` | Todos los argumentos, cada uno conservado por separado. |
| `"$*"` | Todos los argumentos juntos en una sola palabra. |
| `$?` | Código de salida de la última orden ejecutada. |
| `$$` | PID del proceso de Bash actual. |
| `$!` | PID de la última orden ejecutada en segundo plano. |

Valida el número de argumentos antes de usarlos:

```bash
if [[ $# -ne 1 ]]; then
    echo "Uso: $0 <fichero>" >&2
    exit 2
fi

fichero=$1
```

Usa `"$@"` para recorrer argumentos que puedan contener espacios:

```bash
for argumento in "$@"; do
    echo "Argumento: $argumento"
done
```

## 6. Redirecciones y composición de órdenes

Los procesos disponen de tres canales habituales:

| Descriptor | Nombre | Uso |
| --- | --- | --- |
| `0` | Entrada estándar (`stdin`) | Datos que recibe la orden. |
| `1` | Salida estándar (`stdout`) | Resultado normal. |
| `2` | Salida de error (`stderr`) | Avisos y errores. |

Redirecciones frecuentes:

| Sintaxis | Efecto |
| --- | --- |
| `orden > salida.txt` | Guarda la salida estándar y sobrescribe el fichero. |
| `orden >> salida.txt` | Añade la salida estándar al final del fichero. |
| `orden < entrada.txt` | Lee la entrada desde un fichero. |
| `orden 2> errores.txt` | Guarda los errores y sobrescribe el fichero. |
| `orden 2>> errores.txt` | Añade los errores al fichero. |
| `orden > salida.txt 2>&1` | Envía ambos canales al mismo destino. |
| `orden > /dev/null 2>&1` | Descarta la salida normal y los errores. |

El orden de las redirecciones importa. `2>&1` dirige el descriptor 2 al destino
que tenga en ese momento el descriptor 1.

La tubería `|` conecta la salida de una orden con la entrada de otra:

```bash
grep -i 'error' registro.log | wc -l
```

Otros operadores útiles:

- `orden1 && orden2`: ejecuta `orden2` solo si `orden1` termina correctamente.
- `orden1 || orden2`: ejecuta `orden2` solo si `orden1` falla.
- `orden1 ; orden2`: ejecuta ambas órdenes en secuencia, sin condicionar la segunda.
- `(...)`: ejecuta las órdenes agrupadas en un subshell.
- `{ ...; }`: agrupa órdenes en el shell actual; requiere espacios y `;` antes de `}`.

El estado de una tubería es normalmente el de la última orden. En Bash,
`set -o pipefail` hace que la tubería falle si falla alguna de sus órdenes.

## 7. Condiciones

El `if` ejecuta bloques según el estado de una orden o prueba. En Bash, el
código `0` significa que la condición se cumple; un valor distinto de `0`
significa que no se cumple o que se produjo un error.

```bash
if [[ -d "$directorio" ]]; then
    echo "Es un directorio"
elif [[ -e "$directorio" ]]; then
    echo "Existe, pero no es un directorio"
else
    echo "No existe"
fi
```

`[[ ... ]]` es una construcción de Bash para comprobar cadenas, números y
rutas. También existe `[ ... ]` (el comando `test`); en ambos casos los
espacios alrededor de los corchetes son obligatorios.

Pruebas frecuentes:

| Prueba | Significado |
| --- | --- |
| `-e ruta` | La ruta existe. |
| `-f ruta` | Es un fichero regular. |
| `-d ruta` | Es un directorio. |
| `-L ruta` | Es un enlace simbólico. |
| `-r ruta` | Se puede leer. |
| `-w ruta` | Se puede escribir. |
| `-x ruta` | Se puede ejecutar o, si es un directorio, recorrer. |
| `-s ruta` | Existe y tiene tamaño mayor que cero. |

Para clasificar enlaces simbólicos, comprueba `-L` antes de otras pruebas:

```bash
if [[ -L "$ruta" ]]; then
    echo "Enlace simbólico"
elif [[ -f "$ruta" ]]; then
    echo "Fichero regular"
elif [[ -d "$ruta" ]]; then
    echo "Directorio"
elif [[ -e "$ruta" ]]; then
    echo "Existe y es de otro tipo"
else
    echo "No existe"
fi
```

Comparaciones habituales:

| Tipo | Operadores |
| --- | --- |
| Cadenas | `==`, `!=`, `-z` (vacía), `-n` (no vacía) |
| Números enteros | `-eq`, `-ne`, `-lt`, `-le`, `-gt`, `-ge` |

Valida que un dato sea numérico antes de compararlo como número:

```bash
if [[ ! $limite =~ ^[0-9]+$ ]] || (( limite < 1 || limite > 100 )); then
    echo "El límite debe ser un entero entre 1 y 100" >&2
    exit 2
fi
```

Una orden también puede ser directamente la condición:

```bash
if grep -q '^root:' /etc/passwd; then
    echo "La cuenta root aparece en la base de usuarios"
fi
```

`grep -q` no imprime coincidencias: su código de salida indica si encontró
alguna.

## 8. Selección de opciones

### `case`

`case` compara un valor con patrones. Es útil para opciones de línea de
comandos y menús:

```bash
case "${1:-}" in
    iniciar)
        echo "Iniciando"
        ;;
    detener)
        echo "Deteniendo"
        ;;
    *)
        echo "Uso: $0 {iniciar|detener}" >&2
        exit 2
        ;;
esac
```

En cada alternativa, `;;` termina el bloque y `*)` representa cualquier otro
valor. Los patrones pueden incluir `|` para aceptar varias opciones, por
ejemplo `s|S|si|SI)`.

### Menús con `select`

`select` presenta una lista numerada y repite el menú. La elección se guarda
en la variable indicada; la entrada escrita por el usuario queda en `REPLY`.
`PS3` permite personalizar el indicador:

```bash
PS3='Elige una opción: '
select opcion in 'Mostrar fecha' 'Salir'; do
    case $REPLY in
        1) date ;;
        2) break ;;
        *) echo "Opción incorrecta" ;;
    esac
done
```

Para menús con más control sobre el formato, se puede combinar `while`,
`read` y `case`. Antes de borrar o modificar información, solicita
confirmación y comprueba la respuesta.

## 9. Operaciones aritméticas

Bash realiza operaciones con enteros mediante `$((...))` o `((...))`:

```bash
base=8
incremento=3
total=$((base + incremento))
resto=$((total % 2))
echo "Total: $total; resto: $resto"
```

Operadores habituales: `+`, `-`, `*`, `/` y `%` (resto). Para expresar una
operación, conserva los espacios y usa paréntesis cuando ayuden a aclarar el
orden. La división de Bash es entera: no conserva decimales.

Para decimales se puede usar `bc`, si está instalado:

```bash
resultado=$(echo 'scale=2; 20.1 / 2.5' | bc -l)
```

## 10. Bucles

### `for`

`for` ejecuta el bloque una vez por cada valor:

```bash
for nombre in Ana Luis Marta; do
    echo "Hola, $nombre"
done
```

También se usa para recorrer ficheros que coinciden con un patrón:

```bash
for fichero in ./*.txt; do
    [[ -e "$fichero" ]] || continue
    echo "Encontrado: $fichero"
done
```

La comprobación evita procesar literalmente `./*.txt` si no hay coincidencias.
`continue` pasa a la siguiente iteración y `break` termina el bucle.

### `while`

`while` repite el bloque mientras la condición termine correctamente:

```bash
contador=1
while (( contador <= 5 )); do
    echo "$contador"
    contador=$((contador + 1))
done
```

Al procesar un fichero línea a línea, usa `IFS=` y `read -r` para conservar
espacios y barras invertidas:

```bash
while IFS= read -r linea || [[ -n $linea ]]; do
    echo "Línea: $linea"
done < entrada.txt
```

La condición adicional procesa también la última línea si el fichero no acaba
en salto de línea. La redirección al final evita que el bucle se ejecute en un
subshell y permite conservar contadores modificados dentro de él.

### `until`

`until` repite mientras la condición falle y termina cuando tiene éxito:

```bash
respuesta=''
until [[ $respuesta == 'salir' ]]; do
    read -r -p 'Escribe salir para terminar: ' respuesta
done
```

Comprueba siempre que una variable de control cambia dentro del bucle para
evitar iteraciones infinitas.

## 11. Funciones

Una función agrupa instrucciones para reutilizarlas. Sus argumentos se reciben
como `$1`, `$2`, etc. y son independientes de los argumentos del script que la
llama:

```bash
mostrar_uso() {
    echo "Uso: $0 <fichero>" >&2
}

fichero_legible() {
    local ruta=$1
    [[ -f "$ruta" && -r "$ruta" ]]
}

if fichero_legible "${1:-}"; then
    echo "El fichero se puede leer"
else
    mostrar_uso
    exit 1
fi
```

`local` limita una variable a la función. Cada alternativa de un menú puede
implementarse en una función distinta para que el flujo principal sea fácil de
leer.

`return` termina una función y devuelve un código de estado; no devuelve
texto. Para comunicar un resultado lógico, deja que la última orden de la
función proporcione su estado, o usa `return 0` para éxito y un valor distinto
de cero para fallo. Para guardar el texto que muestra una función, captura su
salida:

```bash
obtener_fecha() {
    date '+%Y-%m-%d'
}

fecha=$(obtener_fecha)
```

## 12. Códigos de salida y estructura segura

Cada orden y script termina con un código de salida:

- `0`: éxito.
- Distinto de `0`: fallo o situación no satisfactoria.
- `$?`: código de la última orden ejecutada; guárdalo o compruébalo antes de
  ejecutar otra orden, porque su valor cambia.

`exit n` termina un script con el código indicado. `return n` termina una
función. Es habitual reservar códigos distintos para errores diferentes, por
ejemplo, argumentos incorrectos, ruta inválida y fallo de una operación.

Un esqueleto de validación:

```bash
#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Uso: $0 <fichero>" >&2
    exit 2
fi

fichero=$1
if [[ ! -f "$fichero" ]]; then
    echo "Error: no es un fichero regular: $fichero" >&2
    exit 1
fi
if [[ ! -r "$fichero" ]]; then
    echo "Error: no se puede leer: $fichero" >&2
    exit 1
fi

lineas=$(wc -l < "$fichero") || {
    echo "Error al contar las líneas" >&2
    exit 1
}
echo "Líneas: $lineas"
exit 0
```

`>&2` envía el mensaje al canal de error. No muestres un mensaje de éxito ni
devuelvas `0` antes de comprobar que la operación principal terminó bien.

`set -euo pipefail` puede ayudar a detectar ciertos fallos, pero modifica el
comportamiento del script. No sustituye a la validación ni a la comprobación
explícita de órdenes: estudia sus efectos, sobre todo en condiciones,
funciones, sustituciones y tuberías, antes de usarlo.

## 13. Automatización de tareas administrativas

Los boletines aplican estas construcciones a consultas del sistema, análisis
de ficheros, menús, usuarios, almacenamiento, recogida de prácticas y copias
de seguridad. Al automatizar tareas administrativas:

1. Valida argumentos, rutas, tipos de fichero y permisos antes de actuar.
2. Usa comillas en rutas y expansiones; no des por supuesto el directorio de
   trabajo actual.
3. Comprueba el código de salida de operaciones como `cp`, `mkdir` y `tar`.
4. Envía los errores a `stderr`, registra las incidencias y resume los
   resultados de forma veraz.
5. Antes de sobrescribir, borrar o modificar cuentas, informa de lo que se
   afectará y solicita confirmación cuando proceda.
6. Comprueba privilegios solo cuando la operación los requiere. Prueba las
   tareas de administración en un entorno de prácticas y con datos de prueba.

Para leer registros separados por dos puntos, como `/etc/passwd`, asigna cada
campo a una variable:

```bash
while IFS=: read -r usuario clave uid gid descripcion home shell; do
    echo "$usuario: UID=$uid, HOME=$home"
done < /etc/passwd
```

No guardes contraseñas en texto plano ni las incluyas en scripts o registros.
Las prácticas de creación de usuarios deben realizarse en máquinas de
laboratorio y con un método autorizado para establecer credenciales.

Para analizar ocupación, `df -P` ofrece una salida adecuada para procesar por
líneas. Elimina el encabezado antes de leer los campos y valida el límite
numérico antes de compararlo. Recuerda que las unidades de espacio deben ser
coherentes: comprueba las unidades que devuelve cada opción de `df`.

Para copias de seguridad, valida el origen y el destino, crea el destino solo
si corresponde, decide explícitamente qué hacer si la copia ya existe y
comprueba el resultado de `tar` antes de informar de éxito. En la rotación,
verifica que la selección conserva las copias más recientes y que cualquier
borrado solo afecta a los ficheros esperados.

## 14. Menús con `dialog`

`dialog` es una herramienta opcional para crear cuadros y menús en terminal.
No forma parte de Bash y debe estar instalada en el sistema. Puede mostrar
mensajes, pedir datos y presentar opciones:

```console
$ dialog --msgbox "Proceso terminado" 8 40
$ dialog --yesno "¿Continuar?" 8 40
```

El código de salida permite distinguir, por ejemplo, entre aceptar y cancelar.
Los datos introducidos en cuadros como `--inputbox` se escriben normalmente en
`stderr`; redirígelos a un fichero o usa la opción `--stdout` si quieres
capturarlos por la salida estándar. Comprueba siempre el estado devuelto antes
de continuar.

## 15. Ejercicios propuestos

Hay ejercicios ordenados por dificultad, con soluciones explicadas, en
[ejercicios.md](./ejercicios.md). Como práctica adicional, puedes trabajar
estos retos sin consultar primero las soluciones:

1. Muestra un informe de sesión con usuario, UID, directorio personal, shell,
   equipo, fecha y directorio actual.
2. Crea un clasificador que reciba una ruta e indique si no existe, es un
   fichero regular, un directorio o un enlace simbólico.
3. Amplía el clasificador para validar argumentos y permisos y, si recibe un
   fichero, mostrar líneas, palabras y tamaño.
4. Diseña un menú repetitivo con una función por opción y confirmación antes
   de salir o modificar datos.
5. Analiza el espacio de varios sistemas de ficheros a partir de un umbral
   validado y devuelve un código de salida distinto si hay alertas.
6. Diseña una copia de seguridad y pruébala con datos temporales, rutas con
   espacios, origen inexistente y copia ya existente. Comprueba qué ficheros
   conserva la rotación antes de permitir cualquier borrado.

## 16. Errores frecuentes

### Olvidar los espacios en `[ ]`

Los corchetes de `test` son parte de una orden y deben separarse de sus
argumentos:

```bash
# Incorrecto
if [ "$numero" -gt10 ]; then
    echo "Mayor que diez"
fi

# Correcto
if [ "$numero" -gt 10 ]; then
    echo "Mayor que diez"
fi
```

### Usar variables sin comillas

Sin comillas, Bash puede dividir un valor por espacios y expandir caracteres
comodín. Cita variables que contienen rutas o texto:

```bash
# Puede fallar si la ruta contiene espacios
if [[ -f $fichero ]]; then
    cat $fichero
fi

# Conserva la ruta como un solo argumento
if [[ -f "$fichero" ]]; then
    cat "$fichero"
fi
```

### No comprobar los argumentos

Acceder a `$1` no garantiza que el usuario haya proporcionado un argumento.
Comprueba primero `$#` y muestra el uso por `stderr` si no coincide con lo
esperado:

```bash
if [[ $# -ne 1 ]]; then
    echo "Uso: $0 <fichero>" >&2
    exit 2
fi
```

### Confundir el estado de una orden con su salida

`$?` guarda el código de salida de la última orden; no su texto. Compruébalo
inmediatamente, porque otra orden lo cambia. En una condición, es más claro
comprobar directamente la orden:

```bash
if grep -q '^root:' /etc/passwd; then
    echo "Se ha encontrado root"
else
    echo "No se ha encontrado root"
fi
```

### No actualizar la variable de control de un bucle

Un bucle `while` puede no terminar nunca si la condición sigue siendo cierta.
Actualiza el contador en cada iteración:

```bash
numero=1
while [[ $numero -le 3 ]]; do
    echo "$numero"
    numero=$((numero + 1))
done
```

### Contar el contenido en vez de acumularlo

Si en cada iteración asignas el nuevo valor al total, se pierde el resultado
anterior. Para contar, incrementa el acumulador:

```bash
total=0
for nombre in Ana Luis Marta; do
    total=$((total + 1))
done
echo "Total: $total"
```

### Suponer que una copia o un borrado siempre funciona

Que `cp`, `tar` o `rm` no produzcan el resultado esperado debe reflejarse en el
código de salida y en el mensaje. Valida las rutas antes de actuar y comprueba
el estado de la operación antes de informar de éxito. Practica siempre sobre
ficheros temporales, no sobre datos del sistema.

## 17. Lista de comprobación

Antes de entregar un script, comprueba cada punto que corresponda:

- [ ] Empieza con `#!/bin/bash` y declara para qué sirve y cómo se usa.
- [ ] Comprueba que se recibe el número de argumentos esperado.
- [ ] Maneja argumentos vacíos y rutas con espacios.
- [ ] Cita las expansiones de variables, especialmente cuando son rutas.
- [ ] Comprueba que las rutas existen, son del tipo esperado y tienen los
  permisos necesarios.
- [ ] Valida números y opciones antes de compararlos o utilizarlos.
- [ ] Cada bucle actualiza su condición y puede terminar.
- [ ] Las tareas repetidas están separadas en funciones con nombres claros.
- [ ] Los errores van a `stderr` y el código de salida indica el resultado.
- [ ] El mensaje final solo afirma resultados que se han comprobado.
- [ ] Las operaciones que sobrescriben, borran o cambian cuentas se revisan y
  requieren confirmación cuando corresponde.
- [ ] `bash -n script.sh` termina sin errores de sintaxis.
- [ ] Prueba casos válidos, argumentos incorrectos, rutas inexistentes y
  espacios en las rutas con datos de práctica.

## Material complementario

- [Chuleta de Bash](./chuleta.md): referencia breve de comandos y estructuras
  del tema.
- [Ejercicios de Bash](./ejercicios.md): prácticas progresivas con soluciones
  explicadas.