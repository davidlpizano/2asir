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

## Uso de directorios y archivos con `du`

`du` calcula el espacio ocupado por archivos y directorios. A diferencia de
`df`, que informa del espacio de los sistemas de archivos, `du` permite
localizar qué directorios están usando ese espacio.

| Opción | Función |
| --- | --- |
| `-h` | Muestra los tamaños en unidades legibles. |
| `-s` | Muestra únicamente el total de cada ruta indicada. |
| `-a` | Incluye también los archivos, no solo los directorios. |
| `--max-depth=N` | Limita el resultado a `N` niveles por debajo de la ruta. |

### Ejemplos

```bash
# Mostrar el tamaño total del directorio actual
du -sh .

# Mostrar el tamaño de cada directorio del nivel actual
du -h --max-depth=1 .

# Mostrar el tamaño de un directorio concreto
du -sh /var/log

# Incluir archivos en el resultado
du -ah .
```

## Actividad de disco con `iostat`

`iostat`, incluido en el paquete `sysstat`, muestra estadísticas de actividad
de la CPU y de los dispositivos de almacenamiento. A diferencia de `df` y
`du`, permite observar operaciones de entrada y salida y su rendimiento a lo
largo del tiempo.

| Opción | Función |
| --- | --- |
| `-c` | Muestra estadísticas de uso de la CPU. |
| `-d` | Muestra estadísticas de los dispositivos. |
| `-x` | Añade estadísticas extendidas de los dispositivos. |
| `-z` | Omite los dispositivos sin actividad durante el intervalo. |

### Ejemplos

```bash
# Mostrar estadísticas de CPU y dispositivos
iostat

# Mostrar estadísticas extendidas de disco cada segundo, cinco informes
iostat -dx 1 5

# Mostrar estadísticas extendidas y omitir dispositivos inactivos
iostat -dxz 1
```

En las estadísticas extendidas, `await` indica el tiempo medio de espera de
las operaciones, en milisegundos, y `%util` el porcentaje de tiempo durante
el que el dispositivo estuvo ocupado. El primer informe resume la actividad
desde el arranque; los siguientes corresponden a los intervalos solicitados.
