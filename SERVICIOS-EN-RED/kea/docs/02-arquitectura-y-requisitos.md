# Arquitectura y requisitos

**Navegación:** [Inicio](../README.md) ·
[Índice](../manual_de_despliegue_dns_asir.md) ·
[← Conceptos DNS](01-conceptos-dns.md) ·
[Siguiente: Despliegue →](03-despliegue-con-vagrant.md)

## Topología

| Nodo | Función | WAN / puente | LAN `lan_asir` |
|---|---|---:|---:|
| `kea1` | Kea DHCP principal, DDNS, Keepalived y NAT | `172.26.30.203/16` | `192.168.10.2/24` |
| `kea2` | Kea DHCP en espera, DDNS y Keepalived | `172.26.30.204/16` | `192.168.10.3/24` |
| Router virtual | Puerta de enlace proporcionada por VRRP | `172.26.32.250/16` | `192.168.10.1/24` |
| `dns1` | BIND maestro de `asir.lan` y DDNS | — | `192.168.10.10/24` |
| `dns2` | BIND maestro de `es.asir.lan` y esclavo de las zonas padre | — | `192.168.10.11/24` |
| `cliente1` | Cliente DHCP y equipo de pruebas | — | Dirección dinámica |

El pool dinámico de Kea es `192.168.10.100–192.168.10.200`. El laboratorio
reserva direcciones estáticas fuera de ese pool para router, servidores y
dispositivos.

## Flujo de servicios

1. `cliente1` solicita una concesión DHCP en la LAN.
2. Kea ofrece dirección, puerta de enlace (`192.168.10.1`), sufijo `asir.lan`
   y resolvers (`192.168.10.10`, `192.168.10.11`).
3. Kea DDNS envía actualizaciones firmadas con TSIG a `dns1`.
4. `dns1` sirve `asir.lan` y la zona inversa, y publica el corte de
   `es.asir.lan`.
5. `dns2` sirve la zona hija y mantiene copias esclavas de las zonas del padre.
6. Keepalived mueve las direcciones virtuales del router entre `kea1` y
   `kea2`; Kea HA sincroniza el servicio DHCP según su configuración.

## Requisitos del anfitrión

- Linux, macOS o Windows con soporte para VirtualBox; comprueba la
  compatibilidad de las versiones instaladas de VirtualBox y Vagrant.
- Vagrant y el proveedor VirtualBox instalado y operativo.
- Conexión a Internet durante el aprovisionamiento para descargar paquetes.
- Interfaz de red física conectada a una red `172.26.0.0/16` cuyo gateway sea
  `172.26.0.1`, **o** adaptación explícita de las direcciones de WAN y gateway
  del `Vagrantfile`.
- Recursos recomendados: al menos 4 GB de RAM disponibles para las máquinas
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
  servicio DHCP del laboratorio a otros equipos. No arranques el laboratorio
  ahí sin aislamiento/autorización.
- El contenido es didáctico. No incluye endurecimiento completo, gestión
  centralizada de secretos, monitorización ni controles de acceso propios de
  producción.
