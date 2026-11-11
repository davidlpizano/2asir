# Chuleta de Bash

Referencia rápida para los scripts de este tema. Los ejemplos usan Bash y
`echo`.

## Inicio y ejecución

```bash
#!/bin/bash

echo "Hola, $USER"
```

```console
$ bash script.sh
$ chmod u+x script.sh
$ ./script.sh
$ bash -n script.sh
$ bash -x script.sh argumento
```

## Variables y entrada

```bash
nombre="Ana Pérez"             # Asignar: sin espacios alrededor de =
echo "$nombre"                 # Expandir una variable
fecha=$(date '+%Y-%m-%d')      # Guardar la salida de una orden
read -r -p "Nombre: " nombre   # Leer una línea
export MODO="prueba"           # Compartir con procesos hijos
unset nombre                   # Eliminar una variable
```

Usa comillas dobles alrededor de expansiones para conservar espacios.
Las comillas simples conservan literalmente su contenido; las dobles permiten
expandir variables.

## Argumentos y variables especiales

| Variable | Significado |
| --- | --- |
| `$0` | Nombre o ruta con la que se ejecuta el script. |
| `$1`, `$2`, ... | Primer argumento, segundo argumento, etc. |
| `$#` | Número de argumentos. |
| `"$@"` | Todos los argumentos, conservando cada uno por separado. |
| `"$*"` | Todos los argumentos juntos en una sola palabra. |
| `$?` | Código de salida de la última orden. |
| `$$` | PID del proceso de Bash actual. |
| `$!` | PID de la última orden enviada al segundo plano. |

```bash
if [[ $# -ne 1 ]]; then
    echo "Uso: $0 <fichero>" >&2
    exit 2
fi

fichero=$1
```

## Condiciones

```bash
if [[ -f "$ruta" ]]; then
    echo "Es un fichero regular"
elif [[ -d "$ruta" ]]; then
    echo "Es un directorio"
else
    echo "No existe o es de otro tipo"
fi
```

| Prueba | Comprueba si... |
| --- | --- |
| `-e "$ruta"` | La ruta existe. |
| `-f "$ruta"` | Es un fichero regular. |
| `-d "$ruta"` | Es un directorio. |
| `-L "$ruta"` | Es un enlace simbólico. |
| `-r "$ruta"` | Se puede leer. |
| `-w "$ruta"` | Se puede escribir. |
| `-x "$ruta"` | Se puede ejecutar o recorrer. |
| `-s "$ruta"` | Existe y tiene contenido. |

| Tipo | Operadores |
| --- | --- |
| Cadenas | `==`, `!=`, `-z` (vacía), `-n` (no vacía) |
| Números enteros | `-eq`, `-ne`, `-lt`, `-le`, `-gt`, `-ge` |

Deja espacios alrededor de los corchetes y de los operadores de `[ ... ]`.
En Bash, `[[ ... ]]` permite, además, comparar con patrones y validar formatos:

```bash
if [[ $limite =~ ^[0-9]+$ ]]; then
    echo "Es un entero positivo"
fi
```

## `case` y órdenes encadenadas

```bash
case "${1:-}" in
    iniciar) echo "Iniciando" ;;
    detener) echo "Deteniendo" ;;
    *) echo "Opción no válida" >&2; exit 2 ;;
esac
```

- `orden1 && orden2`: ejecuta la segunda orden si la primera tiene éxito.
- `orden1 || orden2`: ejecuta la segunda orden si la primera falla.
- `orden1 ; orden2`: ejecuta ambas órdenes en secuencia.

## Aritmética

```bash
numero=4
numero=$((numero + 1))
doble=$((numero * 2))
resto=$((numero % 2))
echo "Número: $numero; doble: $doble; resto: $resto"
```

Bash calcula enteros y trunca el resultado de una división entera. Para
decimales se puede usar `bc`, si está instalado:

```bash
resultado=$(echo 'scale=2; 7 / 3' | bc -l)
```

## Bucles

```bash
for nombre in Ana Luis Marta; do
    echo "$nombre"
done
```

```bash
numero=1
while [[ $numero -le 3 ]]; do
    echo "$numero"
    numero=$((numero + 1))
done
```

```bash
while IFS= read -r linea || [[ -n $linea ]]; do
    echo "$linea"
done < entrada.txt
```

- `break` termina el bucle.
- `continue` pasa a la iteración siguiente.
- Comprueba que los bucles actualicen la condición para que puedan terminar.

## Funciones

```bash
mostrar_mensaje() {
    local mensaje=$1
    echo "$mensaje"
}

mostrar_mensaje "Hola, Ana"
```

Dentro de la función, `$1`, `$2`, etc. son sus propios argumentos.
`return n` devuelve un código de estado, no un texto. Usa `exit n` para
terminar el script.

## Salida, redirecciones y estados

| Sintaxis | Efecto |
| --- | --- |
| `orden > salida.txt` | Escribe la salida estándar y sobrescribe el fichero. |
| `orden >> salida.txt` | Añade la salida estándar al fichero. |
| `orden < entrada.txt` | Lee la entrada desde el fichero. |
| `orden 2> errores.txt` | Escribe los errores en el fichero. |
| `orden > salida.txt 2>&1` | Envía la salida y los errores al mismo fichero. |
| `orden > /dev/null 2>&1` | Descarta la salida y los errores. |
| `orden1 \| orden2` | Conecta la salida de la primera orden con la segunda. |

- Código de salida `0`: éxito; distinto de `0`: fallo o condición no satisfecha.
- `$?` contiene el estado de la última orden; compruébalo antes de ejecutar
  otra.
- `>&2` envía un mensaje a la salida de error.

```bash
if grep -q '^root:' /etc/passwd; then
    echo "Existe la cuenta root"
fi
```

## Comprobaciones antes de ejecutar

```console
$ bash -n script.sh             # Comprobar la sintaxis
$ bash -x script.sh argumento   # Mostrar las órdenes mientras se ejecutan
```

Valida argumentos, comillas, rutas, permisos y códigos de salida. Prueba las
operaciones que modifican o borran datos únicamente con ficheros de práctica.
