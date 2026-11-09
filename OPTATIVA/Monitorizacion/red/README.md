# Tráfico de la red

## Captura de tráfico con `tcpdump`

Instala `tcpdump` con `sudo apt install tcpdump` en Debian/Ubuntu o con
`sudo dnf install tcpdump` en Fedora.

`tcpdump` captura y muestra paquetes que circulan por una interfaz de red.
Normalmente requiere permisos de administrador. Usa filtros para limitar la
captura a los paquetes relevantes y evitar registrar tráfico innecesario.

| Opción | Función |
| --- | --- |
| `-i INTERFAZ` | Selecciona la interfaz de red; `any` captura en todas las interfaces compatibles. |
| `-n` | Evita resolver direcciones IP y puertos a nombres. |
| `-c N` | Termina después de capturar `N` paquetes. |
| `-v` | Aumenta el detalle de la salida; se puede repetir (`-vv`, `-vvv`) para mostrar más información. |
| `-w ARCHIVO` | Guarda los paquetes capturados en un archivo `.pcap`. |
| `-r ARCHIVO` | Lee y muestra paquetes desde un archivo `.pcap`. |
| `-X` | Muestra el contenido de los paquetes en hexadecimal y ASCII. |

### Ejemplos

```bash
# Listar las interfaces disponibles
sudo tcpdump -D

# Capturar diez paquetes en una interfaz concreta
sudo tcpdump -i eth0 -n -c 10

# Capturar tráfico dirigido al puerto 53
sudo tcpdump -i eth0 -n 'port 53'

# Guardar una captura para analizarla más tarde
sudo tcpdump -i eth0 -n -c 100 -w captura.pcap

# Leer una captura guardada
tcpdump -n -r captura.pcap
```

Los filtros pueden combinarse; por ejemplo, `host 192.0.2.10 and port 443`
selecciona tráfico del host indicado por el puerto 443. Sustituye `eth0` por
una interfaz disponible en el sistema y captura únicamente tráfico que estés
autorizado a analizar.

## Seguimiento de conexiones TCP con `tcptrack`

Instala `tcptrack` con `sudo apt install tcptrack` en Debian/Ubuntu o con
`sudo dnf install tcptrack` en Fedora si el paquete está disponible en los
repositorios configurados.

`tcptrack` muestra en tiempo real las conexiones TCP activas, incluyendo las
direcciones y puertos de origen y destino, el estado y el volumen de datos
transferidos. Requiere permisos de administrador y una interfaz de red válida.

| Opción | Función |
| --- | --- |
| `-i INTERFAZ` | Captura el tráfico de la interfaz indicada. |
| `-f FILTRO` | Limita la captura con una expresión de filtro de tipo BPF. |
| `-r SEGUNDOS` | Define el intervalo de actualización de la pantalla. |

### Ejemplos

```bash
# Seguir las conexiones TCP de una interfaz
sudo tcptrack -i eth0

# Mostrar conexiones relacionadas con el puerto 443
sudo tcptrack -i eth0 -f 'port 443'

# Actualizar la pantalla cada dos segundos
sudo tcptrack -i eth0 -r 2
```

`tcptrack` muestra conexiones TCP, no sustituye a una captura general de
paquetes como `tcpdump`. Sustituye `eth0` por una interfaz disponible en el
sistema y monitoriza únicamente tráfico que estés autorizado a analizar.

## Monitorización de red con `iptraf`

En las distribuciones actuales, IPTraf suele instalarse como `iptraf-ng`.
Instálalo con `sudo apt install iptraf-ng` en Debian/Ubuntu o con
`sudo dnf install iptraf-ng` en Fedora. En algunas distribuciones el ejecutable
puede llamarse `iptraf`.

IPTraf ofrece una interfaz interactiva para consultar estadísticas de tráfico
IP, actividad general de las interfaces y estadísticas de servicios TCP/UDP.
Requiere permisos de administrador para capturar tráfico.

| Opción | Función |
| --- | --- |
| `-i INTERFAZ` | Inicia el monitor de tráfico IP para la interfaz indicada. |
| `-g` | Muestra estadísticas generales de las interfaces. |
| `-d INTERFAZ` | Muestra estadísticas detalladas de la interfaz indicada. |
| `-s INTERFAZ` | Muestra estadísticas de servicios TCP/UDP de la interfaz. |

### Ejemplos

```bash
# Abrir el menú interactivo
sudo iptraf-ng

# Monitorizar el tráfico IP de una interfaz
sudo iptraf-ng -i eth0

# Consultar estadísticas detalladas de la interfaz
sudo iptraf-ng -d eth0

# Consultar estadísticas de servicios TCP/UDP
sudo iptraf-ng -s eth0
```

Sustituye `eth0` por una interfaz disponible en el sistema y monitoriza
únicamente tráfico que estés autorizado a analizar.

## Monitorización del ancho de banda con `bmon`

Instala `bmon` con `sudo apt install bmon` en Debian/Ubuntu o con
`sudo dnf install bmon` en Fedora.

`bmon` presenta en una interfaz interactiva las tasas de tráfico de entrada y
salida de las interfaces de red. Permite observar el uso del ancho de banda
en tiempo real, sin capturar ni mostrar el contenido de los paquetes.

| Opción | Función |
| --- | --- |
| `-p INTERFACES` | Limita la vista a las interfaces indicadas, separadas por comas. |

### Ejemplos

```bash
# Monitorizar todas las interfaces
bmon

# Monitorizar una interfaz concreta
bmon -p eth0

# Monitorizar dos interfaces
bmon -p eth0,wlan0
```

Sustituye los nombres de ejemplo por las interfaces disponibles en el sistema.

## Conexiones y sockets con `ss`

`ss` suele venir incluido en el paquete `iproute2`. Si no está instalado,
instálalo con `sudo apt install iproute2` en Debian/Ubuntu o con
`sudo dnf install iproute` en Fedora.

`ss` muestra sockets y conexiones de red. Permite consultar puertos en escucha,
conexiones TCP o UDP y los procesos asociados. No suele necesitar permisos de
administrador, aunque `sudo` permite ver información de todos los procesos.

| Opción | Función |
| --- | --- |
| `-t` | Muestra sockets TCP. |
| `-u` | Muestra sockets UDP. |
| `-l` | Muestra sockets en escucha. |
| `-n` | Muestra direcciones y puertos numéricos, sin resolver nombres. |
| `-p` | Muestra el proceso asociado al socket; puede requerir `sudo`. |
| `-a` | Muestra sockets en escucha y no escucha. |
| `-4` / `-6` | Limita los resultados a IPv4 o IPv6. |

### Ejemplos

```bash
# Mostrar todas las conexiones TCP
ss -t -a

# Mostrar puertos TCP en escucha con direcciones numéricas
ss -t -l -n

# Mostrar puertos TCP y UDP en escucha y los procesos asociados
sudo ss -plunt

# Mostrar conexiones TCP establecidas
ss -t -o state established
```
