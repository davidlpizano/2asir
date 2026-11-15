# Despliegue con Vagrant

**Navegación:** [Inicio](../README.md) ·
[← Arquitectura](02-arquitectura-y-requisitos.md) ·
[Siguiente: Configuración manual →](04-configuracion-manual.md)

## 1. Preparar el entorno

Instala Vagrant y VirtualBox en el anfitrión. Revisa la sección de
[requisitos de red](02-arquitectura-y-requisitos.md#requisitos-del-anfitrion) y
confirma que las direcciones WAN del ejemplo no colisionan con tu LAN.

Configura el nombre de la interfaz puente. En Linux, por ejemplo:

```bash
IF_BRIDGE=enp3s0 vagrant up
```

En PowerShell (Windows):

```powershell
$env:IF_BRIDGE="NombreDeTuInterfaz"; vagrant up
```

Sustituye el nombre por la interfaz correcta de tu anfitrión. Si no se
establece, se utiliza `eno1`.

## 2. Crear las máquinas

Por la dependencia de servicios, despliega primero los servidores DHCP/routers:

```bash
vagrant up kea1
vagrant up kea2
```

Después arranca el cliente, que necesita que Kea ya esté atendiendo:

```bash
vagrant up cliente1
```

También se puede ejecutar `vagrant up` para crear todas las máquinas. Si el
cliente no recibe una concesión porque se aprovisionó antes que Kea, vuelve a
ejecutar `vagrant provision cliente1` cuando los servicios DHCP estén listos.

El aprovisionamiento instala paquetes Debian, genera configuraciones y activa
servicios. La primera ejecución puede tardar varios minutos y requiere que los
repositorios de paquetes sean accesibles desde las máquinas.

El proyecto debe conservar la carpeta compartida predeterminada de Vagrant:
los scripts de `provision/` leen sus plantillas desde `/vagrant/config/` y el
renderizador desde `/vagrant/provision/`. Si has desactivado o cambiado el
montaje sincronizado en tu configuración local, restáuralo antes de provisionar.

La topología y las máquinas se definen en `Vagrantfile`; la lógica de
instalación está en `provision/`; los ficheros con variables se encuentran en
`config/`. El renderizador sustituye marcadores como `@@IF_LAN@@` y valida la
sintaxis JSON de `kea-dhcp4.json.tmpl` antes de instalarlo.

## 3. Acceder y comprobar el estado

```bash
vagrant status
vagrant ssh cliente1
```

Dentro del cliente, confirma la concesión y la ruta:

```bash
ip -4 address
ip route
cat /etc/resolv.conf
```

La dirección debe pertenecer al pool `192.168.10.100–192.168.10.200`, la ruta
predeterminada debe usar `192.168.10.1` y los DNS deben ser `1.1.1.1` y
`9.9.9.9`. Después ejecuta las comprobaciones de
[validación](05-pruebas-y-validacion.md).

## 4. Operaciones frecuentes

```bash
vagrant halt                 # Apagar las máquinas
vagrant up                   # Volver a iniciarlas
vagrant provision kea1       # Repetir el aprovisionamiento de un nodo
vagrant ssh kea1             # Abrir una sesión en un nodo
vagrant destroy              # Eliminar las máquinas del laboratorio
```

## 5. Cambiar una dirección o interfaz

No basta con cambiar la IP en una sola línea: revisa de forma coordinada el
`Vagrantfile`, `provision/kea.sh`, `config/kea-dhcp4.json.tmpl`,
`config/keepalived.conf.tmpl`, `config/nftables.conf.tmpl` y
`config/kea-fix-routes.sh.tmpl`. Para un entorno distinto, modifica primero la
tabla de [arquitectura](02-arquitectura-y-requisitos.md#topologia).

## 6. Retirada del laboratorio

Detén y elimina únicamente las VMs creadas por este proyecto:

```bash
vagrant destroy
```
