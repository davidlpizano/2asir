# Resolución de problemas

**Navegación:** [Inicio](../README.md) ·
[← Pruebas y validación](05-pruebas-y-validacion.md)

## `kea-dhcp4 -t` devuelve errores de sintaxis

Revisa el fichero `/etc/kea/kea-dhcp4.conf` en la línea indicada. Los errores
más frecuentes en JSON son una coma sobrante tras el último elemento de una
lista o bloque, comillas sin cerrar o un marcador `@@...@@` sin sustituir.

## Kea HA no establece conexión con el otro nodo

Confirma que la librería `libdhcp_ha.so` está instalada y cargada, que
`this-server-name` identifica al nodo actual (`kea1` o `kea2`) y que las URL de
los peers (`http://192.168.10.2:8001/` y `http://192.168.10.3:8001/`) son
alcanzables entre sí. Comprueba que `chrony` mantiene la hora sincronizada y
revisa los logs de `kea-dhcp4-server`. El Control Agent es una interfaz de
administración distinta; no la expongas fuera de la LAN de laboratorio.

## Keepalived no asigna las VIPs o ambos nodos quedan en `MASTER`

- Comprueba que la red interna `lan_asir` permite el tráfico multicast VRRP y
  que `nicpromisc` está habilitado en VirtualBox.
- Verifica que los nombres de interfaz en `/etc/keepalived/keepalived.conf`
  coinciden exactamente con los del sistema (`ip -br link`).
- Confirma que `virtual_router_id` y `auth_pass` son idénticos en `kea1` y
  `kea2`, y que la prioridad es distinta (`100` frente a `90`).

## El cliente no recibe concesión DHCP

Comprueba que `cliente1` está conectado a `lan_asir`, que la interfaz LAN se
detecta correctamente en las VMs, que `kea-dhcp4-server` escucha en ella y que
la VIP `192.168.10.1` está presente. Asegúrate de arrancar y aprovisionar
primero `kea1` y `kea2`, y después `cliente1`. Si el cliente arrancó antes,
ejecuta `vagrant provision cliente1` o renueva con `dhclient`.

## No hay acceso a Internet desde la LAN del laboratorio

Verifica IP, prefijo, gateway WAN (`172.26.0.1`), rutas por defecto y que la
WAN VIP (`172.26.32.250`) sea alcanzable en la red puente. Comprueba en `kea1`
el forwarding IPv4 (`sysctl net.ipv4.ip_forward`) y las reglas de `nftables`
(`sudo nft list ruleset`). La IP `172.26.0.1` es solo un supuesto del ejemplo y
puede no ser el router de tu red.

## Vagrant no encuentra la interfaz puente

Revisa el nombre con `ip -br link` (en Linux) o `Get-NetAdapter` (en Windows) y
define `IF_BRIDGE` con el valor adecuado. Confirma también que VirtualBox
permite el modo puente en esa interfaz y que el usuario tiene permisos para
administrar las VMs.
