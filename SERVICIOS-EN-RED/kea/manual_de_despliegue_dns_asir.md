# Manual de despliegue DNS para ASIR

**Navegación:** [Inicio del repositorio](README.md) ·
[Conceptos DNS](docs/01-conceptos-dns.md) ·
[Arquitectura](docs/02-arquitectura-y-requisitos.md) ·
[Despliegue](docs/03-despliegue-con-vagrant.md) ·
[Configuración manual](docs/04-configuracion-manual.md) ·
[Pruebas](docs/05-pruebas-y-validacion.md) ·
[Resolución de problemas](docs/06-resolucion-de-problemas.md)

Este manual se ha reorganizado en un repositorio con guía de uso, explicación
teórica, despliegue automatizado, configuración manual, ficheros de referencia,
pruebas y diagnóstico.

## Empezar

Ve al [README principal](README.md) para conocer el alcance y el orden
recomendado. Si quieres desplegar directamente el entorno, revisa antes los
[requisitos de red](docs/02-arquitectura-y-requisitos.md) y sigue la
[guía de despliegue con Vagrant](docs/03-despliegue-con-vagrant.md).

## Capítulos

1. [Conceptos DNS: zonas, subdominios y delegación](docs/01-conceptos-dns.md)
2. [Arquitectura, direccionamiento y requisitos](docs/02-arquitectura-y-requisitos.md)
3. [Despliegue automatizado con Vagrant](docs/03-despliegue-con-vagrant.md)
4. [Configuración manual de BIND y Kea](docs/04-configuracion-manual.md)
5. [Pruebas y validación](docs/05-pruebas-y-validacion.md)
6. [Resolución de problemas](docs/06-resolucion-de-problemas.md)
7. [Ejemplos de configuración BIND](config/bind/)

## Topología resumida

El laboratorio utiliza `kea1` y `kea2` como routers/DHCP, `dns1` como maestro
de `asir.lan`, `dns2` como maestro de `es.asir.lan` y esclavo de las zonas del
padre, y `cliente1` como equipo de pruebas. Todo el direccionamiento y las
limitaciones del escenario se describen en
[arquitectura y requisitos](docs/02-arquitectura-y-requisitos.md).

**Advertencia:** es un laboratorio educativo. No lo conectes a redes que no
controles; contiene un servidor DHCP y conectividad puenteada configurable.
