# 3. Plantillas y escenarios de configuración

**Navegación:** [Inicio](README.md) ·
[← Arquitectura y sintaxis](02-arquitectura-y-sintaxis-nftables.md) ·
[Siguiente: Gestión y depuración →](04-gestion-depuracion-y-equivalencias.md)

La forma recomendada de administrar `nftables` en Debian es centralizar las
reglas en `/etc/nftables.conf` y aplicar **recargas atómicas**. Comenzar el
fichero con `flush ruleset` garantiza que el estado previo se limpia antes de
cargar las nuevas tablas, evitando duplicados o reglas huérfanas.

## 3.1 Escenario A: Cortafuegos de servidor

Protege un servidor final con política restrictiva (`policy drop`) en `input` y
`forward`, permitiendo únicamente tráfico local (`lo`), conexiones ya
establecidas, los servicios publicados (`22`, `80`, `443`) e ICMP/ICMPv6
necesario.

Plantilla disponible en [ejemplos/servidor-basico.nft](ejemplos/servidor-basico.nft):

```nft
#!/usr/sbin/nft -f
flush ruleset

table inet filtro {
    chain input {
        type filter hook input priority filter; policy drop;

        iif lo accept
        ct state established,related accept
        ct state invalid drop

        tcp dport { 22, 80, 443 } accept
        icmp type echo-request limit rate 5/second accept
        # Imprescindible en IPv6: Neighbor Discovery (equivalente a ARP)
        icmpv6 type { echo-request, nd-neighbor-solicit, nd-neighbor-advert, nd-router-advert } accept
    }

    chain forward {
        type filter hook forward priority filter; policy drop;
    }

    chain output {
        type filter hook output priority filter; policy accept;
    }
}
```

### Puntos clave de esta plantilla

- **`iif lo accept`:** permite la comunicación interna por *loopback* (`127.0.0.1`
  y `::1`), indispensable para bases de datos locales, resolvers y sockets.
- **`ct state established,related accept`:** autoriza el tráfico de retorno de
  conexiones iniciadas por el servidor (`output`) o ya aceptadas previamente.
- **ICMPv6 `nd-*`:** en IPv6 no existe ARP; la resolución de direcciones de
  enlace depende de *Neighbor Discovery* sobre ICMPv6. Bloquear todo ICMPv6
  incomunica la interfaz IPv6.

## 3.2 Escenario B: Router con NAT (`MASQUERADE`) y *Port Forwarding* (`DNAT`)

Supongamos un router Linux con:
- Interfaz WAN (Internet): `enp1s0`
- Interfaz LAN (`192.168.1.0/24`): `enp3s0`
- Servidor web interno en `192.168.1.10:80` que se desea publicar en el puerto
  externo `8080` del router.

Recuerda habilitar antes el reenvío IP en el kernel
([apartado 1.3](01-fundamentos-netfilter-y-nat.md#13-reenvío-ip-ip_forward)).

Plantilla disponible en [ejemplos/router-nat-dnat.nft](ejemplos/router-nat-dnat.nft):

```nft
#!/usr/sbin/nft -f
flush ruleset

table inet nat {
    chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        # Redirigir puerto externo 8080 al servidor web interno 192.168.1.10:80
        iifname "enp1s0" tcp dport 8080 dnat ip to 192.168.1.10:80
    }

    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        # Enmascarar tráfico saliente hacia Internet
        oifname "enp1s0" masquerade
    }
}

table inet filter {
    chain input {
        type filter hook input priority filter; policy drop;

        iif lo accept
        ct state established,related accept
        ct state invalid drop
        iifname "enp3s0" tcp dport 22 accept
    }

    chain forward {
        type filter hook forward priority filter; policy drop;

        ct state invalid drop
        # Permitir salida de la LAN a Internet y sus respuestas
        iifname "enp3s0" oifname "enp1s0" accept
        iifname "enp1s0" oifname "enp3s0" ct state established,related accept

        # Permitir el tráfico DNAT (ya llega con la IP y puerto traducidos)
        iifname "enp1s0" oifname "enp3s0" ip daddr 192.168.1.10 tcp dport 80 accept
    }

    chain output {
        type filter hook output priority filter; policy accept;
    }
}
```

### Detalles críticos del router NAT/DNAT

1. **Si la IP WAN es fija**, puedes sustituir `oifname "enp1s0" masquerade` por
   `oifname "enp1s0" ip saddr 192.168.1.0/24 snat ip to <IP_WAN_FIJA>`.
2. **Regla en `forward` tras el `DNAT`:** cuando `forward` evalúa el paquete
   entrante hacia el servidor publicado, el `prerouting` ya ha reescrito el
   destino a `192.168.1.10` y puerto `80`. Por eso la regla de `forward` filtra
   por `ip daddr 192.168.1.10 tcp dport 80`, **no** por el puerto externo `8080`.
3. **Acceso SSH al router:** en el ejemplo se restringe la administración SSH
   únicamente desde la interfaz LAN (`enp3s0`).

## 3.3 Doble NAT en cascada vs. enrutamiento puro

En topologías con dos routers en serie (**Router A** conectado a Internet y
**Router B** conectado detrás de A atendiendo a los clientes), existen dos
diseños posibles:

| Aspecto | Con Doble NAT (A y B hacen NAT) | Sin NAT en Router B (solo enruta) |
| --- | --- | --- |
| **Configuración de `postrouting`** | Ambos routers aplican `masquerade` / `snat` en su interfaz de salida. | Solo **Router A** aplica `masquerade` hacia Internet; **Router B** solo filtra en `forward`. |
| **Rutas en Router A** | **No necesita** ruta estática hacia la red interna de B, porque todo el tráfico le llega con la IP WAN de B como origen. | **Sí requiere una ruta estática** (`ip route add <red_clientes> via <IP_Router_B>`) para saber devolver las respuestas a la red detrás de B. |
| **Publicar un servicio interno (`DNAT`)** | Requiere **encadenar dos DNAT** (A redirige hacia B, y B redirige hacia el servidor interno). | Basta un **único DNAT** en Router A apuntando directamente a la IP interna del servidor (alcanzable vía la ruta estática). |
| **Trazabilidad en logs** | El Router A pierde la IP real del cliente interno (solo ve la de B). | Se conserva la IP real de cada cliente en toda la red interna hasta llegar a Router A. |
