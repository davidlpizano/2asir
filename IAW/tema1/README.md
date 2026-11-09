# Tema 1: Instalación de servidores de aplicaciones web

Apuntes elaborados a partir de los PDF de fundamentos web y de las actividades
prácticas de la unidad. Se recorren los componentes de una aplicación web desde
la instalación del servidor hasta la comunicación entre PHP y una base de datos.

## 1. Arquitectura de una aplicación web

En una aplicación web intervienen varios componentes:

- **Cliente:** el navegador (por ejemplo, Firefox o Chrome) solicita recursos y
  presenta la respuesta.
- **Servidor web:** Apache recibe las peticiones HTTP y entrega archivos
  estáticos o deriva los archivos PHP al intérprete correspondiente.
- **PHP:** ejecuta la lógica de la aplicación en el servidor. Puede procesar
  formularios y comunicarse con una base de datos.
- **Base de datos:** MariaDB o MySQL guarda y consulta información persistente.
- **HTML y CSS:** HTML estructura el contenido que recibe el navegador y CSS
  define su presentación.

En una consulta dinámica, el recorrido habitual es:

```text
Navegador → Apache → PHP → MariaDB/MySQL
Navegador ← Apache ← PHP ← MariaDB/MySQL
```

El navegador no se conecta directamente a la base de datos ni recibe el código
fuente PHP: recibe la respuesta que genera el servidor, normalmente HTML.

## 2. Instalación manual de la pila LAMP en Ubuntu

LAMP agrupa Linux, Apache, MySQL o MariaDB y PHP. En la práctica de la unidad se
instalan los componentes por separado:

```bash
sudo apt update
sudo apt install -y apache2
sudo apt install -y php libapache2-mod-php
sudo apt install -y mariadb-server
```

Comprobaciones principales:

```bash
sudo systemctl status apache2
sudo systemctl status mariadb
php -v
```

Apache debe estar activo (`active (running)`). Al abrir `http://localhost` en el
navegador del mismo equipo se comprueba que el servidor responde. `localhost`
se refiere al equipo local; no es una dirección de otro servidor de Internet.

### 2.1. DocumentRoot y rutas

En la instalación habitual de Apache en Ubuntu, el directorio raíz del sitio
(`DocumentRoot`) es `/var/www/html`. Apache relaciona la ruta de una URL con un
archivo bajo ese directorio. Por ejemplo:

```text
URL:              http://localhost/apuntes/tema1.html
Archivo servido:  /var/www/html/apuntes/tema1.html
```

El navegador solicita una URL, no una ruta física del disco. Si se solicita un
directorio, Apache busca un archivo de portada definido por `DirectoryIndex`,
habitualmente `index.html` o `index.php`; por eso `http://localhost/` puede
mostrar la portada sin indicar el nombre del archivo.

Los nombres de archivo distinguen mayúsculas y minúsculas en Linux:
`Contacto.html` y `contacto.html` son rutas diferentes. Si no existe el recurso
solicitado, el servidor puede responder `404 Not Found`.

### 2.2. Archivos y permisos

La práctica identifica al usuario de Apache (`www-data` en Ubuntu) y al usuario
de MariaDB (`mysql`), que son cuentas de servicio y no cuentas normales para
iniciar sesión. También compara sus permisos con los del usuario que edita el
contenido web.

Antes de crear archivos en `/var/www/html`, hay que comprobar quién es su
propietario y qué permisos tiene. El usuario que desarrolla necesita poder
escribir en el directorio; el proceso web necesita leer los archivos que sirve.
Los permisos deben configurarse de forma deliberada y con el mínimo acceso
necesario, evitando hacer los archivos escribibles por todo el mundo.

## 3. Recursos estáticos y dinámicos

- **Estático:** Apache devuelve un archivo existente, como `index.html`,
  `contacto.html`, una imagen o un documento.
- **Dinámico:** el servidor ejecuta PHP antes de responder. Por ejemplo, un
  script puede mostrar la fecha y hora del servidor o la versión de PHP.

Para comprobar la diferencia, se puede servir una portada `index.html`, enlazar
una página en un subdirectorio y visitar un archivo `prueba.php`. Al consultar
el código fuente desde el navegador se verá la salida HTML, no las instrucciones
PHP que se ejecutaron en el servidor.

## 4. Formularios y protocolo HTTP

Un formulario HTML envía los campos al recurso indicado por `action`. El atributo
`method` define cómo se envían y cada control necesita un atributo `name` para
que su valor forme parte de la petición. Por ejemplo:

```html
<form action="procesar.php" method="GET">
  <input type="text" name="criterio">
  <button type="submit">Buscar</button>
</form>
```

Una petición HTTP se compone de:

