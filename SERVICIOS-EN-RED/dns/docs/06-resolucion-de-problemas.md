# Resolución de problemas

**Navegación:** [Inicio](../README.md) ·
[← Pruebas y validación](05-pruebas-y-validacion.md)

## `named-checkconf` o `named-checkzone` devuelve errores

Revisa el fichero y la línea indicada. Los errores más comunes son una llave o
punto y coma ausente en `named.conf`, un nombre relativo expandido bajo el
`$ORIGIN` equivocado, un punto final ausente en un nombre absoluto o un SOA
mal formado. Valida antes de reiniciar BIND.

## `dns2` responde `NXDOMAIN` para `www.es.asir.lan`

1. Consulta directamente el SOA de la zona:

   ```bash
   dig @192.168.10.11 es.asir.lan SOA
   ```

2. Comprueba que `/var/lib/bind/db.es.asir.lan` existe en `dns2`, y que su
   declaración de zona apunta a esa ruta.
3. Ejecuta `named-checkzone es.asir.lan /var/lib/bind/db.es.asir.lan` y revisa
   permisos (`bind:bind`).
4. Consulta `journalctl -u bind9 -n 50 --no-pager` en `dns2`.

## `dns1` responde con autoridad para un registro de la hija

Comprueba que el fichero de `asir.lan` contiene el corte `NS` de
`es.asir.lan`, pero no registros hijos como `www` o `ftp` de esa zona. Los
registros de la hija deben estar en la zona que sirve `dns2`.

## El padre no devuelve la referencia a `dns2`

Comprueba el registro `NS` del corte y que el destino del NS sea resoluble. En
esta topología el nombre `nssub.es.asir.lan` debe estar asociado a la IP
`192.168.10.11` como glue en el padre y como `A` en la zona hija. Verifica además
que `dns1` tenga recursión habilitada cuando se espera resolución recursiva.

## Las zonas esclavas no se transfieren

Comprueba conectividad DNS entre `dns1` y `dns2` por UDP/TCP 53, que ambos
servidores tengan exactamente la misma clave TSIG `transfer-key` y nombre de
clave, que `dns1` permita transferencias autenticadas (`allow-transfer`) y que
BIND haya leído la sección `server` del esclavo. Revisa los logs de ambos
servidores.

## `dns1` o `dns2` no resuelven dominios externos

Verifica que `dns1` y `dns2` conservan la salida a Internet (a través de la
interfaz NAT de Vagrant o del gateway de laboratorio) y que los reenviadores
(`1.1.1.1; 9.9.9.9;`) responden en puerto UDP/TCP 53.
