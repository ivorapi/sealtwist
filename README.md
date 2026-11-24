# SealTwist Visual

Indicador visual para paladines Reprensión en **WoW Forever, interfaz 16001**. Tres runas doradas muestran los ecos de Orden. Al llenarse la tercera, brillan y aparece **Cambiá a Rectitud**. Con Rectitud, el primer eco enciende una runa celeste y muestra **Volvé a Orden**. El indicador sigue las auras del jugador mediante `Blizzard_AuraContainer`.

## Instalación

1. Descargá el archivo **SealTwistVisual-1.2.2.zip** de la [versión 1.2.2](https://github.com/ivorapi/sealtwist/releases/tag/v1.2.2).
2. Extraé la carpeta `SealTwistVisual` en `World of Warcraft/_forever_/Interface/AddOns/`. El archivo `SealTwistVisual.toc` debe quedar directamente dentro de esa carpeta del addon.
3. Activá **SealTwist Visual** en la lista de addons. Si estás actualizando durante una sesión, usá `/reload` fuera de combate.

## Controles

| Acción | Control |
| --- | --- |
| Ajustar tamaño, opacidad y visibilidad | Clic izquierdo en el ícono del minimapa o `/st` |
| Mover las runas | Fuera de combate, clic derecho en el ícono. Arrastrá el indicador y soltalo |
| Reubicar el ícono del minimapa | Arrastrá el ícono por el borde |
| Consultar la versión y el estado del visor | `/st diagnostico` |

La [guía del addon](SealTwistVisual/LEEME.txt) incluye todos los comandos.

## Desarrollo

El código que carga el juego está en `SealTwistVisual/`. Las pruebas en `tests/` ejecutan ese mismo Lua con un cliente simulado. Cubren los umbrales de los ecos, avisos, brillo, expiración y ajustes. La apariencia y el comportamiento del cliente en combate se verifican dentro de WoW.

Desde la raíz del repositorio, con Node.js 22, npm y PowerShell 7:

```sh
npm ci
npm test
pwsh -File scripts/package.ps1
```

El empaquetador toma la versión del manifiesto y genera el ZIP en `dist/`. GitHub Actions ejecuta las pruebas y verifica el empaquetado en cada push y pull request.

[Historial de cambios](CHANGELOG.md) · [Licencia MIT](LICENSE)
