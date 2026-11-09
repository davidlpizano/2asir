# Tema 2: Programación en PHP

Apuntes de introducción a PHP basados en las guías y prácticas de la unidad, con
el manual oficial de PHP y W3Schools como referencias para ampliar contenidos.
PHP es un lenguaje ejecutado en el servidor: Apache entrega el archivo PHP al
intérprete, que procesa el código y genera una respuesta (normalmente HTML) para
el navegador. El usuario no recibe el código PHP original.

## 1. Preparar el entorno y ejecutar PHP

Guarda los archivos con extensión `.php` dentro del directorio web del entorno
local. En XAMPP para Linux, la ruta habitual es `/opt/lampp/htdocs`; por ejemplo,
un archivo `prueba.php` guardado en `htdocs/php_parte1/` se abre con:

```text
http://localhost/php_parte1/prueba.php
```

PHP también puede ejecutarse desde una terminal. La versión del intérprete de
la terminal puede ser distinta de la que utiliza Apache, especialmente si
conviven PHP del sistema y PHP incluido en XAMPP. Comprueba qué ejecutable y qué
configuración (`php.ini`) se están utilizando antes de diagnosticar diferencias.

El código PHP se delimita normalmente con `<?php ... ?>` y puede alternarse con
HTML. Las instrucciones sencillas terminan en `;`. En archivos que contienen
solo PHP se suele omitir la etiqueta de cierre. La salida de `echo` se incorpora
a la respuesta; los saltos de línea de texto no siempre se representan como
saltos visuales en HTML, por lo que conviene utilizar los elementos HTML
adecuados.

## 2. Variables, tipos y salida

- Las variables comienzan por `$`, por ejemplo `$precio`. PHP determina su tipo
  a partir del valor asignado; los nombres distinguen mayúsculas de minúsculas.
- Entre los tipos habituales están los enteros (`int`), números decimales
  (`float`), cadenas (`string`), booleanos (`bool`), arrays y valores nulos
  (`null`).
- Una constante representa un valor que no se reasigna durante la ejecución y
  se define con `const` o `define()`.
- `echo` genera salida. El operador `.` concatena cadenas; `+` suma números.
- Las cadenas con comillas dobles pueden interpolar variables; las comillas
  simples tratan su contenido mayoritariamente como literal.
- Para mostrar importes con un formato uniforme puede usarse
  `number_format()`.

Ejemplo de cálculo:

```php
<?php
$subtotal = 20.00;
$iva = 0.21;
$total = $subtotal + ($subtotal * $iva);

echo number_format($total, 2, ',', '.') . " €";
```

## 3. Operadores y decisiones

Los operadores aritméticos permiten realizar cálculos; los de comparación
producen un booleano y los operadores lógicos combinan condiciones.

| Operador | Significado |
| --- | --- |
| `=` | Asignación |
| `==`, `!=` | Comparación con posibles conversiones de tipo |
| `===`, `!==` | Comparación estricta de valor y tipo |
| `<`, `<=`, `>`, `>=` | Comparaciones numéricas u ordenadas |
| `&&`, `||`, `!` | Y, O y negación lógica |

No confundas `=` con una comparación. Cuando el tipo importa, usa comparaciones
estrictas como `===`; esto evita aceptar como equivalentes valores como el
entero `80` y la cadena `"80"` por conversión implícita.

`if`, `elseif` y `else` permiten ejecutar ramas según una condición. `switch`
selecciona entre varios casos y `default` cubre los restantes. El operador
ternario es apropiado para elegir entre dos expresiones sencillas, no para
sustituir bloques de lógica complejos.

## 4. Bucles y arrays

Los bucles permiten repetir instrucciones:

- `for` resulta útil cuando se conoce el contador y sus límites.
- `while` comprueba la condición antes de cada repetición.
- `do ... while` ejecuta el bloque al menos una vez.
- `foreach` recorre directamente los elementos de un array.

Hay que actualizar correctamente la condición o el contador para evitar bucles
infinitos. `break` termina un bucle y `continue` pasa a la siguiente iteración.

Un array organiza valores relacionados mediante claves:

- **Indexado:** suele utilizar claves numéricas, comenzando habitualmente en
  `0`.
- **Asociativo:** usa claves con nombre, por ejemplo
  `['hostname' => 'web-01', 'estado' => 'OK']`.
- **Multidimensional:** contiene otros arrays y permite representar listas de
  registros o tablas.

`foreach` es una forma clara de recorrer arrays indexados o asociativos; puede
recuperar solo el valor o tanto la clave como el valor.

## 5. Funciones y reutilización

Una función agrupa instrucciones que pueden reutilizarse. Puede recibir
parámetros y devolver un resultado con `return`. Las variables creadas dentro
de una función tienen ámbito local; es preferible pasarle explícitamente los
datos que necesita, en lugar de depender de variables globales.

Se pueden guardar funciones y configuración compartida en archivos separados.
`require_once` incorpora un archivo una sola vez. `__DIR__` permite construir
rutas relativas a la ubicación del propio archivo y evita depender del
directorio desde el que se inició la ejecución.

## 6. Errores y depuración

Los avisos y errores de PHP suelen señalar el archivo y la línea donde se
detectó el problema. Revisa también la instrucción anterior: un punto y coma,
paréntesis o comilla sin cerrar puede causar el error que aparece más adelante.
Comprueba que el dato de entrada tenga el tipo esperado y que las operaciones
sean válidas, como evitar una división entre cero.

En un entorno local se pueden habilitar errores para facilitar el aprendizaje.
En un entorno publicado, los errores detallados deben registrarse en el
servidor, no mostrarse al visitante. Las operaciones que pueden fallar, como
abrir un archivo, requieren revisar su resultado y tratar el error; algunas
funciones emiten avisos y devuelven `false` en vez de lanzar una excepción.

