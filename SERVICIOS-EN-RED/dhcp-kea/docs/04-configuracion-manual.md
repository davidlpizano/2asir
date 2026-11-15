# Configuración manual

**Navegación:** [Inicio](../README.md) ·
[← Despliegue](03-despliegue-con-vagrant.md) ·
[Siguiente: Pruebas →](05-pruebas-y-validacion.md)

Esta guía explica la estructura y el orden de configuración manual de los
servicios DHCP, VRRP y NAT en Debian. El `Vagrantfile` define la topología, los
scripts de instalación están en [`provision/`](../provision/) y las plantillas
se encuentran en [`config/`](../config/). Los comandos con `sudo` deben
ejecutarse en el servidor indicado.

## Orden de trabajo

1. Prepara las interfaces de red (WAN y LAN), las direcciones estáticas y el
   reenvío de paquetes IPv4.
2. Configura `nftables` para aplicar SNAT hacia la WAN.
3. Configura `keepalived` en `kea1` (`MASTER`, prioridad `100`) y `kea2`
   (`BACKUP`, prioridad `90`) y verifica que las VIPs están activas en `kea1`.
4. Configura `kea-dhcp4` y `kea-ctrl-agent` en ambos nodos, incluyendo el hook
   de alta disponibilidad (`hot-standby`).
5. Configura la ruta por defecto WAN y el servicio `kea-routes.service`.
6. Conecta `cliente1`, solicita una concesión DHCP y valida conectividad y HA.

## Red, forwarding y NAT en `kea1` y `kea2`

1. Instala los paquetes necesarios:

   ```bash
   sudo apt update
   sudo apt install kea-dhcp4-server kea-ctrl-agent keepalived nftables curl chrony
   ```

2. Habilita el encaminamiento IPv4 persistente:

   ```bash
   echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ipforward.conf
   sudo sysctl --system
   ```

3. Configura `/etc/nftables.conf` tomando como referencia
   [`nftables.conf.tmpl`](../config/nftables.conf.tmpl), sustituyendo
   `@@IF_WAN@@` por la interfaz WAN y `@@VIP_WAN@@` por `172.26.32.250`. Luego
   activa el servicio:

   ```bash
   sudo systemctl enable --now nftables
   ```

## Alta disponibilidad de puerta de enlace con Keepalived

1. Adapta [`keepalived.conf.tmpl`](../config/keepalived.conf.tmpl) en
   `/etc/keepalived/keepalived.conf`:
   - En `kea1`: `state MASTER`, `priority 100`.
   - En `kea2`: `state BACKUP`, `priority 90`.
   - Sustituye `@@IF_LAN@@`, `@@IF_WAN@@`, `@@VIP_LAN@@` (`192.168.10.1`) y
     `@@VIP_WAN@@` (`172.26.32.250`).

2. Activa e inicia Keepalived:

   ```bash
   sudo systemctl enable --now keepalived
   sudo systemctl status keepalived --no-pager
   ```

## Configuración de Kea DHCPv4 y HA

1. Crea `/etc/kea/kea-dhcp4.conf` a partir de
   [`kea-dhcp4.json.tmpl`](../config/kea-dhcp4.json.tmpl):
   - Sustituye `@@IF_LAN@@` por la interfaz de la red `192.168.10.0/24`.
   - Sustituye `@@THIS_NAME@@` por `kea1` o `kea2` según el nodo.
   - Sustituye `@@VIP_LAN@@` por `192.168.10.1`.
   - Si deseas usar tus propios servidores DNS internos (por ejemplo del
     [laboratorio DNS](../../dns/README.md)), cambia `"data": "1.1.1.1, 9.9.9.9"`
     por `"192.168.10.10, 192.168.10.11"`.

2. Valida la sintaxis JSON y la configuración de Kea antes de iniciar:

   ```bash
   sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
   ```

3. Activa los servicios de Kea:

   ```bash
   sudo systemctl enable --now kea-dhcp4-server kea-ctrl-agent
   sudo systemctl status kea-dhcp4-server --no-pager
   ```

## Rutas de salida en los routers Kea

En entornos Vagrant donde exista una interfaz NAT auxiliar (`10.0.2.x`),
conviene asegurar que la ruta por defecto apunte al gateway WAN real
(`172.26.0.1`). Consulta [`kea-fix-routes.sh.tmpl`](../config/kea-fix-routes.sh.tmpl)
y [`kea-routes.service`](../config/kea-routes.service).

## Diferencia entre el ejemplo y producción

Esta guía no constituye un procedimiento universal de instalación: interfaces,
nombres de paquetes, servicios, permisos y sockets dependen de la versión y del
sistema. En producción se requieren controles adicionales, como protección de
las APIs de Kea, cifrado TLS en los endpoints HA, filtrado de tráfico,
supervisión y copias de seguridad.
