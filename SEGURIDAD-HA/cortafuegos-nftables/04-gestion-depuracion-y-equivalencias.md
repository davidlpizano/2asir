# 4. Gestión, equivalencias y depuración

**Navegación:** [Inicio](README.md) ·
[← Plantillas y escenarios](03-plantillas-y-escenarios.md) ·
[Siguiente: Errores frecuentes y ejercicios →](05-errores-frecuentes-y-autoevaluacion.md)

## 4.1 Gestión diaria y persistencia

| Comando | Propósito |
| --- | --- |
| `sudo nft -c -f /etc/nftables.conf` | Validar sintaxis y referencias de interfaces **sin aplicar** cambios. |
| `sudo nft -f /etc/nftables.conf` | Aplicar el fichero de forma atómica. |
| `sudo nft list ruleset` | Mostrar todas las tablas, cadenas y reglas activas en memoria. |
| `sudo nft -a list ruleset` | Mostrar el conjunto de reglas incluyendo el identificador numérico **`handle`** de cada regla. |
| `sudo nft delete rule inet filtro input handle 7` | Eliminar una regla concreta usando su `handle`. |
| `sudo nft flush ruleset` | Vaciar completamente el cortafuegos en memoria (útil en emergencias locales). |
| `sudo systemctl enable --now nftables` | Habilitar el servicio para que cargue `/etc/nftables.conf` en cada arranque. |
| `sudo systemctl status nftables --no-pager` | Comprobar el estado del servicio y posibles errores de carga. |

### Truco anti-bloqueo al administrar por SSH

Cuando trabajes de forma remota sobre un servidor en producción, aplica
cambios de prueba con reversión automática tras un tiempo prudencial:

```bash
sudo nft -f /etc/nftables.conf.nuevo && sleep 120 && sudo nft -f /etc/nftables.conf
```

- Si tras aplicar `/etc/nftables.conf.nuevo` sigues teniendo acceso SSH, pulsa
  `Ctrl+C` antes de 120 segundos y sustituye `/etc/nftables.conf` por el nuevo.
- Si una regla te bloquea el acceso, pasados 2 minutos se restaurará
  automáticamente el fichero anterior y recuperarás la conexión.

## 4.2 Equivalencias rápidas: `iptables` $\leftrightarrow$ `nftables`

| Concepto | `iptables` | `nftables` |
| --- | --- | --- |
| IP origen / destino | `-s 10.0.0.0/8` / `-d 8.8.8.8` | `ip saddr 10.0.0.0/8` / `ip daddr 8.8.8.8` |
| Interfaz entrada / salida | `-i enp3s0` / `-o enp1s0` | `iif enp3s0` / `oif enp1s0` (o `iifname` / `oifname`) |
| Varios puertos | `-m multiport --dports 80,443` | `tcp dport { 80, 443 }` |
| Estado de conexión | `-m conntrack --ctstate ESTABLISHED,RELATED` | `ct state established,related` |
| Acciones | `-j ACCEPT` / `-j DROP` / `-j REJECT` | `accept` / `drop` / `reject` |
| Enmascarar salida | `-t nat -A POSTROUTING -o eth0 -j MASQUERADE` | `oifname "eth0" masquerade` |
| Redirección de puerto | `-t nat -A PREROUTING -i eth0 -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.10:80` | `iifname "eth0" tcp dport 8080 dnat ip to 192.168.1.10:80` |
| Traductor automático | `iptables-translate <regla>` | Genera en pantalla el equivalente en sintaxis `nft`. |

Ejemplo de uso de `iptables-translate` (paquete `iptables`):

```bash
iptables-translate -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
# Salida: nft 'add rule ip filter INPUT tcp dport 22 ct state new counter accept'
```

## 4.3 Herramientas de verificación y diagnóstico

### 1. Contadores por regla (`counter`)

Añadir `counter` antes del veredicto permite comprobar cuántos paquetes y bytes
han coincidido exactamente con una regla concreta:

```nft
iifname "enp3s0" oifname "enp1s0" counter accept
```

Al ejecutar `sudo nft list ruleset`, verás algo como `counter packets 42 bytes 3528`.
Si los contadores permanecen a `0`, el tráfico no está llegando a esa regla (o se
quedó en una cadena/regla anterior).

### 2. Registro en log (`log prefix`)

Coloca una regla `log` justo antes de un `drop` o al final de la cadena (antes
de aplicar la política por defecto) para saber qué tráfico se está descartando:

```nft
log prefix "[FWD-DROP] " level warn drop
```

Consulta los eventos en tiempo real con:

```bash
sudo journalctl -k -f
```

> [!WARNING]
> En reglas expuestas a Internet con mucho tráfico, conviene combinar `log`
> con `limit rate` (por ejemplo, `limit rate 5/minute log prefix "[DROP] "`)
> para evitar saturar el disco o los logs del sistema.

### 3. Captura de tráfico (`tcpdump`)

`tcpdump` permite observar los paquetes tal como entran o salen en cada
interfaz, lo que resulta muy útil para comprobar si el NAT está traduciendo las
direcciones correctamente:

```bash
sudo tcpdump -ni enp3s0 icmp          # Ver tráfico original en la LAN
sudo tcpdump -ni enp1s0 icmp          # Ver tráfico ya traducido (SNAT/MASQUERADE) en la WAN
```

### 4. Inspección de la tabla de estados (`conntrack`)

El comando `conntrack` (paquete `conntrack`) muestra las conexiones activas y
las traducciones NAT en curso:

```bash
sudo conntrack -L
sudo conntrack -L -p tcp --dport 80
```

### 5. Comprobación de puertos locales (`ss`)

Antes de diagnosticar un bloqueo de `INPUT` o `DNAT`, verifica que el servicio
realmente está escuchando en la IP y puerto esperados:

```bash
sudo ss -tulpn
```
