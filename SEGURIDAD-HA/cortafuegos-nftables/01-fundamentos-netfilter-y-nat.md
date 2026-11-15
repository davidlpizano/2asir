# 1. Fundamentos de Netfilter, caminos y NAT

**Navegación:** [Inicio](README.md) ·
[Siguiente: Arquitectura y sintaxis →](02-arquitectura-y-sintaxis-nftables.md)

## 1.1 Netfilter y `nftables`

- **Netfilter** es el subsistema del núcleo Linux encargado de inspeccionar,
  filtrar, modificar y hacer seguimiento de los paquetes de red.
- **`nftables`** (administrado con el comando `nft`) es el marco de trabajo y la
  herramienta de espacio de usuario predeterminada en Debian desde Debian 10
  en adelante, sustituyendo al conjunto clásico `iptables` / `ip6tables` /
  `arptables` / `ebtables`.

> [!CAUTION]
> En distribuciones Debian modernas, el comando `iptables` utiliza por debajo
> la capa de compatibilidad `iptables-nft`. Aunque ambos acaban en el mismo
> subsistema del kernel, **nunca deben mezclarse reglas de `iptables` y de
> `nft` en la misma máquina**, ya que generan tablas separadas difíciles de
> depurar y pueden provocar bloqueos inesperados o comportamientos
> contradictorios al hacer `flush ruleset`.

## 1.2 Los tres caminos de un paquete

Antes de escribir ninguna regla, hay que identificar qué camino sigue el
tráfico respecto al propio equipo:

1. **`INPUT`:** tráfico dirigido a un proceso local que escucha en la propia
   máquina (por ejemplo, una conexión SSH al puerto 22 del servidor o una
   consulta DNS hacia un BIND local).
2. **`OUTPUT`:** tráfico originado por la propia máquina hacia el exterior (por
   ejemplo, `apt update`, consultas DNS salientes o peticiones `curl`).
3. **`FORWARD`:** tráfico que **atraviesa** la máquina entrando por una interfaz
   y saliendo por otra (por ejemplo, un cliente de la LAN que navega por
   Internet a través de un router/cortafuegos Linux).

```text
Red externa ──► [prerouting] ──┬──► [input] ──► Máquina local ──► [output] ──┐
                               │                                              ▼
                               └──────────────► [forward] ──────────────► [postrouting] ──► Red interna/externa
```

Un error habitual es colocar en `INPUT` reglas pensadas para proteger o
permitir el tráfico de clientes que están detrás del router: ese tráfico nunca
pasa por `INPUT`, sino por `FORWARD`.

## 1.3 Reenvío IP (`ip_forward`)

Por seguridad, el núcleo Linux trae desactivado el reenvío de paquetes entre
interfaces (`net.ipv4.ip_forward = 0`). Un equipo configurado así actúa como
*host* final y descarta cualquier paquete que no tenga como destino una de sus
propias direcciones IP.

Para que el equipo funcione como **router**, **pasarela NAT** o **cortafuegos
perimetral** (es decir, para que los paquetes lleguen a la cadena `FORWARD`),
es imprescindible habilitar el reenvío IP en el kernel.

En sistemas Debian recientes (como Debian 13, donde ya no se emplea
`/etc/sysctl.conf` por defecto), se configura de forma persistente mediante un
fichero dedicado dentro de `/etc/sysctl.d/`:

```bash
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-forward.conf
sudo sysctl --system
```

Si también se va a enrutar tráfico IPv6 entre interfaces, se añade del mismo
modo:

```bash
echo "net.ipv6.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.d/99-forward.conf
sudo sysctl --system
```

Para comprobar el valor activo en caliente:

```bash
sysctl net.ipv4.ip_forward
```

## 1.4 Seguimiento de conexiones (`conntrack`)

El cortafuegos moderno es **con estado** (*stateful*). En lugar de evaluar cada
paquete de forma aislada, el módulo `conntrack` del kernel recuerda las
conexiones activas y clasifica cada paquete en uno de estos estados:

| Estado | Significado | Uso habitual en reglas |
| --- | --- | --- |
| `new` | Primer paquete que intenta iniciar una conexión aún no registrada. | Controlar qué servicios nuevos pueden abrirse y limitar tasas (`limit rate`). |
| `established` | Paquete que pertenece a una conexión ya vista en ambos sentidos. | Permitir el tráfico de retorno sin abrir todos los puertos altos manualmente. |
| `related` | Conexión nueva asociada a otra ya existente (por ejemplo, mensajes ICMP de error como *Destination Unreachable* o canales de datos FTP). | Aceptar junto con `established` para evitar cortes en diagnósticos o protocolos auxiliares. |
| `invalid` | Paquete que no corresponde a ninguna conexión conocida o tiene cabeceras/banderas incoherentes. | Descartar cuanto antes (`ct state invalid drop`). |

Aceptar `ct state established,related accept` al principio de `input` y
`forward` tiene dos ventajas fundamentales:

1. **Rendimiento:** una vez establecida la conexión, los paquetes siguientes
   coinciden con la primera regla sin recorrer toda la lista.
2. **Simplicidad y seguridad:** las respuestas a peticiones permitidas vuelven
   automáticamente, sin necesidad de abrir rangos de puertos efímeros.

## 1.5 Traducción de direcciones (NAT)

El NAT (*Network Address Translation*) modifica las direcciones IP y/o los
puertos de los paquetes al atravesar un router. En Netfilter existen tres
operaciones principales:

| Tipo | Qué modifica | Hook donde actúa | Caso de uso principal |
| --- | --- | --- | --- |
| **`SNAT`** | IP de origen (por una IP pública o externa fija). | `postrouting` | Router con IP WAN estática (por ejemplo, `snat to 172.26.32.250`). |
| **`MASQUERADE`** | IP de origen (toma automáticamente la IP de la interfaz de salida). | `postrouting` | Router con IP pública dinámica (DHCP/PPPoE) o salida genérica sin fijar IP. |
| **`DNAT`** | IP y/o puerto de destino. | `prerouting` | Publicar servicios internos hacia el exterior (*port forwarding*). |

### Relación entre NAT, enrutamiento y filtrado

- **`DNAT` siempre va en `prerouting`:** el cambio de la dirección/puerto de
  destino debe producirse **antes** de que el kernel decida si el paquete es
  para sí mismo (`input`) o para otro equipo de la red interna (`forward`).
- **`SNAT` y `MASQUERADE` siempre van en `postrouting`:** se aplican justo
  **antes** de que el paquete abandone el router por la interfaz de salida, una
  vez ya se ha decidido por qué interfaz saldrá.
- **Un `DNAT` no sustituye al filtrado en `forward`:** tras traducir la IP de
  destino en `prerouting`, el paquete atraviesa la cadena `forward`. Si
  `forward` tiene política `drop`, el cortafuegos debe permitir explícitamente
  el paso hacia la **IP y puerto internos ya traducidos**.
- **Direccionamiento privado (RFC 1918):** las redes internas detrás de NAT
  deben utilizar únicamente bloques reservados privados (`10.0.0.0/8`,
  `172.16.0.0/12`, `192.168.0.0/16`). Usar rangos públicos ajenos en la LAN
  impedirá alcanzar a los destinos reales de Internet pertenecientes a ese
  rango.
