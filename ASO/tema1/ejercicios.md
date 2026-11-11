# Ejercicios de Bash

Resuelve los ejercicios en orden. Para cada uno, predice primero qué hará el
script, implementa la solución y pruébala con varios casos. Las soluciones
están plegadas al final para que puedas intentar los ejercicios antes de
consultarlas.

Usa `#!/bin/bash` en los scripts. No ejecutes prácticas de borrado,
modificación de usuarios o administración sobre datos reales.

## Nivel 1: variables y operaciones

### Ejercicio 1. Sigue los valores

Sin ejecutar el código, indica el valor de cada variable después de cada
asignación y predice las tres líneas de salida:

```bash
#!/bin/bash

a=5
b=2
c=$((a * b))
a=$((a + 3))
b=$((c - b))
echo "$a"
echo "$b"
echo "$c"
```

Después ejecútalo y compara el resultado con tu predicción.

## Nivel 2: entrada y condiciones

### Ejercicio 2. Saludo

Crea `saludo.sh` para que pida un nombre y muestre `Hola, NOMBRE`. Prueba una
respuesta con nombre y apellidos y otra con una sola palabra.

### Ejercicio 3. Clasificador de rutas

Crea `tipo_ruta.sh` para recibir exactamente una ruta y clasificarla como
enlace simbólico, fichero regular, directorio o ruta inexistente. Comprueba
primero si es un enlace. Si el número de argumentos es incorrecto, muestra el
uso por la salida de error y termina con un código distinto de cero.

Prueba el script con un fichero, un directorio, una ruta inexistente y, si es
posible, un enlace simbólico.

## Nivel 3: argumentos y procesamiento de ficheros

### Ejercicio 4. Informe de texto

Crea `informe.sh` con el uso `./informe.sh <fichero>`. Debe comprobar que:

1. Se ha recibido exactamente un argumento.
2. La ruta es un fichero regular y se puede leer.
3. Los errores se envían a `stderr` y el script finaliza con un código
   distinto de cero.

Si las comprobaciones pasan, muestra el número de líneas y de palabras. Debe
funcionar con ficheros cuyo nombre contenga espacios.

### Ejercicio 5. Analizador de un registro

Crea `analizar_registro.sh` para recibir un fichero de texto y contar las
líneas vacías y las que contienen la palabra `error`, sin distinguir entre
mayúsculas y minúsculas. Lee el fichero línea a línea y muestra un resumen al
final. Comprueba qué pasa si la última línea no acaba en un salto de línea.

## Nivel 4: bucles y funciones

### Ejercicio 6. Contador de ficheros

Crea `contar.sh` para recibir un directorio. Recorre sus elementos directos,
cuenta los ficheros regulares y no suma los subdirectorios. Valida la ruta y
controla el caso en que no haya ningún fichero coincidente.

### Ejercicio 7. Menú de consulta

Crea un menú que se repita hasta elegir salir. Debe tener tres opciones:

1. Mostrar la fecha.
2. Mostrar el directorio actual.
3. Salir.

Implementa cada opción en una función. Avisa si se introduce una opción
incorrecta y pide confirmación antes de salir. Si el usuario responde que no,
el menú debe continuar.

## Nivel 5: ejercicio integrador

### Ejercicio 8. Resumen seguro de un registro

Crea `resumen.sh`, con uso `./resumen.sh <fichero>`. El script debe:

1. Validar que se ha recibido un único argumento.
2. Comprobar que el fichero existe, es regular y se puede leer.
3. Leerlo línea a línea, conservando espacios y procesando también la última
   línea si no acaba en salto de línea.
4. Contar las líneas vacías y las líneas que contienen `error`, sin distinguir
   entre mayúsculas y minúsculas.
5. Escribir los errores a `stderr`, devolver un código de error y mostrar el
   resumen solo cuando todas las comprobaciones hayan pasado.
6. Probarse con un fichero cuyo nombre tenga espacios, un fichero sin permiso
   de lectura y una ruta inexistente.

**Reto:** implementa el procesamiento de líneas en una función. La función
debe devolver su resultado con códigos de salida o variables; recuerda que
`return` no devuelve texto.

## Soluciones explicadas

Intenta primero cada ejercicio. Expande el bloque de la solución únicamente
cuando quieras comprobar o comparar tu trabajo.

<details>
<summary>Solución 1: Sigue los valores</summary>

- `a` empieza en `5` y `b` en `2`.
- `c` se calcula con los valores iniciales: `5 * 2 = 10`.
- Después, `a` pasa a `8` y `b` pasa a `10 - 2 = 8`.
- La salida es `8`, `8` y `10`, en ese orden.

```bash
#!/bin/bash

a=5
b=2
c=$((a * b))
a=$((a + 3))
b=$((c - b))
echo "$a"
echo "$b"
echo "$c"
```

`c` no cambia cuando cambian `a` o `b`: contiene el resultado calculado en el
momento de su asignación.

</details>

<details>
<summary>Solución 2: Saludo</summary>

```bash
#!/bin/bash

read -r -p "Introduce tu nombre: " nombre
echo "Hola, $nombre"
```

`read -r` conserva la entrada y las comillas dobles de `echo` permiten que un
nombre con espacios se muestre como una sola cadena.

