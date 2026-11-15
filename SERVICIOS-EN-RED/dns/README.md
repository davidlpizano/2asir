# Laboratorio DNS con BIND 9

**Documentación:** [Conceptos DNS](docs/01-conceptos-dns.md) ·
[Arquitectura](docs/02-arquitectura-y-requisitos.md) ·
[Despliegue](docs/03-despliegue-con-vagrant.md) ·
[Configuración manual](docs/04-configuracion-manual.md) ·
[Pruebas](docs/05-pruebas-y-validacion.md) ·
[Resolución de problemas](docs/06-resolucion-de-problemas.md)

Repositorio educativo para desplegar un laboratorio de **DNS con BIND 9**,
zonas directa e inversa, transferencias de zona autenticadas con **TSIG**,
subdominios lógicos y **delegación de subdominios**.

El laboratorio se ejecuta en máquinas Debian mediante Vagrant y VirtualBox en
una red interna aislada; **no es una configuración de producción**.

> [!NOTE]
> Este laboratorio cubre de forma independiente el servicio **DNS con BIND 9**.
> La práctica de servidores **DHCP con Kea y alta disponibilidad** se encuentra
> separada en [Laboratorio DHCP con Kea](../dhcp-kea/README.md).

## Contenido

```text
.
├── Vagrantfile
├── README.md
├── config/
│   ├── named.conf.options.tmpl
│   ├── named.conf.local.dns1.example
│   ├── named.conf.local.dns2.example
│   └── zones/
│       ├── db.asir.lan
│       ├── db.es.asir.lan
│       └── db.10.168.192
├── provision/
│   ├── dns1.sh
│   ├── dns2.sh
│   ├── cliente.sh
│   └── render-template.py
└── docs/
    ├── 01-conceptos-dns.md
    ├── 02-arquitectura-y-requisitos.md
    ├── 03-despliegue-con-vagrant.md
    ├── 04-configuracion-manual.md
    ├── 05-pruebas-y-validacion.md
    └── 06-resolucion-de-problemas.md
```

El `Vagrantfile` define las máquinas, la red y qué aprovisionador corresponde
a cada nodo. Los scripts de `provision/` instalan y configuran BIND 9; las
plantillas y ficheros de `config/` contienen las opciones, declaraciones de zona
y registros DNS. Vagrant comparte el proyecto con las máquinas en `/vagrant`,
desde donde los scripts leen esos ficheros.

## Recorrido recomendado

1. Lee [conceptos DNS](docs/01-conceptos-dns.md).
2. Comprueba los [requisitos y la topología](docs/02-arquitectura-y-requisitos.md).
3. Sigue el [despliegue con Vagrant](docs/03-despliegue-con-vagrant.md).
4. Ejecuta las [pruebas y validaciones](docs/05-pruebas-y-validacion.md).
5. Si algo falla, consulta [resolución de problemas](docs/06-resolucion-de-problemas.md).
6. Para aprender a instalar los componentes sin Vagrant, sigue la
   [configuración manual](docs/04-configuracion-manual.md).

## Aviso de seguridad y alcance

- Usa únicamente una máquina anfitriona y una red de laboratorio aislada.
- Las claves TSIG se generan localmente en `.lab-secrets.json`; ese fichero está
  excluido de Git. No reutilices claves ni direccionamiento de laboratorio en
  producción.
- Los servidores DNS recursivos están restringidos a la LAN del laboratorio
  (`192.168.10.0/24`), no expuestos al exterior.

## Licencia y uso

Material didáctico. Adapta y verifica cada configuración antes de usarla en una
red real.