1. **Línea de petición:** método, ruta solicitada y versión HTTP.
2. **Cabeceras:** metadatos como el servidor destinatario y el tipo o tamaño del
   contenido.
3. **Línea en blanco:** separa las cabeceras del cuerpo.
4. **Cuerpo (body):** datos enviados con la petición, cuando los hay.

### 4.1. GET y POST

| Aspecto | GET | POST |
| --- | --- | --- |
| Ubicación de los datos del formulario | Parámetros de la URL después de `?` | Cuerpo de la petición HTTP |
| Uso habitual | Búsquedas, filtros y paginación | Envío de formularios, registros y datos más voluminosos |
| Visibilidad | Los parámetros aparecen en la URL y pueden quedar en el historial | Los datos no aparecen en la URL |
| Reenvío o marcador | La URL puede compartirse o guardarse | El contenido del formulario no queda representado en la URL |

En GET, varios parámetros se separan con `&`, por ejemplo:
`procesar_get.php?criterio=teclado&categoria=perifericos`. En PHP se leen con
`$_GET['criterio']` y `$_GET['categoria']`. Los datos POST se leen con
`$_POST['usuario']`, etc.

**POST no cifra ni protege los datos por sí solo.** Aunque el contenido no se
muestre en la barra de direcciones, una petición HTTP sin cifrar puede ser
observada durante el tránsito. Para proteger credenciales se necesita HTTPS,
además de las medidas de seguridad de la aplicación.

El nombre que aparece en la petición viene del `name` del campo; si se omite,
ese valor no se envía. Las herramientas de desarrollador del navegador, en la
pestaña Red/Network, permiten observar el método, la URL, el estado HTTP, las
cabeceras y, en una petición POST, el cuerpo enviado.

Al mostrar datos recibidos por el formulario, la práctica usa `htmlspecialchars`
para que la entrada se trate como texto y no como marcado HTML. Un formulario
GET con acción inexistente sirve para observar que el envío de datos y la
respuesta del servidor son cosas distintas: el recurso puede responder
`404 Not Found` aunque la petición incluya parámetros.

## 5. Integración de PHP con MariaDB/MySQL

Para que PHP se comunique con MySQL necesita la extensión correspondiente
(`mysqli` en la actividad). Después de instalarla, se reinicia Apache y se
comprueba que PHP la reconoce. MySQL/MariaDB debe estar instalado y su servicio
activo.

La actividad crea una base de datos de prácticas (`iaw_prueba`) y un usuario
local propio de la aplicación (`usuario_iaw`), con permisos limitados a esa base
de datos. La aplicación no debería conectarse como `root`: limitar los
privilegios reduce el impacto de errores o accesos no autorizados.

Para establecer la conexión, PHP utiliza cuatro datos: servidor, usuario,
contraseña y nombre de la base de datos. Una página de prueba permite verificar
una conexión correcta y luego diagnosticar una conexión fallida si las
credenciales no coinciden. Apache y PHP pueden seguir funcionando aunque la
base de datos rechace la conexión, porque son componentes distintos de la pila.

No se deben reutilizar en otros entornos las contraseñas de ejemplo de las
actividades ni publicar archivos que contengan credenciales.

## 6. XAMPP como entorno integrado

XAMPP reúne en una plataforma los componentes necesarios para un entorno local
de desarrollo. En Linux, la instalación de la práctica queda habitualmente en
`/opt/lampp`, y el directorio web es `/opt/lampp/htdocs`, frente a
`/var/www/html` en la instalación manual de Ubuntu. Se puede comprobar la
instalación buscando `/opt/lampp/lampp`; el gestor inicia y detiene el entorno:

```bash
sudo /opt/lampp/lampp start
sudo /opt/lampp/lampp stop
```

La práctica inicia y detiene XAMPP con el gestor incluido en esa ruta, comprueba
`http://localhost` y crea una página PHP para verificar que el servidor la
procesa. Al detener XAMPP, la página deja de estar disponible desde esa
instalación; al iniciarlo de nuevo, vuelve a responder.

| Instalación manual | XAMPP |
| --- | --- |
| Los componentes se instalan y gestionan por separado. | Los componentes se agrupan y se gestionan desde la plataforma. |
| Directorio web habitual: `/var/www/html`. | Directorio web habitual: `/opt/lampp/htdocs`. |
| Más control sobre qué componentes se instalan y cómo se configuran. | Puesta en marcha sencilla para pruebas locales. |

Antes de iniciar XAMPP, hay que comprobar si Apache o MySQL/MariaDB instalados
por separado están activos, porque pueden competir por los mismos puertos. La
actividad indica detener temporalmente los servicios que estuvieran activos y
restaurarlos al terminar. XAMPP se usa para desarrollo local y no se debe
publicar directamente en Internet como servidor de producción.