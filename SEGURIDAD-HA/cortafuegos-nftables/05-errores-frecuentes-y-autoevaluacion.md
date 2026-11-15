# 5. Errores frecuentes y ejercicios de repaso

**Navegación:** [Inicio](README.md) ·
[← Gestión y depuración](04-gestion-depuracion-y-equivalencias.md)

## 5.1 Errores típicos a evitar

1. **Bloquearte el acceso SSH:** establecer `policy drop` en la cadena `input`
   sin haber incluido previamente `ct state established,related accept` y
   `tcp dport 22 accept`.
2. **Olvidar `ip_forward=1`:** las reglas de `nat` y `forward` son
   sintácticamente válidas, pero el router no reenvía ningún paquete entre
   interfaces.
3. **Olvidar el tráfico de retorno en `forward`:** sin `ct state established,related accept`,
   las peticiones desde la LAN salen hacia Internet, pero las respuestas de
   vuelta se descartan al llegar al router.
4. **Colocar `DNAT` en `postrouting` o `SNAT` en `prerouting`:** el `DNAT` debe
   ir siempre en **`prerouting`** (antes de la decisión de enrutamiento) y
   `SNAT`/`MASQUERADE` siempre en **`postrouting`** (después del enrutamiento).
5. **Olvidar permitir el tráfico `DNAT` en `forward`:** definir la redirección
   en `prerouting` sin autorizar el paquete traducido (IP interna y puerto
   interno) en `forward`.
6. **Bloquear todo `icmpv6`:** impide el funcionamiento de *Neighbor
   Discovery* (`nd-neighbor-solicit`, `nd-neighbor-advert`, `nd-router-advert`),
   dejando inoperativa la conectividad IPv6.
7. **Usar rangos públicos en redes privadas:** emplear direcciones fuera de
   **RFC 1918** (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) impide
   alcanzar los destinos reales de Internet asignados a ese prefijo.
8. **Mezclar `iptables` y `nft`:** gestionar reglas simultáneamente con ambos
   comandos genera conflictos y confusión al revisar el conjunto activo.

## 5.2 Lista de comprobación previa al despliegue

- [ ] ¿Está desactivado cualquier otro cortafuegos conflictivo o reglas previas
      de `iptables`?
- [ ] Si el equipo es router, ¿está activo `net.ipv4.ip_forward = 1` de forma
      persistente en `/etc/sysctl.d/`?
- [ ] ¿Comienza `/etc/nftables.conf` con `#!/usr/sbin/nft -f` y `flush ruleset`?
- [ ] ¿Permite `input` el tráfico de `lo`, `ct state established,related` y el
      puerto de administración remota (SSH) desde orígenes autorizados?
- [ ] ¿Descarta `ct state invalid drop`?
- [ ] En interfaces dinámicas o VPN, ¿se usa `iifname`/`oifname` en lugar de
      `iif`/`oif`?
- [ ] ¿Se ha validado el fichero con `sudo nft -c -f /etc/nftables.conf`?
- [ ] ¿Se ha habilitado `systemctl enable --now nftables`?

## 5.3 Ejercicios prácticos de repaso

### Ejercicio 1: Servidor web + SSH restringido con limitación

**Enunciado:** Configura una tabla `inet filtro` para un servidor con una sola
interfaz que:
- Tenga política por defecto `drop` en `input` y `forward`, y `accept` en `output`.
- Permita `loopback`, tráfico `established,related` y descarte `invalid`.
- Permita HTTP/HTTPS (`80`, `443`) desde cualquier origen.
- Permita SSH (`22`) solo desde la red de administración `192.168.50.0/24` con
  un límite de `3/minute` para conexiones nuevas.
- Registre el resto de paquetes descartados en `input` con prefijo `"[INPUT-DROP] "`
  (limitado a `5/minute`).

<details>
<summary>Ver solución propuesta</summary>

```nft
#!/usr/sbin/nft -f
flush ruleset

table inet filtro {
    chain input {
        type filter hook input priority filter; policy drop;

        iif lo accept
        ct state established,related accept
        ct state invalid drop

        tcp dport { 80, 443 } accept
        ip saddr 192.168.50.0/24 tcp dport 22 ct state new limit rate 3/minute accept
        icmp type echo-request limit rate 5/second accept
        icmpv6 type { echo-request, nd-neighbor-solicit, nd-neighbor-advert, nd-router-advert } accept

        limit rate 5/minute log prefix "[INPUT-DROP] " drop
    }

    chain forward {
        type filter hook forward priority filter; policy drop;
    }

    chain output {
        type filter hook output priority filter; policy accept;
    }
}
```

</details>

### Ejercicio 2: Router NAT con publicación de servicios mediante mapa

**Enunciado:** En un router con WAN `eth0` (IP pública dinámica) y LAN `eth1`
(`10.10.0.0/24`):
- Habilita el acceso a Internet de toda la LAN mediante `MASQUERADE`.
- Publica mediante `DNAT`:
  - Puerto externo `8080/tcp` $\rightarrow$ `10.10.0.10:80`
  - Puerto externo `8443/tcp` $\rightarrow$ `10.10.0.10:443`
- Permite el paso por `forward` únicamente a la salida de la LAN, sus
  respuestas y los dos puertos traducidos hacia `10.10.0.10`.

<details>
<summary>Ver solución propuesta</summary>

Recuerda activar primero `net.ipv4.ip_forward=1` en `/etc/sysctl.d/99-forward.conf`.

```nft
#!/usr/sbin/nft -f
flush ruleset

table inet nat {
    chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        iifname "eth0" tcp dport 8080 dnat ip to 10.10.0.10:80
        iifname "eth0" tcp dport 8443 dnat ip to 10.10.0.10:443
    }

    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "eth0" ip saddr 10.10.0.0/24 masquerade
    }
}

table inet filter {
    chain forward {
        type filter hook forward priority filter; policy drop;

        ct state invalid drop
        iifname "eth1" oifname "eth0" accept
        iifname "eth0" oifname "eth1" ct state established,related accept
        iifname "eth0" oifname "eth1" ip daddr 10.10.0.10 tcp dport { 80, 443 } accept
    }
}
```

</details>

### Ejercicio 3: Diagnóstico de fallo en cascada (Doble NAT vs. Ruta estática)

**Enunciado:** Tienes dos routers en serie: `Router-A` (conectado a Internet) y
`Router-B` (detrás de `Router-A`, dando servicio a la red `192.168.20.0/24`).
Desactivas el NAT en `Router-B` dejando solo filtrado en `forward`, y los
clientes de `192.168.20.0/24` dejan de recibir respuesta de Internet. Sin
embargo, `tcpdump` en `Router-A` muestra que las peticiones salen con
`MASQUERADE` hacia Internet y vuelven a `Router-A`. ¿Qué falta?

<details>
<summary>Ver explicación y solución</summary>

Cuando `Router-B` deja de hacer NAT, `Router-A` ve paquetes cuyo origen es
`192.168.20.x`. Al volver la respuesta desde Internet y deshacer el `MASQUERADE`
en `Router-A`, el destino vuelve a ser `192.168.20.x`. Si `Router-A` no tiene
una **ruta estática** que indique que la red `192.168.20.0/24` se alcanza a
través de la IP de `Router-B`, enviará las respuestas por su puerta de enlace
predeterminada (Internet) o las descartará.

Solución en `Router-A`:

```bash
sudo ip route add 192.168.20.0/24 via <IP_ROUTER_B_EN_ENLACE_CON_A>
```

</details>
