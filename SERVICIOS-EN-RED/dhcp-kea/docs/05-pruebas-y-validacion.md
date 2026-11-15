# Pruebas y validación

**Navegación:** [Inicio](../README.md) ·
[← Configuración manual](04-configuracion-manual.md) ·
[Siguiente: Resolución de problemas →](06-resolucion-de-problemas.md)

Ejecuta primero las comprobaciones locales en `kea1` y `kea2`, y después las
pruebas desde `cliente1`.

## 1. Validar configuración y servicios en `kea1` y `kea2`

En ambos nodos:

```bash
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
sudo systemctl is-active kea-dhcp4-server kea-ctrl-agent keepalived nftables
sudo journalctl -u kea-dhcp4-server -n 50 --no-pager
```

Comprueba en qué nodo están las VIPs (`192.168.10.1` y `172.26.32.250`):

```bash
ip -4 address
```

En condiciones normales, ambas VIPs deben estar presentes en `kea1` (`MASTER`).

## 2. Validar el estado del hook HA

En `kea1` o `kea2`, verifica que ambos peers escuchan en el puerto `8001` y
que la comunicación HA funciona:

```bash
ss -tlnp | grep 8001
sudo journalctl -u kea-dhcp4-server | grep -i -E "ha_|hot-standby|partner" | tail -n 20
```

También puedes inspeccionar el fichero de concesiones sincronizado en ambos
nodos:

```bash
sudo cat /var/lib/kea/kea-leases4.csv
```

## 3. Validar dirección DHCP y ruta en `cliente1`

Desde `cliente1`:

```bash
ip -4 address
ip route
cat /etc/resolv.conf
```

Verifica:

- IP asignada dentro del rango `192.168.10.100–192.168.10.200`.
- Ruta predeterminada apuntando a `192.168.10.1`.
- Servidores DNS `1.1.1.1` y `9.9.9.9` (o los configurados en `option-data`).

Para forzar una renovación DHCP desde `cliente1`:

```bash
sudo dhclient -r enp0s8
sudo dhclient -v -H portatil-ana enp0s8
```

*(Sustituye `enp0s8` por el nombre real de tu interfaz LAN en `cliente1`.)*

## 4. Validar conectividad a través del router virtual (NAT)

Desde `cliente1`:

```bash
ping -c 3 192.168.10.1
ping -c 3 192.168.10.2
ping -c 3 192.168.10.3
```

Si la red WAN configurada tiene salida a Internet:

```bash
curl -I https://example.com
```

## 5. Probar la conmutación por fallo (HA y Keepalived)

Solo en una red aislada de laboratorio:

1. Detén temporalmente Kea o Keepalived en `kea1` (o apaga `kea1` con
   `vagrant halt kea1`).
2. Comprueba en `kea2` que ha asumido las VIPs (`ip -4 address`) y el servicio
   DHCP activo en los logs (`sudo journalctl -u kea-dhcp4-server -f`).
3. Solicita o renueva una concesión desde `cliente1` y comprueba que sigue
   recibiendo IP y saliendo por `192.168.10.1`.
4. Vuelve a arrancar `kea1` y verifica que recupera el rol `MASTER` en
   Keepalived y sincroniza el estado en Kea HA.
