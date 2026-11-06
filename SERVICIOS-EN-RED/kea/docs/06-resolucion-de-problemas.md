# Resolución de problemas

**Navegación:** [Inicio](../README.md) ·
[Índice](../manual_de_despliegue_dns_asir.md) ·
[← Pruebas y validación](05-pruebas-y-validacion.md)

## `named-checkconf` o `named-checkzone` devuelve errores

Revisa el fichero y la línea indicada. Los errores más comunes son una llave o
punto y coma ausente en `named.conf`, un nombre relativo expandido bajo el
`$ORIGIN` equivocado, un punto final ausente en un nombre absoluto o un SOA
mal formado. Valida antes de reiniciar BIND.

## `rndc reload` falla con una zona dinámica

No edites ni recargues a ciegas una zona que mantiene un journal DDNS. Congela
la zona con `rndc freeze <zona>`, edita y valida el fichero y vuelve a cargarla
con `rndc thaw <zona>`. Consulta
[editar una zona dinámica](04-configuracion-manual.md#editar-una-zona-dinamica).

## `dns2` responde `NXDOMAIN` para `www.es.asir.lan`

1. Consulta directamente el SOA de la zona:

   ```bash
   dig @192.168.10.11 es.asir.lan SOA
   ```

2. Comprueba que `/var/lib/bind/db.es.asir.lan` existe en `dns2`, y que su
   declaración de zona apunta a esa ruta.
3. Ejecuta `named-checkzone es.asir.lan` sobre el fichero y revisa permisos.
4. Consulta `journalctl -u bind9 -n 50 --no-pager` en `dns2`.

## `dns1` responde con autoridad para un registro de la hija

Comprueba que el fichero de `asir.lan` contiene el corte NS de
`es.asir.lan`, pero no registros hijos como `www` o `ftp` de esa zona. Los
registros de la hija deben estar en la zona que sirve `dns2`.

## El padre no devuelve la referencia a `dns2`

Comprueba el registro `NS` del corte y que el destino del NS sea resoluble. En
esta topología el nombre `nssub.es.asir.lan` debe estar asociado a la IP
`192.168.10.11` como glue en el padre y como A en la zona hija. Verifica además
que `dns1` tenga recursión habilitada cuando se espera resolución recursiva.

## Las zonas esclavas no se transfieren

Comprueba conectividad DNS entre `dns1` y `dns2` por UDP/TCP 53, que ambos
servidores tengan la misma clave TSIG de transferencia y nombre de clave, que
`dns1` permita transferencias autenticadas y que BIND haya leído la sección
`server` del esclavo. Revisa los logs de ambos servidores.

## Kea DDNS no actualiza la zona

- Confirma que `kea-dhcp-ddns` está activo y escucha en el puerto local esperado.
- Verifica que Kea DHCP apunte al servicio DDNS correcto y que el dominio
  calificado coincida con `asir.lan`.
- Confirma que Kea DDNS y BIND comparten la clave TSIG DDNS actual.
- Revisa `update-policy`, el destino DNS y los logs de ambos servicios.
- Comprueba si la concesión tiene nombre de host válido y si el nombre ya
  existe con datos incompatibles.

## Kea HA no establece conexión con el otro nodo

Confirma que la librería del hook HA está instalada y cargada, que
`this-server-name` identifica al nodo actual y que las URL de los peers
corresponden a los endpoints HTTP de HA de cada servidor. Comprueba la
conectividad entre esos endpoints y revisa los logs de DHCP y del hook. El
Control Agent es una interfaz de administración distinta; no la expongas fuera
de la LAN de laboratorio.

## El cliente no recibe concesión DHCP

Comprueba que el cliente esté conectado a `lan_asir`, que la interfaz LAN se
detecte en cada VM, que Kea escuche en ella y que la VIP del gateway esté
presente. Asegúrate de arrancar y aprovisionar primero `kea1` y `kea2`, y
después `cliente1`. En el cliente puedes renovar la concesión con el cliente
DHCP disponible en la imagen; el binario exacto depende de los paquetes
instalados.

## No hay acceso a Internet desde la LAN del laboratorio

Verifica IP, prefijo, gateway WAN, rutas por defecto y que la WAN VIP sea
alcanzable en la red puente. Comprueba en `kea1` el forwarding IPv4 y las
reglas nftables. La IP `172.26.0.1` es solo un supuesto del ejemplo y puede no
ser el router de tu red.

## Vagrant no encuentra la interfaz puente

Revisa el nombre con `ip -br link` en el anfitrión y define `IF_BRIDGE` con el
valor adecuado. Confirma también que VirtualBox permite el modo puente en esa
interfaz y que el usuario tiene permisos para administrar las VMs.
