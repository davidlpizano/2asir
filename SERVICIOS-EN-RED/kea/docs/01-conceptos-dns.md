# Conceptos DNS del laboratorio

**Navegación:** [Inicio](../README.md) ·
[Índice](../manual_de_despliegue_dns_asir.md) ·
[Siguiente: Arquitectura →](02-arquitectura-y-requisitos.md)

## Zona, dominio y nombre

El espacio de nombres DNS es jerárquico. Una zona es la parte del árbol cuya
información administra un conjunto de servidores autoritativos. Una zona puede
contener nombres que parezcan subdominios sin que estos constituyan zonas
independientes.

En este laboratorio, `asir.lan` es la zona padre. `www.asir.lan` es un nombre
dentro de ella. La forma con punto final (`www.asir.lan.`) es un nombre
absoluto; sin punto final, el nombre puede completarse con el origen vigente de
la zona.

## Subdominio lógico dentro de la misma zona

Un espacio como `virtual.asir.lan` puede organizarse bajo la zona `asir.lan`
sin crear una zona DNS independiente. En el fichero de zona se expresa, por
ejemplo, con:

```dns
$ORIGIN virtual.asir.lan.
www IN A 192.168.10.60
```

El registro resultante es `www.virtual.asir.lan.`. `dns1`, que sirve la zona
`asir.lan`, sigue siendo autoritativo para ese nombre. `$ORIGIN` cambia la
base relativa de los nombres que aparecen a continuación; un nombre terminado
en punto no se expande.

## Delegación y corte de zona

Una delegación crea una zona hija independiente y transfiere su administración
a otros servidores. El padre publica los servidores autoritativos de la hija;
la hija tiene su propio SOA y sus propios registros.

En `asir.lan`, el corte de `es.asir.lan` se expresa así:

```dns
$ORIGIN es.asir.lan.
@     IN NS nssub
nssub IN A  192.168.10.11
```

La zona hija, cargada por `dns2`, contiene su propio SOA y los registros que
administra:

```dns
$ORIGIN es.asir.lan.
@     IN NS nssub
nssub IN A  192.168.10.11
www   IN A  192.168.10.70
ftp   IN A  192.168.10.71
```

Como el nombre del servidor delegado está dentro de la zona delegada, el padre
incluye también su dirección para evitar una dependencia circular al localizar
el servidor (`glue`). En una zona pública el registrador publica el glue
necesario; aquí el ejemplo se limita a una red privada de laboratorio.

No dupliques `www.es.asir.lan` ni otros registros de la hija en el padre. El
padre debe publicar el corte `NS`; los registros de la hija pertenecen a la
zona de `dns2`.

## Autoridad, recursión y referencia

- Una respuesta autoritativa lleva el indicador `aa`.
- Una respuesta recursiva de `dns1` puede devolver el dato de la zona hija sin
  `aa`, porque quien responde al cliente es el resolver `dns1`, no la autoridad
  de la zona hija.
- Con recursión desactivada (`dig +norecurse`), el servidor padre puede
  devolver una referencia con los NS de la hija y, cuando corresponda, datos
  adicionales de glue.
- El resultado exacto de las secciones `AUTHORITY` y `ADDITIONAL` puede variar
  según la consulta y la versión; valida el estado, los indicadores y el dato
  relevante en vez de comparar una salida completa carácter por carácter.

## Transferencias de zona y TSIG

`dns2` mantiene copias esclavas de `asir.lan` y de la zona inversa. BIND las
obtiene desde `dns1` mediante transferencias de zona (AXFR/IXFR). TSIG firma y
autentica las transferencias: los dos servidores deben compartir la clave y
usar el mismo nombre de clave y algoritmo.

TSIG también se utiliza para autorizar las actualizaciones DDNS enviadas por
Kea. La política de actualización debe limitarse a las zonas y tipos de
registros que el DHCP necesita modificar. Las claves de ejemplo no deben
guardarse en el repositorio ni reutilizarse en otros entornos.

## DNS dinámico (DDNS)

Cuando un cliente obtiene una concesión, Kea puede solicitar a BIND que cree o
actualice los registros directo e inverso. En el ejemplo, Kea usa
`ddns-key`; BIND limita esa clave a actualizaciones de la zona correspondiente.
Las zonas dinámicas pueden mantener un fichero de journal `.jnl`, que registra
cambios aún no incorporados al fichero maestro. Para una edición manual se debe
congelar la zona y descongelarla después; véase la
[guía manual](04-configuracion-manual.md#editar-una-zona-dinamica).

## Direccionamiento inverso

Para la red `192.168.10.0/24`, la zona inversa es
`10.168.192.in-addr.arpa`. Por ejemplo, la dirección `192.168.10.10` se
representa con el nombre `10.10.168.192.in-addr.arpa.` y puede apuntar a
`dns1.asir.lan.` mediante un registro PTR.
