# Arquitectura y requisitos

**Navegación:** [Inicio](../README.md) ·
[← Conceptos DHCP y HA](01-conceptos-dhcp-y-ha.md) ·
[Siguiente: Despliegue →](03-despliegue-con-vagrant.md)

## Topología

| Nodo | Función | WAN / puente | LAN `lan_asir` |
|---|---|---:|---:|
| `kea1` | Kea DHCP principal (`primary`), Keepalived (`MASTER`) y NAT | `172.26.30.203/16` | `192.168.10.2/24` |
| `kea2` | Kea DHCP en espera (`standby`), Keepalived (`BACKUP`) y NAT | `172.26.30.204/16` | `192.168.10.3/24` |
| Router virtual | Puerta de enlace proporcionada por VRRP | `172.26.32.250/16` | `192.168.10.1/24` |
| `cliente1` | Cliente DHCP y equipo de pruebas | — | Dirección dinámica |

El pool dinámico de Kea es `192.168.10.100–192.168.10.200`. El laboratorio
reserva direcciones estáticas fuera de ese pool para router, servidores DHCP y
dispositivos con reserva (como `impresora-aula` en `192.168.10.50`).

## Flujo de servicios

1. `cliente1` solicita una concesión DHCP en la LAN `lan_asir`.
2. Kea (`kea1` activo, con respaldo de `kea2`) ofrece dirección del pool,
   puerta de enlace (`192.168.10.1`), sufijo `asir.lan` y resolvers
   (`1.1.1.1`, `9.9.9.9`).
3. Kea HA replica el estado de la concesión entre `kea1` y `kea2` por el puerto
   TCP `8001`.
4. Keepalived mantiene las VIPs (`192.168.10.1` y `172.26.32.250`) en `kea1`
   mientras esté operativo; si falla, conmutan a `kea2`.
5. `nftables` aplica SNAT al tráfico saliente de `192.168.10.0/24` hacia la
   interfaz WAN usando la VIP `172.26.32.250`.

## Requisitos del anfitrión

- Linux, macOS o Windows con soporte para VirtualBox; comprueba la
  compatibilidad de las versiones instaladas de VirtualBox y Vagrant.
- Vagrant y el proveedor VirtualBox instalado y operativo.
- Conexión a Internet durante el aprovisionamiento para descargar paquetes.
- Interfaz de red física conectada a una red `172.26.0.0/16` cuyo gateway sea
  `172.26.0.1`, **o** adaptación explícita de las direcciones de WAN y gateway
  del `Vagrantfile` y `provision/kea.sh`.
- Recursos recomendados: al menos 3 GB de RAM disponibles para las máquinas
  virtuales.

La interfaz puente predeterminada es `eno1`. Para otra interfaz, establece
`IF_BRIDGE` al ejecutar Vagrant. Para identificar interfaces en Linux, consulta
`ip -br link` en el anfitrión.

## Límites y supuestos

- La IP puente, el gateway WAN y la dirección WAN virtual pertenecen a un
  escenario de ejemplo. No son valores universales; no los uses si ya están
  asignados en tu red.
- La red interna de VirtualBox se llama `lan_asir`.
- El router aplica SNAT a través de la dirección WAN virtual. Para que funcione,
  la red física debe aceptar esa dirección y el gateway configurado debe ser
  alcanzable.
- En una red compartida o institucional, la interfaz puente puede exponer el
  entorno a otros equipos. No arranques el laboratorio ahí sin
  aislamiento/autorización.
- El contenido es didáctico. No incluye endurecimiento completo, gestión
  centralizada de secretos, monitorización ni controles de acceso propios de
  producción.
