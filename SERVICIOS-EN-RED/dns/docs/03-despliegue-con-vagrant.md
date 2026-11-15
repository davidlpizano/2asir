# Despliegue con Vagrant

**Navegación:** [Inicio](../README.md) ·
[← Arquitectura](02-arquitectura-y-requisitos.md) ·
[Siguiente: Configuración manual →](04-configuracion-manual.md)

## 1. Preparar el entorno

Instala Vagrant y VirtualBox en el anfitrión.

El primer uso crea `.lab-secrets.json` con la clave TSIG aleatoria
(`TRANSFER_KEY`) para este laboratorio y la guarda con permisos restringidos. El
fichero está excluido de Git. Si defines `TRANSFER_KEY` en el entorno, ese valor
sustituye al generado; usa secretos válidos y no los compartas.

## 2. Crear las máquinas

Puedes crear todas las máquinas a la vez o por orden:

```bash
vagrant up dns1
vagrant up dns2
vagrant up cliente1
```

O directamente:

```bash
vagrant up
```

El aprovisionamiento instala BIND 9 y sus utilidades, genera la clave TSIG,
valida las configuraciones con `named-checkconf` y `named-checkzone` y arranca
los servicios.

El proyecto debe conservar la carpeta compartida predeterminada de Vagrant:
los scripts de `provision/` leen sus plantillas desde `/vagrant/config/` y el
renderizador desde `/vagrant/provision/`. Si has desactivado o cambiado el
montaje sincronizado en tu configuración local, restáuralo antes de provisionar.

## 3. Acceder y comprobar el estado

```bash
vagrant status
vagrant ssh cliente1
```

Dentro de `cliente1`, confirma la configuración IP y los resolvers:

```bash
ip -4 address
cat /etc/resolv.conf
```

La IP en la red `lan_asir` debe ser `192.168.10.100/24` y `/etc/resolv.conf`
debe apuntar a `192.168.10.10` y `192.168.10.11`. Después ejecuta las consultas
de [validación](05-pruebas-y-validacion.md).

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
pretendes conservar máquinas ya aprovisionadas: ambos servidores DNS usan esa
clave para las transferencias de zona.

## 5. Cambiar una dirección o zona

No basta con cambiar una IP en una sola línea: revisa de forma coordinada el
`Vagrantfile`, las opciones de escucha en `config/named.conf.options.tmpl`,
`config/named.conf.local.*.example` y los ficheros de zona en `config/zones/`.
Comprueba también que el prefijo de la zona inversa corresponda a la subred.

## 6. Retirada del laboratorio

Detén y elimina únicamente las VMs creadas por este proyecto:

```bash
vagrant destroy
```

Si quieres regenerar las claves locales, hazlo solo después de destruir y
reaprovisionar las máquinas; las claves nuevas no coincidirán con las que
están instaladas en nodos existentes.
