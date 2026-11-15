# Laboratorio DHCP con Kea y alta disponibilidad

**Documentación:** [Conceptos DHCP y HA](docs/01-conceptos-dhcp-y-ha.md) ·
[Arquitectura](docs/02-arquitectura-y-requisitos.md) ·
[Despliegue](docs/03-despliegue-con-vagrant.md) ·
[Configuración manual](docs/04-configuracion-manual.md) ·
[Pruebas](docs/05-pruebas-y-validacion.md) ·
[Resolución de problemas](docs/06-resolucion-de-problemas.md)

Repositorio educativo para desplegar un laboratorio de **DHCPv4 con ISC Kea** en
alta disponibilidad (`hot-standby`), junto con un router virtual con
**Keepalived** (VRRP) y traducción de direcciones (**nftables SNAT**).

El laboratorio se ejecuta en máquinas Debian mediante Vagrant y VirtualBox. Está
pensado para una red aislada de prácticas; **no es una configuración de
producción**. En especial, los nodos `kea1` y `kea2` se conectan mediante una
interfaz puente a la red física del anfitrión.

> [!NOTE]
> Este laboratorio cubre de forma independiente el servicio **DHCP con Kea**.
> La práctica de servidores **DNS con BIND 9** se encuentra separada en
> [Laboratorio DNS con BIND 9](../dns/README.md).

## Contenido

```text
.
├── Vagrantfile
├── README.md
├── config/
│   ├── kea-dhcp4.json.tmpl
│   ├── kea-fix-routes.sh.tmpl
│   ├── kea-routes.service
│   ├── keepalived.conf.tmpl
│   └── nftables.conf.tmpl
├── provision/
│   ├── kea.sh
│   ├── cliente.sh
│   └── render-template.py
└── docs/
    ├── 01-conceptos-dhcp-y-ha.md
    ├── 02-arquitectura-y-requisitos.md
    ├── 03-despliegue-con-vagrant.md
    ├── 04-configuracion-manual.md
    ├── 05-pruebas-y-validacion.md
    └── 06-resolucion-de-problemas.md
```

El `Vagrantfile` define las máquinas, la red y qué aprovisionador corresponde
a cada nodo. Los scripts de `provision/` instalan y configuran los servicios;
las plantillas versionadas en `config/` contienen los ajustes de Kea,
Keepalived, nftables y las rutas. Vagrant comparte el proyecto con las máquinas
en `/vagrant`, desde donde los scripts leen esos ficheros.

## Recorrido recomendado

1. Lee [conceptos DHCP y HA](docs/01-conceptos-dhcp-y-ha.md).
2. Comprueba los [requisitos y la topología](docs/02-arquitectura-y-requisitos.md).
3. Sigue el [despliegue con Vagrant](docs/03-despliegue-con-vagrant.md).
4. Ejecuta las [pruebas y validaciones](docs/05-pruebas-y-validacion.md).
5. Si algo falla, consulta [resolución de problemas](docs/06-resolucion-de-problemas.md).
6. Para aprender a instalar los componentes sin Vagrant, sigue la
   [configuración manual](docs/04-configuracion-manual.md).

## Aviso de seguridad y alcance

- Usa únicamente una máquina anfitriona y una red de laboratorio que controles.
- No conectes el puente WAN del laboratorio a una red institucional o pública
  sin autorización del administrador.
- No arranques servidores DHCP conectados a una red compartida donde puedan
  responder a equipos reales.
- El servicio Control Agent y los endpoints de HA de Kea están pensados solo
  para la LAN del laboratorio, no como servicios expuestos a Internet.
- El direccionamiento WAN y el nombre de la interfaz puente dependen del entorno
  local. Revisa la guía antes de ejecutar `vagrant up`.

## Licencia y uso

Material didáctico. Adapta y verifica cada configuración antes de usarla en una
red real.
