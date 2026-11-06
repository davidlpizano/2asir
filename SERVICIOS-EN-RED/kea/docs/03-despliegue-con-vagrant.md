# Despliegue con Vagrant

**Navegación:** [Inicio](../README.md) ·
[Índice](../manual_de_despliegue_dns_asir.md) ·
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

Sustituye `enp3s0` por la interfaz correcta de tu anfitrión. En otros shells,
exporta la variable con la sintaxis propia de ese shell antes de ejecutar
Vagrant. Si no se establece, se utiliza `eno1`.

El primer uso crea `.lab-secrets.json` con claves TSIG aleatorias para este
laboratorio y lo guarda con permisos de usuario. El fichero está excluido de
Git. Si defines `TRANSFER_KEY` o `DDNS_KEY` en el entorno, esos valores
sustituyen a los generados; usa secretos válidos y no los compartas.

## 2. Crear las máquinas

Por la dependencia de servicios, despliega primero los routers y servidores:

```bash
vagrant up kea1
vagrant up kea2
vagrant up dns1
vagrant up dns2
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
`config/kea/` y `config/bind/`. El renderizador sustituye marcadores como
`@@IF_LAN@@` y valida la sintaxis JSON de las plantillas de Kea antes de
instalarlas.

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
predeterminada debe usar `192.168.10.1` y los DNS deben ser `192.168.10.10` y
`192.168.10.11`. Después ejecuta las consultas de
[validación](05-pruebas-y-validacion.md).

## 4. Operaciones frecuentes

```bash
vagrant halt                 # Apagar las máquinas
vagrant up                   # Volver a iniciarlas
vagrant provision dns1       # Repetir el aprovisionamiento de un nodo
vagrant ssh dns1             # Abrir una sesión en un nodo
vagrant destroy              # Eliminar las máquinas del laboratorio
```

`vagrant destroy` elimina las máquinas virtuales; no borra el código del
repositorio ni `.lab-secrets.json`. No elimines el fichero de claves si
pretendes conservar máquinas ya aprovisionadas: los nodos usan esas claves
para las transferencias y actualizaciones DNS.

## 5. Cambiar una dirección o interfaz

No basta con cambiar la IP en una sola línea: revisa de forma coordinada el
`Vagrantfile`, las direcciones de servicio BIND, Kea, las opciones DHCP, los
registros DNS, las rutas y las pruebas. Comprueba también que el prefijo de la
zona inversa corresponda a la nueva subred. Para un entorno distinto, modifica
primero la tabla de [arquitectura](02-arquitectura-y-requisitos.md#topologia).

## 6. Retirada del laboratorio

Detén y elimina únicamente las VMs creadas por este proyecto:

```bash
vagrant destroy
```

Si quieres regenerar las claves locales, hazlo solo después de destruir y
reaprovisionar las máquinas; las claves nuevas no coincidirán con las que
están instaladas en nodos existentes.
