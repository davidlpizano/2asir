# Pruebas y validación

**Navegación:** [Inicio](../README.md) ·
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

## 2. Resolución directa e inversa en la zona padre

Desde `cliente1`:

```bash
dig @192.168.10.10 dns1.asir.lan A
dig @192.168.10.10 impresora.asir.lan A
dig @192.168.10.10 -x 192.168.10.50
```

Resultado esperado: `status: NOERROR`, indicador `aa` y los registros `A` y
`PTR` esperados.

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
dig @192.168.10.11 ftp.es.asir.lan A
```

Resultado esperado: `status: NOERROR`, indicador `aa` y direcciones
`192.168.10.70` y `192.168.10.71`. Esta prueba consulta directamente al servidor
autoritativo de la zona hija.

## 5. Referencia desde el padre sin recursión

```bash
dig @192.168.10.10 www.es.asir.lan A +norecurse
```

El padre no debe responder autoritativamente con la dirección de `www`. Debe
mostrar la referencia `NS` de `es.asir.lan`; al tratarse de una zona delegada,
puede aparecer la dirección de `nssub.es.asir.lan` como dato adicional. El
indicador `aa` no debe presentarse como autoridad sobre el registro de la zona
hija.

## 6. Resolución recursiva a través del padre

```bash
dig @192.168.10.10 www.es.asir.lan A
```

Resultado esperado: `status: NOERROR` y dirección `192.168.10.70`. Normalmente
la respuesta del resolver padre no lleva `aa`, dado que `dns1` ha resuelto a
través de la autoridad delegada. Si falla, comprueba el corte NS en `dns1`, el
servidor delegado y el camino de red entre ambos.

## 7. Transferencias de zona hacia `dns2`

En `dns2`, consulta las zonas transferidas:

```bash
sudo rndc zonestatus asir.lan
sudo rndc zonestatus 10.168.192.in-addr.arpa
sudo journalctl -u bind9 --since "10 minutes ago" --no-pager
```

Desde `cliente1`, verifica que `dns2` también responde autoritativamente por la
copia esclava:

```bash
dig @192.168.10.11 impresora.asir.lan A
dig @192.168.10.11 -x 192.168.10.10
```
