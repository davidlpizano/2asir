# 2. Arquitectura y sintaxis de `nftables`

**Navegación:** [Inicio](README.md) ·
[← Fundamentos](01-fundamentos-netfilter-y-nat.md) ·
[Siguiente: Plantillas y escenarios →](03-plantillas-y-escenarios.md)

## 2.1 Estructura jerárquica

`nftables` organiza las reglas en cuatro niveles claros:

```text
Familia ──► Tabla (nombre libre) ──► Cadena (nombre libre) ──► Reglas
```

A diferencia de `iptables`, **no existen tablas ni cadenas predefinidas
obligatorias**: el administrador elige los nombres de las tablas y cadenas, y
define explícitamente en qué puntos del kernel se enganchan.

### Familias principales

| Familia | Alcance | Observaciones |
| --- | --- | --- |
| `ip` | Solo IPv4 | Útil cuando se quiere separar estrictamente reglas IPv4. |
| `ip6` | Solo IPv6 | Útil cuando se gestiona IPv6 de forma independiente. |
| **`inet`** | **IPv4 e IPv6 simultáneos** | **Familia recomendada.** Evita duplicar reglas comunes. Soporta NAT desde kernel $\ge 5.2$ y `nftables` $\ge 0.9.1$ (Debian 11+). |
| `arp` | Tramas ARP | Filtrado específico de resolución de direcciones en IPv4. |
| `bridge` | Puentes Ethernet | Filtrado en capa 2 sobre *bridges* Linux. |
| `netdev` | Interfaz en ingreso | Filtrado muy temprano por tarjeta antes de llegar a capas superiores. |

> [!TIP]
> Dentro de una tabla `inet`, algunas expresiones siguen distinguiendo
> protocolo cuando hacen referencia a cabeceras específicas: por ejemplo,
> `ip saddr` / `dnat ip to` para IPv4 o `icmpv6 type` para IPv6, mientras que
> `tcp dport`, `udp dport` o `ct state` funcionan de forma unificada para ambos.

### Cadenas base vs. cadenas regulares

- **Cadena base:** se engancha directamente a un *hook* de Netfilter mediante
  una declaración de cabecera:

  ```nft
  chain input {
      type filter hook input priority filter; policy drop;
  }
  ```

  Sus parámetros son:
  - **`type`:** `filter` (filtrado), `nat` (traducción de direcciones) o `route`
    (reenrutado tras modificar campos como marcas o IP).
  - **`hook`:** punto de enganche en el flujo de red (`prerouting`, `input`,
    `forward`, `output`, `postrouting`).
  - **`priority`:** entero (o alias estándar) que fija el orden de ejecución
    cuando varias cadenas comparten hook (menor número se evalúa antes):
    - `-100` (`dstnat`) para cadenas de `DNAT` en `prerouting`.
    - `0` (`filter`) para filtrado estándar en `input`, `forward` y `output`.
    - `100` (`srcnat`) para cadenas de `SNAT`/`MASQUERADE` en `postrouting`.
  - **`policy`:** veredicto por defecto si el paquete recorre toda la cadena
    sin coincidir con ninguna regla (`accept` o `drop`).

- **Cadena regular:** no lleva `type`/`hook`/`priority` ni `policy`. Sirve
  como subrutina para modularizar reglas y se invoca desde otra cadena con
  `jump <cadena>` (retorna al terminar) o `goto <cadena>` (no retorna).

## 2.2 Veredictos e interfaces

### Veredictos principales

- **`accept`:** permite el paso del paquete y finaliza la evaluación en la
  cadena actual.
- **`drop`:** descarta el paquete en silencio sin enviar respuesta al emisor. Es
  la opción recomendada para tráfico entrante desde **Internet** (evita revelar
  información sobre puertos cerrados o consumir ancho de banda respondiendo a
  escaneos).
- **`reject`:** descarta el paquete y devuelve inmediatamente un aviso ICMP o
  TCP RST al emisor. Es ideal hacia la **LAN**, porque evita largos tiempos de
  espera (*timeouts*) en las aplicaciones cliente y facilita detectar fallos.
- **`log prefix "..."`:** sentencia no terminal que registra el paquete en el
  log del kernel (`dmesg` / `journalctl -k`) y continúa evaluando la regla
  siguiente.

### Comparación de interfaces: `iif`/`oif` vs. `iifname`/`oifname`

| Forma | Cómo compara | Ventajas e inconvenientes |
| --- | --- | --- |
| `iif` / `oif` | Compara por el índice numérico interno de la interfaz. | Más rápido, pero **falla al cargar** la configuración si la interfaz aún no existe al arrancar `nftables` (túneles VPN `tun0`, `wg0`, interfaces PPP, etc.). |
| `iifname` / `oifname` | Compara por el nombre de texto de la interfaz (acepta comodines como `"eth*"`). | Algo menos rápido por comparación de cadena, pero **no falla** si la interfaz es dinámica o aparece más tarde. |

## 2.3 Conjuntos (*sets*), mapas y limitación de tasa

`nftables` incorpora de forma nativa estructuras de datos que en `iptables`
requerían extensiones externas (`ipset`):

### Conjuntos anónimos

Permiten agrupar múltiples valores directamente en una regla:

```nft
tcp dport { 22, 80, 443 } accept
ip saddr { 192.168.10.0/24, 10.20.0.0/16 } accept
```

### Conjuntos nombrados (`set`)

Se declaran en la tabla y permiten añadir o eliminar IPs/redes en caliente sin
recargar todo el cortafuegos:

```nft
table inet filtro {
    set lista_negra {
        type ipv4_addr
        flags interval
    }

    chain input {
        type filter hook input priority filter; policy drop;
        ip saddr @lista_negra drop
    }
}
```

Actualización dinámica desde consola:

```bash
sudo nft add element inet filtro lista_negra { 203.0.113.66, 198.51.100.0/24 }
sudo nft delete element inet filtro lista_negra { 203.0.113.66 }
sudo nft list set inet filtro lista_negra
```

### Mapas (`map`)

Asocian una clave de búsqueda con un valor de destino, reduciendo decenas de
reglas a una sola línea. Por ejemplo, publicar varios puertos internos con
`DNAT`:

```nft
dnat ip to tcp dport map { 8080 : 192.168.1.10, 8443 : 192.168.1.11 }
```

Si también cambia el puerto de destino, puede utilizarse concatenación (`ip . port`
o `dnat ip to tcp dport map { 8080 : 192.168.1.10 . 80, 8443 : 192.168.1.11 . 443 }`).

### Limitación de tasa (`limit rate`)

Permite acotar la frecuencia con la que se aceptan nuevas conexiones o paquetes
ICMP para mitigar ataques de fuerza bruta o inundaciones:

```nft
tcp dport 22 ct state new limit rate 3/minute accept
icmp type echo-request limit rate 5/second accept
```

También pueden combinarse contadores y ráfagas (`burst`), por ejemplo:
`limit rate 5/second burst 10 packets accept`.
