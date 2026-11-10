# Tema 2: Programación en PHP

PHP es un lenguaje de programación del lado del servidor. Apache entrega el
archivo `.php` al intérprete, este procesa el código y genera una respuesta
(normalmente HTML) para el navegador. El usuario nunca ve el código PHP original.

Este documento resume los contenidos clave de la unidad y mantiene el enfoque
práctico: preparar el entorno, manejar variables, formularios, sesiones,
autenticación y una aplicación completa.

## Resumen rápido

- PHP se ejecuta en el servidor y se guarda en el directorio web local.
- Las variables empiezan por `$` y se tipan dinámicamente.
- Las decisiones se gestionan con `if`, `elseif`, `else`, `switch` y operadores
  de comparación/lógica.
- Los arrays pueden ser indexados, asociativos o multidimensionales.
- Las funciones permiten reutilizar lógica y separar código.
- Los errores deben diagnosticarse con el archivo y la línea exacta.
- Los formularios reciben datos con `$_GET` o `$_POST` y deben validarse.
- Las sesiones y cookies permiten mantener el estado entre peticiones.
- La autenticación exige comprobar identidad y autorizar accesos.
- La práctica final es una calculadora web protegida con sesión.

## 1. Preparar el entorno y ejecutar PHP

- Guarda los archivos con extensión `.php` dentro del directorio web del entorno
  local. En XAMPP para Linux, suele ser `/opt/lampp/htdocs`.
- Ejemplo: un archivo `prueba.php` ubicado en `htdocs/php_parte1/` se abre con:

```text
http://localhost/php_parte1/prueba.php
```

- PHP también puede ejecutarse desde una terminal.
- La versión del intérprete de la terminal puede ser distinta de la que usa
  Apache, especialmente si coexisten PHP del sistema y PHP de XAMPP.
- Antes de diagnosticar diferencias, comprueba qué ejecutable y qué `php.ini`
  se están usando.
- El código PHP se delimita con `<?php ... ?>` y puede alternarse con HTML.
- Las instrucciones terminan con `;`.
- En archivos que contienen solo PHP, suele omitirse la etiqueta de cierre.
- `echo` genera salida HTML; los saltos de línea del texto no siempre se ven
  como saltos visuales en HTML, por lo que conviene usar elementos HTML
  adecuados.

## 2. Variables, tipos y salida

- Las variables comienzan por `$`, por ejemplo `$precio`.
- PHP determina el tipo a partir del valor asignado; los nombres distinguen
  mayúsculas y minúsculas.
- Tipos habituales: `int`, `float`, `string`, `bool`, arrays y `null`.
- Una constante no se reasigna durante la ejecución y se define con `const` o
  `define()`.
- `echo` muestra salida.
- El operador `.` concatena cadenas; `+` suma números.
- Las cadenas con comillas dobles pueden interpolar variables; las comillas
  simples se tratan casi como texto literal.
- `number_format()` ayuda a mostrar importes con formato uniforme.

Ejemplo:

```php
<?php
$subtotal = 20.00;
$iva = 0.21;
$total = $subtotal + ($subtotal * $iva);

echo number_format($total, 2, ',', '.') . " €";
```

## 3. Operadores y decisiones

Los operadores aritméticos, de comparación y lógicos permiten realizar cálculos y
comprobar condiciones.

| Operador | Significado |
| --- | --- |
| `=` | Asignación |
| `==`, `!=` | Comparación con conversiones de tipo |
| `===`, `!==` | Comparación estricta de valor y tipo |
| `<`, `<=`, `>`, `>=` | Comparaciones numéricas u ordenadas |
| `&&`, `||`, `!` | Y, O y negación lógica |

Importante:

- No confundir `=` con `==`.
- Cuando el tipo importa, usa comparaciones estrictas como `===`.
- Esto evita aceptar como equivalentes valores como `80` y `"80"` por
  conversión implícita.

Estructuras de control:

- `if`, `elseif` y `else` ejecutan ramas según una condición.
- `switch` selecciona entre varios casos; `default` cubre el resto.
- El operador ternario sirve para decisiones breves, no para sustituir lógica
  compleja.

## 4. Bucles y arrays

Los bucles repiten instrucciones:

- `for`: útil cuando se conoce el contador y sus límites.
- `while`: comprueba la condición antes de cada iteración.
- `do ... while`: ejecuta al menos una vez.
- `foreach`: recorre un array directamente.

Hay que actualizar bien la condición o el contador para evitar bucles infinitos.
`break` termina el bucle y `continue` pasa a la siguiente iteración.

Tipos de arrays:

- **Indexado:** usa claves numéricas, normalmente desde `0`.
- **Asociativo:** usa claves con nombre, por ejemplo
  `['hostname' => 'web-01', 'estado' => 'OK']`.
- **Multidimensional:** contiene otros arrays para representar listas o tablas.

`foreach` es la forma más clara de recorrer arrays indexados o asociativos; puede
obtener solo el valor o también la clave.

## 5. Funciones y reutilización

- Una función agrupa instrucciones reutilizables.
- Puede recibir parámetros y devolver un resultado con `return`.
- Las variables creadas dentro de una función tienen ámbito local.
- Lo recomendable es pasar los datos necesarios explícitamente, no depender de
  variables globales.
