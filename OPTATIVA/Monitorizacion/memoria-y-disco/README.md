# Memoria y disco

Linux ofrece herramientas sencillas para consultar el uso de la memoria RAM,
la memoria de intercambio (**swap**) y el espacio disponible en los sistemas
de archivos.

## Memoria RAM y swap con `free`

`free` muestra un resumen de la memoria total, utilizada y disponible.
La columna `available` estima cuánta memoria pueden usar las aplicaciones sin
necesidad de recurrir a swap.

| Opción | Función |
| --- | --- |
| `-h` | Presenta los tamaños en unidades legibles, como MiB o GiB. |
| `-c N` | Muestra `N` actualizaciones y termina. |
| `-s N` | Actualiza cada `N` segundos; continúa hasta interrumpirlo con `Ctrl+C`. |

### Ejemplos

```bash
# Mostrar la memoria en unidades legibles
free -h

# Mostrar cinco actualizaciones
free -h -c 5

# Actualizar cada dos segundos
free -h -s 2
```

También se puede combinar el intervalo con un número limitado de muestras:

```bash
free -h -s 2 -c 5
```

## Espacio en disco con `df`

`df` informa del espacio total, usado y disponible en los sistemas de archivos
montados. Con `-h`, los tamaños se muestran en unidades legibles.

| Opción | Función |
| --- | --- |
| `-h` | Muestra los tamaños en unidades legibles. |
| `-T` | Añade el tipo de sistema de archivos. |
| `-i` | Muestra el uso de inodos en lugar del espacio en bloques. |

### Ejemplos

```bash
# Consultar el espacio de todos los sistemas de archivos
df -h

# Consultar el espacio y el tipo de sistema de archivos
df -hT

# Comprobar el espacio disponible en la ruta actual
df -h .

# Consultar el uso de inodos
df -i
```
