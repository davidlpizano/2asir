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