- Se pueden guardar funciones y configuración en archivos separados.
- `require_once` incorpora un archivo solo una vez.
- `__DIR__` permite construir rutas relativas al archivo actual y evitar
  depender del directorio desde el que se invocó el script.

## 6. Errores y depuración

- Los avisos y errores de PHP suelen indicar el archivo y la línea exacta.
- Cuando aparece un error, conviene revisar también la instrucción anterior: un
  punto y coma, paréntesis o comilla sin cerrar puede provocar el fallo que se
  ve después.
- Comprueba que los datos de entrada tengan el tipo esperado.
- Evita operaciones no válidas, por ejemplo una división entre cero.
- En un entorno local se pueden activar errores para aprender mejor.
- En producción, los errores detallados deben registrarse en el servidor, no
  mostrarse al visitante.
- Algunas funciones devuelven `false` o emiten avisos en vez de lanzar una
  excepción; hay que comprobar el resultado de la operación.

## 7. Formularios: recibir, validar y mostrar datos

Los formularios usan:

- `action`: destino del formulario.
- `method`: método HTTP.
- `name`: identifica cada campo enviado.
- `id`: relaciona el control con una etiqueta; no sustituye a `name`.

Recepción de datos:

- `$_GET`: parámetros en la URL; útiles para búsquedas y filtros.
- `$_POST`: campos del cuerpo de la petición; útiles para operaciones que
  modifican datos.
- `??`: valor alternativo si un campo no existe.
- `isset()`: comprueba si una variable o campo está definido.

Proceso recomendado:

1. **Recepción:** obtener los datos y comprobar el método de la petición.
2. **Validación:** verificar que existan, tengan el formato esperado y sean
   admisibles.
3. **Presentación:** escapar la salida para evitar que la entrada se interprete
   como HTML.

Validación y seguridad:

- La validación HTML (`required`, `min`, `max`, etc.) mejora la experiencia, pero
  no reemplaza la validación en PHP; un usuario puede manipular la petición.
- `is_numeric()` ayuda a comprobar si un valor puede manejarse como número.
- No uses `empty()` como única validación de un número: también considera vacío
  el valor `"0"`.
- Para mostrar una entrada como texto HTML usa `htmlspecialchars($valor,
  ENT_QUOTES, 'UTF-8')`.
- Escapar la salida no es lo mismo que validar los datos: ambas medidas son
  necesarias.
- Si la validación falla, puede conservarse información no sensible ya validada;
  nunca se deben volver a rellenar las contraseñas.
- Una redirección con `header()` debe enviarse antes de producir contenido.
- Después de una redirección, hay que terminar la ejecución del script para
  evitar seguir procesando la página.

## 8. Cookies y sesiones

HTTP no conserva estado entre peticiones por sí mismo. Una variable normal de PHP
se pierde al terminar la petición. Para recordar información entre páginas se
usa una cookie o una sesión.

- **Cookie:** dato pequeño que el servidor pide al navegador guardar y reenviar
  en peticiones posteriores. `setcookie()` y `header()` deben ejecutarse antes
  de enviar contenido.
- **Sesión:** se guarda en el servidor y se asocia normalmente a una cookie con
  el identificador de sesión. PHP accede a los datos con `$_SESSION`; se debe
  ejecutar `session_start()` antes de generar HTML.

Atributos como `HttpOnly`, `SameSite`, `Path` y `Secure` ayudan a restringir el
uso de cookies.

Características importantes:

- Las sesiones permiten mantener el estado del usuario entre páginas sin enviar
  todos los datos en cada URL.
- Perfiles de navegador distintos suelen mantener sesiones separadas.
- Dos pestañas del mismo perfil normalmente comparten la sesión.
- Los datos de sesión no son almacenamiento permanente: al cerrar o destruir la
  sesión dejan de estar disponibles.

## 9. Autenticación y control de acceso

- **Autenticación:** comprobar quién es el usuario.
- **Autorización:** decidir qué páginas o acciones puede acceder.

Flujo de autenticación recomendado:

1. Recibir usuario y contraseña mediante `POST`.
2. Comprobar que los campos existan y comparar la contraseña con el hash
   almacenado usando `password_verify()`.
3. Guardar en `$_SESSION` solo la identidad necesaria para las páginas privadas;
   no guardar la contraseña.
4. Tras autenticar correctamente, renovar el identificador con
   `session_regenerate_id(true)` y redirigir al área privada.
5. Comprobar la sesión al principio de cada página protegida y cerrar sesión
   destruyendo los datos y la cookie de sesión.

Seguridad:

- Las contraseñas no se almacenan en texto plano: `password_hash()` crea un
  hash seguro y `password_verify()` comprueba la contraseña frente a ese hash.
- Un mensaje de error genérico evita revelar si falló el usuario o la
  contraseña.
- Un token CSRF asociado a la sesión ayuda a comprobar que un formulario de
  modificación se envió desde una página legítima del sitio.
- El CSRF no sustituye a la autenticación, la autorización ni la validación de
  datos.
- Los ejemplos de esta unidad son de laboratorio y no constituyen un sistema de
  acceso listo para producción.

## 10. Aplicación práctica de la unidad

La práctica integra los contenidos en una calculadora web:

1. Comprueba la versión de PHP y la configuración cargada por Apache.
2. Recibe dos operandos y una operación desde un formulario `POST`.
3. Valida los números y permite solo las operaciones previstas.
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
