# Git para principiantes

Guía de iniciación a Git, un sistema de control de versiones distribuido que
permite guardar cambios, consultar el historial y colaborar en proyectos.

## Conceptos básicos

- **Repositorio:** carpeta cuyo historial de cambios gestiona Git.
- **Commit:** instantánea de los cambios preparados, con un mensaje descriptivo.
- **Rama:** línea de trabajo independiente que permite desarrollar cambios sin
  alterar directamente otra rama.
- **Remoto:** repositorio alojado en otro lugar, por ejemplo en GitHub.

## Flujo de trabajo básico

```bash
# Crear un repositorio en la carpeta actual
git init

# Consultar los cambios
git status

# Preparar un archivo para el próximo commit
git add README.md

# Guardar los cambios preparados en el historial
git commit -m "Añade documentación inicial"

# Consultar el historial
git log --oneline
```

Antes de hacer un commit, revisa `git status` y comprueba qué archivos has
preparado. Los commits deben agrupar cambios relacionados y usar mensajes que
describan qué se ha hecho.

## Ramas y repositorios remotos

```bash
# Crear y cambiar a una rama nueva
git switch -c mi-rama

# Consultar las ramas
git branch

# Añadir un remoto
git remote add origin https://github.com/usuario/proyecto.git

# Publicar la rama actual por primera vez
git push -u origin mi-rama
```

Sustituye la URL y el nombre de rama de ejemplo por los del repositorio en el
que estés trabajando. No incluyas contraseñas, tokens ni claves privadas en el
historial de Git.