## 7. Formularios: recibir, validar y mostrar datos

El atributo `action` indica el destino del formulario, `method` determina el
método HTTP y `name` identifica cada campo enviado. `id` sirve para relacionar
controles con etiquetas, pero no sustituye a `name`.

- `$_GET` recibe parámetros incluidos en la URL y se usa habitualmente para
  búsquedas y filtros.
- `$_POST` recibe los campos enviados en el cuerpo de la petición y suele
  utilizarse para operaciones que modifican datos.
- El operador `??` permite definir un valor alternativo si un campo no existe.
- `isset()` permite comprobar si una variable o campo está definido.

El procesamiento de datos tiene tres pasos distintos:

1. **Recepción:** obtener los datos y comprobar el método de la petición.
2. **Validación:** verificar que existan, tengan el formato esperado y sean
   admisibles para la operación.
3. **Presentación:** escapar la salida para que la entrada no se interprete
   como HTML.

La validación HTML (por ejemplo, `required`, `min` o `max`) mejora la
experiencia, pero no sustituye a la validación en PHP: una petición puede
modificarse antes de llegar al servidor. En PHP, `is_numeric()` ayuda a
comprobar si un valor puede tratarse como número. Evita usar `empty()` como
única comprobación de un número: también considera vacío el valor `"0"`.

Para representar una entrada como texto HTML se puede usar
`htmlspecialchars($valor, ENT_QUOTES, 'UTF-8')`. Escapar la salida y validar
los datos son medidas diferentes y ambas son necesarias. Si la validación
falla, se pueden conservar campos no sensibles ya validados; las contraseñas
no se deben volver a rellenar en el formulario.

Una redirección HTTP mediante `header()` debe enviarse antes de producir
contenido. Después de una redirección, termina la ejecución del script para
evitar que continúe procesando la página.

## 8. Cookies y sesiones

HTTP no conserva por sí mismo el estado entre peticiones. Una variable normal de
PHP deja de existir cuando termina la petición; para recordar información entre
páginas se puede usar una cookie o una sesión.

- **Cookie:** pequeño dato que el servidor pide al navegador almacenar y
  reenviar en peticiones posteriores. `setcookie()` y `header()` deben
  ejecutarse antes de enviar contenido. Atributos como `HttpOnly`, `SameSite`,
  `Path` y `Secure` ayudan a restringir su uso.
- **Sesión:** los datos se guardan en el servidor y se asocian normalmente a
  una cookie que contiene el identificador de sesión. PHP permite acceder a
  ellos mediante `$_SESSION`; `session_start()` debe ejecutarse antes de
  generar HTML.

Las sesiones permiten mantener el estado de un usuario entre páginas sin
enviar todos los datos en cada URL. Perfiles de navegador distintos suelen
mantener sesiones separadas; dos pestañas del mismo perfil normalmente
comparten la sesión. Los datos de sesión no son almacenamiento permanente:
al cerrar o destruir la sesión, esos datos dejan de estar disponibles.

## 9. Autenticación y control de acceso

- **Autenticación:** comprobar quién es el usuario que intenta entrar.
- **Autorización:** decidir a qué páginas o acciones puede acceder ese usuario.

Para una práctica de inicio de sesión:

1. Recibir usuario y contraseña mediante POST.
2. Comprobar que los campos existan y contrastar la contraseña con el hash
   guardado mediante `password_verify()`.
3. Guardar en `$_SESSION` solo la identidad necesaria para las páginas
   privadas; no guardar la contraseña.
4. Después de autenticar correctamente, renovar el identificador con
   `session_regenerate_id(true)` y redirigir al área privada.
5. Comprobar la sesión al principio de cada página protegida y cerrar sesión
   destruyendo los datos y la cookie de sesión.

Las contraseñas no deben almacenarse en texto plano: `password_hash()` crea un
hash adecuado para almacenamiento y `password_verify()` comprueba una
contraseña frente a ese hash. Un mensaje de error genérico evita revelar si
falló el usuario o la contraseña.

Un token CSRF asociado a la sesión ayuda a comprobar que un formulario de
modificación se envió desde una página legítima del sitio. No sustituye a la
autenticación, la autorización ni la validación de datos. Los ejemplos de esta
unidad son de laboratorio y no constituyen por sí solos un sistema de acceso
listo para producción.

## 10. Aplicación práctica de la unidad

La práctica integra los contenidos en una calculadora web:

1. Comprueba la versión de PHP y la configuración cargada por Apache.
2. Recibe dos operandos y una operación desde un formulario POST.
3. Valida los números y permite únicamente las operaciones previstas.
4. Implementa el cálculo en una función que devuelve el resultado; distingue
   entre un resultado `0` y la ausencia de un cálculo válido.
5. Evita la división por cero y presenta un error comprensible.
6. Protege la calculadora con inicio de sesión y conserva el último cálculo
   válido en la sesión.
7. Verifica que dos perfiles de navegador mantienen datos separados y que al
   cerrar sesión ya no se puede acceder a la página protegida.

## Referencias

- [Manual oficial de PHP en español](https://www.php.net/manual/es/): referencia
  de sintaxis, tipos, variables, estructuras de control, funciones, formularios,
  sesiones y funciones de contraseñas.
- [Tutorial de PHP de W3Schools](https://www.w3schools.com/php/): introducción y
  ejemplos de los fundamentos del lenguaje.
- Guías de la unidad: `IAW_Guia_PHP_Parte_1-1.docx` y
  `IAW_UD2_Practica_2_Teoria_y_Codigo.docx` (material local de clase).
