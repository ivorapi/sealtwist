# RapiTwist

Indicador visual para paladines Reprensión en **WoW Forever, interfaz 16001**. Tres runas doradas muestran los ecos de Orden. Al llenarse la tercera, brillan y aparece **Cambiá a Rectitud**. Con Rectitud, el primer eco enciende una runa celeste y muestra **Volvé a Orden**. El indicador sigue las auras del jugador mediante `Blizzard_AuraContainer`.

## Instalación

1. Descargá el archivo **RapiTwist-1.3.0.zip** de la [versión 1.3.0](https://github.com/ivorapi/sealtwist/releases/tag/v1.3.0).
2. Extraé la carpeta `RapiTwist` en `World of Warcraft/_forever_/Interface/AddOns/`. El archivo `RapiTwist.toc` debe quedar directamente dentro de esa carpeta del addon.
3. Activá **RapiTwist** en la lista de addons. Si estás actualizando durante una sesión, usá `/reload` fuera de combate.

### Actualizar desde 1.2.x

Con WoW cerrado, mové la carpeta antigua `SealTwistVisual` fuera de `Interface/AddOns`. Para conservar los ajustes, copiá `WTF/Account/<cuenta>/SavedVariables/SealTwistVisual.lua` como `RapiTwist.lua` en el mismo directorio y cambiá el nombre de la variable inicial de `SealTwistVisualDB` a `RapiTwistDB`. Si ya existe el nuevo archivo, conservá su contenido. Iniciá WoW y abrí los ajustes con `/rapitwist` o `/st`.

## Controles

| Acción | Control |
| --- | --- |
| Ajustar tamaño, opacidad y visibilidad | Clic izquierdo en el ícono del minimapa o `/st` |
| Mover las runas | Fuera de combate, clic derecho en el ícono. Arrastrá el indicador y soltalo |
| Reubicar el ícono del minimapa | Arrastrá el ícono por el borde |
| Consultar la versión y el estado del visor | `/st diagnostico` |

La [guía del addon](RapiTwist/LEEME.txt) incluye todos los comandos.

## Desarrollo

El código que carga el juego está en `RapiTwist/`. Las pruebas en `tests/` ejecutan ese mismo Lua con un cliente simulado. Cubren los umbrales de los ecos, avisos, brillo, expiración y ajustes. La apariencia y el comportamiento del cliente en combate se verifican dentro de WoW.

Desde la raíz del repositorio, con Node.js 22, npm y PowerShell 7:

```sh
npm ci
npm test
pwsh -File scripts/package.ps1
```

El empaquetador toma la versión del manifiesto y genera el ZIP en `dist/`. GitHub Actions ejecuta las pruebas y verifica el empaquetado en cada push y pull request.

[Historial de cambios](CHANGELOG.md) · [Licencia MIT](LICENSE)
