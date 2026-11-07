# Tema 1: Scripts de Linux

## Índice

- [1. Estructura y ejecución](#1-estructura-y-ejecución)
- [2. Variables y argumentos](#2-variables-y-argumentos)
- [3. Entrada, salida y códigos de retorno](#3-entrada-salida-y-códigos-de-retorno)
- [4. Condiciones](#4-condiciones)
- [5. Bucles](#5-bucles)
- [6. Funciones](#6-funciones)
- [7. Buenas prácticas](#7-buenas-prácticas)
- [8. Ejercicios propuestos](#8-ejercicios-propuestos)

## 1. Estructura y ejecución

Un script de shell es un archivo de texto con comandos que la shell ejecuta en
orden. En este tema se usa Bash. La primera línea selecciona el intérprete:

```bash
#!/usr/bin/env bash

printf 'Hola, %s\n' "${USER:-usuario}"
```

Guarda el archivo, por ejemplo, como `saludo.sh`. Se puede ejecutar pasando el
archivo a Bash o concediéndole permiso de ejecución:

```console
$ bash saludo.sh
$ chmod u+x saludo.sh
$ ./saludo.sh
```

La ruta `./` indica que el archivo está en el directorio actual. Comprueba los
permisos y la ruta si la ejecución falla.

## 2. Variables y argumentos

Asigna valores sin espacios alrededor de `=`. Usa comillas dobles al expandir
variables para preservar espacios y evitar que el shell divida el valor en
palabras:

```bash
nombre="Ana Pérez"
directorio="/var/log"
printf 'Usuario: %s\n' "$nombre"
```

Las variables de entorno se pueden exportar para que las reciban los procesos
hijos:

```bash
export MODO="prueba"
```

Los argumentos recibidos por el script se consultan con parámetros posicionales:

| Expansión | Significado |
| --- | --- |
| `$0` | Nombre o ruta con la que se invocó el script. |
| `$1`, `$2`, ... | Primer argumento, segundo argumento, etc. |
| `$#` | Número de argumentos. |
| `"$@"` | Todos los argumentos, conservando cada uno por separado. |
| `$?` | Código de retorno del último comando. |

Ejemplo de validación de argumentos:

```bash
#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
    printf 'Uso: %s <directorio>\n' "$0" >&2
    exit 2
fi

directorio=$1
printf 'Directorio indicado: %s\n' "$directorio"
```

## 3. Entrada, salida y códigos de retorno

`printf` permite dar formato a la salida. `read` lee una línea introducida por
el usuario. Los códigos de retorno indican si una orden terminó correctamente:
por convención, `0` significa éxito y un valor distinto de cero indica error.

```bash
read -r -p "Nombre: " nombre
printf 'Hola, %s\n' "$nombre"

if [[ -f "$1" ]]; then
    printf 'El archivo existe\n'
else
    printf 'No existe o no es un archivo regular\n' >&2
    exit 1
fi
```

Usa `>&2` para enviar mensajes de error a la salida estándar de error. `exit`
termina el script y devuelve el código indicado.

## 4. Condiciones

`if` ejecuta bloques según el estado de una condición. En Bash, `[[ ... ]]`
permite comprobar cadenas, números y rutas:

```bash
if [[ -d "$directorio" ]]; then
    printf 'Es un directorio\n'
elif [[ -e "$directorio" ]]; then
    printf 'Existe, pero no es un directorio\n'
else
    printf 'No existe\n'
fi
```

Comprobaciones frecuentes:

| Prueba | Significado |
| --- | --- |
| `-e ruta` | La ruta existe. |
| `-f ruta` | Es un archivo regular. |
| `-d ruta` | Es un directorio. |
| `-r ruta` | Se puede leer. |
| `-w ruta` | Se puede escribir. |
| `-x ruta` | Se puede ejecutar o recorrer. |
| `cadena1 == cadena2` | Las cadenas son iguales. |
| `numero1 -eq numero2` | Los números son iguales. |

Para seleccionar entre varias opciones según el valor de una expresión, usa
`case`:

```bash
case "${1:-}" in
    iniciar) printf 'Iniciando\n' ;;
    detener) printf 'Deteniendo\n' ;;
    *)
        printf 'Uso: %s {iniciar|detener}\n' "$0" >&2
        exit 2
        ;;
esac
```

## 5. Bucles

`for` recorre una lista de valores; `while` repite mientras una orden o
condición tenga éxito:

```bash
for archivo in ./*.txt; do
    [[ -e "$archivo" ]] || continue
    printf 'Encontrado: %s\n' "$archivo"
done
```

La comprobación evita procesar literalmente `./*.txt` cuando no hay archivos
que coincidan con el patrón.

```bash
while IFS= read -r linea; do
    printf 'Línea: %s\n' "$linea"
done < entrada.txt
```

`IFS=` junto con `read -r` conserva espacios iniciales y barras invertidas en
cada línea.

## 6. Funciones

Las funciones agrupan órdenes reutilizables. Los argumentos de la función usan
los mismos parámetros posicionales (`$1`, `$2`, ...); `return` devuelve un
código de estado, no un texto:

```bash
mostrar_uso() {
    printf 'Uso: %s <archivo>\n' "$0" >&2
}

archivo_legible() {
    [[ -f "$1" && -r "$1" ]]
}

if archivo_legible "${1:-}"; then
    printf 'Archivo disponible\n'
else
    mostrar_uso
    exit 1
fi
```

Para producir texto desde una función, usa `printf` y captura su salida con
sustitución de comandos: `resultado=$(mi_funcion)`.

## 7. Buenas prácticas

- Cita las expansiones de variables: `"$variable"` y `"$@"`.
- Valida argumentos y rutas antes de actuar sobre ellas.
- Usa rutas explícitas y evita asumir cuál es el directorio de trabajo.
- Comprueba códigos de retorno y muestra errores por la salida de error.
- Prueba primero con datos de ejemplo y evita ejecutar scripts con privilegios
  administrativos si no son necesarios.
- `set -euo pipefail` puede ayudar a detectar errores, variables no definidas
  y fallos en tuberías, pero cambia el comportamiento ante ciertos estados.
  Úsalo conociendo sus efectos y comprueba especialmente las condiciones,
  sustituciones y comandos cuyo fallo sea esperado.
- Pasa el script por `bash -n script.sh` para comprobar errores de sintaxis
  antes de ejecutarlo.

## 8. Ejercicios propuestos

1. Crea un script que reciba una ruta e indique si es archivo, directorio o no
   existe.
2. Amplía el script para comprobar también si el usuario puede leer y escribir
   la ruta.
3. Escribe un script que reciba varios nombres de archivo y muestre los que
   existen.
4. Lee un archivo línea a línea y cuenta cuántas líneas no vacías contiene.
5. Crea una función que valide que se ha recibido exactamente un argumento y
   reutilízala en un script con varias opciones.
