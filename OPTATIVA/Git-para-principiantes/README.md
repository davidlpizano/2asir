# Git para principiantes

Guía de iniciación a Git con los comandos y explicaciones preparados para el
curso. Git permite llevar el historial de cambios de un proyecto y sincronizar
el trabajo con un repositorio remoto.

## Información general y ayuda

| Comando | Explicación | Ejemplo |
| --- | --- | --- |
| `git -v` | Muestra la versión de Git instalada. | `git -v` |
| `git -h` | Muestra la ayuda rápida de Git. | `git -h` |

## Configuración global

La configuración global se aplica a los repositorios del usuario. El nombre y
el correo se guardan como autoría de los commits.

```bash
git config --global user.name "Nombre Apellido"
git config --global user.email "correo@ejemplo.com"
```

Consulta la configuración efectiva con:

```bash
git config -l
```

Establece `main` como nombre de la rama inicial de los nuevos repositorios:

```bash
git config --global init.defaultBranch main
```

## Inicialización de repositorios y ramas

| Comando | Explicación | Ejemplo |
| --- | --- | --- |
| `git init` | Inicializa un repositorio en la carpeta actual creando `.git`, donde Git almacena el historial y la configuración local. | `git init` |
| `git branch -m` | Renombra la rama actual. | `git branch -m main` |
| `git merge <nombre-rama>` | Integra en la rama actual los cambios de la rama indicada. | `git merge desarrollo` |

## Estado, preparación y commits

| Comando | Explicación | Ejemplo |
| --- | --- | --- |
| `git status` | Consulta el estado del directorio de trabajo y del área de preparación (*staging area*), incluidos archivos modificados o sin seguimiento. | `git status` |
| `git add -A` | Añade al área de preparación todos los cambios del repositorio: archivos nuevos, modificados y eliminados. | `git add -A` |
| `git commit -m "<mensaje>"` | Guarda en el historial local una instantánea de los cambios preparados, con un mensaje explicativo. | `git commit -m "Añade documentación inicial"` |
| `touch .gitignore` | Crea un archivo `.gitignore` vacío para indicar qué archivos o carpetas no debe rastrear Git. | `touch .gitignore` |

Revisa `git status` antes de confirmar los cambios. `.gitignore` no deja de
rastrear archivos que Git ya esté siguiendo; para eso hay que quitarlos del
índice por separado.

## Historial de commits

| Comando | Explicación | Ejemplo |
| --- | --- | --- |
| `git log` | Muestra el historial de commits de la rama actual. | `git log` |
| `git log --oneline` | Resume cada commit en una línea. | `git log --oneline` |
| `git log --all --oneline` | Muestra en formato resumido los commits alcanzables desde todas las ramas. | `git log --all --oneline` |

## Diferencias y restauración de cambios

| Comando | Explicación | Ejemplo |
| --- | --- | --- |
| `git diff` | Muestra los cambios no preparados entre el directorio de trabajo y el área de preparación. | `git diff` |
| `git reset` | Quita del área de preparación los cambios indicados y los deja en el directorio de trabajo. Sin indicar archivos ni opciones, deshace la preparación de todos los cambios preparados. | `git reset` |
| `git checkout -- <archivo>` | Descarta las modificaciones no preparadas del archivo y lo restaura al contenido del área de preparación. | `git checkout -- README.md` |

**Atención:** `git checkout -- <archivo>` descarta los cambios locales de ese
archivo que no estén preparados, y puede ser irreversible. Si hay cambios
preparados, estos se conservan. Comprueba antes con `git status` y `git diff`.
`git reset` sin opciones afecta al área de preparación, no borra el contenido
modificado del directorio de trabajo.

## Repositorios remotos

| Comando | Explicación | Ejemplo |
| --- | --- | --- |
| `git clone <url>` | Crea una copia local del repositorio remoto, con su historial. | `git clone https://github.com/usuario/proyecto.git` |
| `git push origin <rama>` | Publica en el remoto `origin` los commits de la rama local indicada. | `git push origin main` |
| `git pull` | Descarga e integra en la rama actual los cambios de la rama remota configurada como seguimiento. | `git pull` |

En un repositorio recién clonado, normalmente se usa `git push` para publicar
la rama configurada. Si el remoto todavía no está asociado a la rama local,
configura el seguimiento con `git push -u origin main`. Revisa la rama y el
remoto antes de publicar para evitar enviar cambios al destino equivocado.