</details>

<details>
<summary>Solución 3: Clasificador de rutas</summary>

```bash
#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Uso: $0 <ruta>" >&2
    exit 2
fi

ruta=$1

if [[ -L "$ruta" ]]; then
    echo "Enlace simbólico"
elif [[ -f "$ruta" ]]; then
    echo "Fichero regular"
elif [[ -d "$ruta" ]]; then
    echo "Directorio"
else
    echo "La ruta no existe o no es accesible"
fi
```

La comprobación `-L` se hace antes que `-f` o `-d`, ya que un enlace puede
apuntar a un fichero o a un directorio.

</details>

<details>
<summary>Solución 4: Informe de texto</summary>

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
    echo "Error: no se pudieron contar las líneas" >&2
    exit 1
}
palabras=$(wc -w < "$fichero") || {
    echo "Error: no se pudieron contar las palabras" >&2
    exit 1
}

echo "Fichero: $fichero"
echo "Líneas: $lineas"
echo "Palabras: $palabras"
```

Las comillas alrededor de `"$fichero"` conservan los espacios al usar la ruta.
Los errores se muestran por `stderr`, y cada fallo termina con un código
distinto de cero.

</details>

<details>
<summary>Solución 5: Analizador de un registro</summary>

```bash
#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Uso: $0 <fichero>" >&2
    exit 2
fi

fichero=$1
if [[ ! -f "$fichero" || ! -r "$fichero" ]]; then
    echo "Error: se necesita un fichero regular y legible" >&2
    exit 1
fi

vacias=0
con_error=0
while IFS= read -r linea || [[ -n $linea ]]; do
    if [[ -z $linea ]]; then
        vacias=$((vacias + 1))
    fi

    case $linea in
        *[Ee][Rr][Rr][Oo][Rr]*)
            con_error=$((con_error + 1))
            ;;
    esac
done < "$fichero"

echo "Líneas vacías: $vacias"
echo "Líneas con error: $con_error"
```

La condición adicional de `read` incluye una última línea aunque el fichero
no termine en salto de línea. El patrón del `case` acepta `error` con
cualquier combinación de mayúsculas y minúsculas.

</details>

<details>
<summary>Solución 6: Contador de ficheros</summary>

```bash
#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Uso: $0 <directorio>" >&2
    exit 2
fi

directorio=$1
if [[ ! -d "$directorio" || ! -r "$directorio" || ! -x "$directorio" ]]; then
    echo "Error: el directorio no existe o no se puede recorrer" >&2
    exit 1
fi

total=0
for elemento in "$directorio"/*; do
    [[ -e "$elemento" ]] || continue
    if [[ -f "$elemento" ]]; then
        total=$((total + 1))
    fi
done

echo "Ficheros: $total"
```

Si el patrón `*` no encuentra elementos, Bash lo deja sin expandir; la
comprobación `-e` evita contar ese patrón como un fichero. `-f` no cuenta los
subdirectorios.

</details>

<details>
<summary>Solución 7: Menú de consulta</summary>

```bash
#!/bin/bash

mostrar_fecha() {
    date
}

mostrar_directorio() {
    pwd
}

salir() {
    read -r -p "¿Desea salir? [s/N]: " respuesta
    case $respuesta in
        s|S|si|SI|Si) return 0 ;;
        *) return 1 ;;
    esac
}

while true; do
    echo "1. Mostrar la fecha"
    echo "2. Mostrar el directorio actual"
    echo "3. Salir"
    read -r -p "Opción: " opcion

    case $opcion in
        1) mostrar_fecha ;;
        2) mostrar_directorio ;;
        3)
            if salir; then
                echo "Fin"
                break
            fi
            ;;
        *) echo "Opción incorrecta" >&2 ;;
    esac
done
```

La función `salir` devuelve `0` solo si se confirma la salida. Si el usuario
responde otra cosa, devuelve un estado distinto de cero y el bucle continúa.

</details>

<details>
<summary>Solución 8: Resumen seguro de un registro</summary>

```bash
#!/bin/bash

mostrar_uso() {
    echo "Uso: $0 <fichero>" >&2
}

resumir_fichero() {
    local fichero=$1
    local linea
    lineas_vacias=0
    lineas_con_error=0

    while IFS= read -r linea || [[ -n $linea ]]; do
        if [[ -z $linea ]]; then
            lineas_vacias=$((lineas_vacias + 1))
        fi

        case $linea in
            *[Ee][Rr][Rr][Oo][Rr]*)
                lineas_con_error=$((lineas_con_error + 1))
                ;;
        esac
    done < "$fichero"
}

if [[ $# -ne 1 ]]; then
    mostrar_uso
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

resumir_fichero "$fichero" || {
    echo "Error al procesar el fichero" >&2
    exit 1
}

echo "Fichero: $fichero"
echo "Líneas vacías: $lineas_vacias"
echo "Líneas con error: $lineas_con_error"
```

La función se ocupa del procesamiento y actualiza contadores. El bucle usa
`IFS=` y `read -r` para preservar espacios y barras invertidas, y procesa
también la última línea sin salto final. La ruta siempre va entre comillas.
No se imprime el resumen hasta después de validar la entrada.

</details>
