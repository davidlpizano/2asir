# Arquitectura y requisitos

**Navegación:** [Inicio](../README.md) ·
[← Conceptos DNS](01-conceptos-dns.md) ·
[Siguiente: Despliegue →](03-despliegue-con-vagrant.md)

## Topología

| Nodo | Función | LAN `lan_asir` |
|---|---|---:|
| `dns1` | BIND maestro de `asir.lan` y `10.168.192.in-addr.arpa` | `192.168.10.10/24` |
| `dns2` | BIND maestro de `es.asir.lan` y esclavo de las zonas padre | `192.168.10.11/24` |
| `cliente1` | Equipo cliente de pruebas DNS (`dig`) | `192.168.10.100/24` |

## Flujo de servicios

1. `dns1` sirve de forma autoritativa `asir.lan` (incluyendo el subdominio lógico
   `virtual.asir.lan`) y la zona inversa `10.168.192.in-addr.arpa`, además de
   publicar la delegación `NS` hacia `es.asir.lan`.
2. `dns2` recibe las transferencias de zona (`asir.lan` y
   `10.168.192.in-addr.arpa`) desde `dns1` firmadas con la clave TSIG
   `transfer-key`, y actúa como servidor autoritativo maestro para `es.asir.lan`.
3. Ambos servidores aceptan consultas recursivas de la red `192.168.10.0/24` y
   utilizan `1.1.1.1` y `9.9.9.9` como reenviadores (`forwarders`) para nombres
   externos.
4. `cliente1` tiene configurados `192.168.10.10` y `192.168.10.11` en
   `/etc/resolv.conf` para validar resolución directa, inversa, delegación,
   recursión y transferencias.

## Requisitos del anfitrión

- Linux, macOS o Windows con soporte para VirtualBox; comprueba la
  compatibilidad de las versiones instaladas de VirtualBox y Vagrant.
- Vagrant y el proveedor VirtualBox instalado y operativo.
- Conexión a Internet durante el aprovisionamiento para descargar paquetes.
- Recursos recomendados: al menos 2 GB de RAM disponibles para las 3 máquinas
  virtuales (`dns1`, `dns2` y `cliente1`).

A diferencia de otros laboratorios, este entorno **no requiere interfaz puente**
(`public_network`): todas las máquinas se comunican a través de la red interna
`lan_asir` y utilizan la interfaz NAT de Vagrant para instalar paquetes.

## Límites y supuestos

- La red interna de VirtualBox se llama `lan_asir` (`192.168.10.0/24`).
- El contenido es didáctico. No incluye endurecimiento completo, gestión
  centralizada de secretos, monitorización ni controles de acceso propios de
  producción.
