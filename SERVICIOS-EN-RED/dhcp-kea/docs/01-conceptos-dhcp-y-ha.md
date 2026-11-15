# Conceptos DHCP y alta disponibilidad con Kea

**Navegación:** [Inicio](../README.md) ·
[Siguiente: Arquitectura →](02-arquitectura-y-requisitos.md)

## Funcionamiento de DHCPv4

El protocolo DHCP (*Dynamic Host Configuration Protocol*) automatiza la
asignación de parámetros de red IPv4 a los clientes mediante el intercambio DORA:

1. **Discover:** el cliente envía una difusión en la red local buscando un
   servidor DHCP.
2. **Offer:** el servidor ofrece una dirección IP del rango configurado junto
   con máscara, puerta de enlace, DNS y tiempos de concesión.
3. **Request:** el cliente solicita formalmente la dirección ofrecida.
4. **Acknowledge:** el servidor confirma la concesión y registra el
   arrendamiento (*lease*).

## Parámetros clave de una concesión

- **Pool dinámico (`pools`):** intervalo de direcciones asignables
  automáticamente (en este laboratorio, `192.168.10.100 - 192.168.10.200`).
- **Reservas estáticas (`reservations`):** asociación fija entre dirección MAC
  (`hw-address`) e IP fuera del pool dinámico, por ejemplo para impresoras o
  servidores.
- **Opciones DHCP (`option-data`):** parámetros adicionales entregados al
  cliente, como la puerta de enlace (`routers`), los servidores DNS
  (`domain-name-servers`) y el sufijo de búsqueda (`domain-name`).
- **Temporizadores:** `valid-lifetime` (duración total de la concesión),
  `renew-timer` (T1, momento en que el cliente intenta renovar con el mismo
  servidor) y `rebind-timer` (T2, momento en que busca cualquier servidor
  disponible si el original no responde).

## Arquitectura de ISC Kea

A diferencia del clásico `isc-dhcp-server`, Kea es modular y configura sus
servicios en formato JSON:

- **`kea-dhcp4`:** demonio principal encargado de atender peticiones DHCPv4.
- **`kea-ctrl-agent`:** agente REST/socket de control para consultar estado y
  administrar el servicio.
- **Base de datos de concesiones (`memfile`):** fichero CSV persistente
  (`/var/lib/kea/kea-leases4.csv`) donde se almacenan los arrendamientos activos.
- **Hooks:** librerías cargadas dinámicamente que amplían funciones, como
  `libdhcp_lease_cmds.so` (gestión de concesiones) y `libdhcp_ha.so` (alta
  disponibilidad).

## Alta disponibilidad en Kea (`hot-standby`)

El hook `libdhcp_ha.so` permite coordinar dos servidores Kea (`kea1` y `kea2`)
para tolerar la caída de uno de ellos:

- En modo **`hot-standby`**, el nodo **`primary`** (`kea1`) atiende todas las
  concesiones mientras esté sano y replica los cambios de leases al nodo
  **`standby`** (`kea2`) mediante HTTP (`http://192.168.10.2:8001/` y
  `http://192.168.10.3:8001/`).
- Ambos nodos intercambian latidos periódicos (`heartbeat-delay`). Si el nodo
  primario deja de responder superando los umbrales configurados
  (`max-response-delay`, `max-unacked-clients`), el secundario asume el
  servicio DHCP automáticamente.

## Redundancia de puerta de enlace con Keepalived (VRRP)

La alta disponibilidad de DHCP no basta si el router por defecto de los clientes
es un único equipo. Para evitar ese punto único de fallo:

- **Keepalived** implementa el protocolo VRRP entre `kea1` (estado `MASTER`,
  prioridad `100`) y `kea2` (estado `BACKUP`, prioridad `90`).
- Ambos comparten dos direcciones virtuales (VIP) sincronizadas mediante
  `vrrp_sync_group`:
  - **VIP LAN:** `192.168.10.1/24`, entregada por DHCP como puerta de enlace.
  - **VIP WAN:** `172.26.32.250/16`, usada por `nftables` para realizar SNAT.
- Si `kea1` cae o pierde una interfaz monitorizada (`track_interface`), `kea2`
  toma ambas VIPs de forma transparente para los clientes.

## Integración opcional con DNS dinámico (DDNS)

En entornos combinados con servidores BIND 9 (véase el
[laboratorio DNS](../../dns/README.md)), Kea puede incluir el servicio adicional
`kea-dhcp-ddns-server` para registrar automáticamente los nombres de los clientes
en las zonas DNS directa e inversa mediante claves TSIG. En este laboratorio
autónomo esa integración está desacoplada para centrarse en DHCPv4, HA, VRRP y
NAT.
