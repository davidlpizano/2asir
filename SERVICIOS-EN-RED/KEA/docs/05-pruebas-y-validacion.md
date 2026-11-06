# Pruebas y validación

**Navegación:** [Inicio](../README.md) ·
[Índice](../manual_de_despliegue_dns_asir.md) ·
[← Configuración manual](04-configuracion-manual.md) ·
[Siguiente: Resolución de problemas →](06-resolucion-de-problemas.md)

Ejecuta primero las comprobaciones de sintaxis en cada servidor y después las
consultas desde `cliente1`. En las salidas de `dig`, presta atención a `status`,
`flags`, las direcciones y los NS; los TTL y el orden de los datos pueden
variar.

## 1. Validar configuración local

En `dns1`:

```bash
sudo named-checkconf
sudo named-checkzone asir.lan /var/lib/bind/db.asir.lan
sudo named-checkzone 10.168.192.in-addr.arpa /var/lib/bind/db.10.168.192
```

En `dns2`:

```bash
sudo named-checkconf
sudo named-checkzone es.asir.lan /var/lib/bind/db.es.asir.lan
```

Comprueba también los servicios:

```bash
sudo systemctl is-active bind9
sudo journalctl -u bind9 -n 50 --no-pager
```

## 2. Validar dirección DHCP y ruta

Desde `cliente1`:

```bash
ip -4 address
ip route
cat /etc/resolv.conf
```

Verifica una IP dentro del pool, puerta de enlace `192.168.10.1` y los
resolvers `192.168.10.10` y `192.168.10.11`. Si el cliente no tiene concesión,
consulta los logs de Kea antes de probar DNS.

## 3. Subdominio lógico

```bash
dig @192.168.10.10 www.virtual.asir.lan A
```

Resultado esperado: `status: NOERROR`, indicador `aa` y dirección
`192.168.10.60`. `dns1` es autoritativo porque el nombre forma parte de su zona
padre.

## 4. Zona delegada consultada directamente

```bash
dig @192.168.10.11 www.es.asir.lan A
```

Resultado esperado: `status: NOERROR`, indicador `aa` y dirección
`192.168.10.70`. Esta prueba consulta directamente al servidor de la zona hija.

## 5. Referencia desde el padre sin recursión

```bash
dig @192.168.10.10 www.es.asir.lan A +norecurse
```

El padre no debe responder autoritativamente con la dirección de `www`. Debe
mostrar la referencia `NS` de `es.asir.lan`; al tratarse de una zona delegada,
puede aparecer la dirección de `nssub.es.asir.lan` como dato adicional. El
indicador `aa` no debe presentarse como autoridad sobre el registro de la zona
hija. Algunas versiones pueden variar la presentación de las secciones; usa
también la consulta recursiva siguiente para comprobar resolución de extremo a
extremo.

## 6. Resolución recursiva a través del padre

```bash
dig @192.168.10.10 www.es.asir.lan A
```

Resultado esperado: `status: NOERROR` y dirección `192.168.10.70`. Normalmente
la respuesta del resolver padre no lleva `aa`, dado que `dns1` ha resuelto a
través de la autoridad delegada. Si falla, comprueba el corte NS en `dns1`, el
servidor delegado y el camino de red entre ambos.

## 7. Transferencias y DDNS

En `dns2`, consulta las zonas transferidas:

```bash
sudo rndc zonestatus asir.lan
sudo rndc zonestatus 10.168.192.in-addr.arpa
sudo journalctl -u bind9 --since "10 minutes ago" --no-pager
```

Desde `cliente1`, consulta el nombre que Kea haya registrado tras la concesión:

```bash
dig @192.168.10.10 portatil-ana.asir.lan A
dig @192.168.10.10 -x <IP_ASIGNADA>
```

Sustituye `<IP_ASIGNADA>` por la dirección real de la concesión. No des por
hecho que siempre será `192.168.10.100`: el pool puede asignar otra dirección
según concesiones previas. En `dns1`, los logs de BIND y Kea DDNS permiten
confirmar si la actualización fue recibida o rechazada.

## 8. Alta disponibilidad

Comprueba por separado:

- Estado del servicio Kea DHCP en ambos nodos.
- Estado del hook HA y comunicación entre los endpoints HTTP que definen los
  peers de Kea.
- Presencia de las VIP en el nodo Keepalived activo (`ip address`).
- Concesión DHCP con el nodo principal detenido solo en una red aislada de
  pruebas.

No hagas pruebas de failover conectando el DHCP del laboratorio a una LAN que
no controles. La respuesta correcta depende de la versión de Kea y del modo HA
configurado; revisa logs de ambos nodos, no solo el resultado de un único
cliente.
