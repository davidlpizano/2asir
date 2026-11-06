# Laboratorio DNS, DHCP y alta disponibilidad

**Documentación:** [Índice del manual](manual_de_despliegue_dns_asir.md) ·
[Conceptos DNS](docs/01-conceptos-dns.md) ·
[Arquitectura](docs/02-arquitectura-y-requisitos.md) ·
[Despliegue](docs/03-despliegue-con-vagrant.md) ·
[Configuración manual](docs/04-configuracion-manual.md) ·
[Pruebas](docs/05-pruebas-y-validacion.md) ·
[Resolución de problemas](docs/06-resolucion-de-problemas.md)

Repositorio educativo para desplegar un laboratorio con BIND 9, delegación de
subdominios, actualizaciones dinámicas DNS (DDNS), Kea DHCP en alta
disponibilidad y un router virtual con Keepalived.

El laboratorio se ejecuta en máquinas Debian mediante Vagrant y VirtualBox. Está
pensado para una red aislada de prácticas; **no es una configuración de
producción**. En especial, los nodos `kea1` y `kea2` se conectan mediante una
interfaz puente a la red física del anfitrión.

## Contenido

```text
.
├── Vagrantfile
├── README.md
├── config/
│   ├── bind/
│   │   ├── named.conf.options.tmpl
│   │   ├── named.conf.local.dns1.example
│   │   ├── named.conf.local.dns2.example
│   │   └── zones/
│   └── kea/
│       ├── kea-dhcp4.json.tmpl
│       ├── kea-dhcp-ddns.json.tmpl
│       └── plantillas de Keepalived, nftables y rutas
├── provision/
│   ├── kea.sh
│   ├── dns1.sh
│   ├── dns2.sh
│   ├── cliente.sh
│   └── render-template.py
├── docs/
│   ├── 01-conceptos-dns.md
│   ├── 02-arquitectura-y-requisitos.md
│   ├── 03-despliegue-con-vagrant.md
│   ├── 04-configuracion-manual.md
│   ├── 05-pruebas-y-validacion.md
│   └── 06-resolucion-de-problemas.md
└── manual_de_despliegue_dns_asir.md
```

El `Vagrantfile` define las máquinas, la red y qué aprovisionador corresponde
a cada nodo. Los scripts de `provision/` instalan y configuran los servicios;
las plantillas versionadas en `config/` contienen los ajustes de Kea, BIND,
Keepalived, nftables y las rutas. Vagrant comparte el proyecto con las máquinas
en `/vagrant`, desde donde los scripts leen esos ficheros.

## Recorrido recomendado

1. Lee [conceptos DNS](docs/01-conceptos-dns.md).
2. Comprueba los [requisitos y la topología](docs/02-arquitectura-y-requisitos.md).
3. Sigue el [despliegue con Vagrant](docs/03-despliegue-con-vagrant.md).
4. Ejecuta las [pruebas y validaciones](docs/05-pruebas-y-validacion.md).
5. Si algo falla, consulta [resolución de problemas](docs/06-resolucion-de-problemas.md).
6. Para aprender a instalar los componentes sin Vagrant, sigue la
   [configuración manual](docs/04-configuracion-manual.md).

El documento original se conserva como [índice de esta documentación](manual_de_despliegue_dns_asir.md).

## Aviso de seguridad y alcance

- Usa únicamente una máquina anfitriona y una red de laboratorio que controles.
- No conectes el puente WAN del laboratorio a una red institucional o pública
  sin autorización del administrador.
- Las claves TSIG se generan localmente en `.lab-secrets.json`; ese fichero está
  excluido de Git. No reutilices claves, contraseñas ni direccionamiento de
  laboratorio en producción.
- Los servicios de control de Kea y DNS recursivo están preparados para la LAN
  del laboratorio, no como servicios expuestos a Internet.
- El direccionamiento WAN y el nombre de la interfaz puente dependen del entorno
  local. Revisa la guía antes de ejecutar `vagrant up`.

## Licencia y uso

Material didáctico. Adapta y verifica cada configuración antes de usarla en una
red real.
