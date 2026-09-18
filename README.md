# ZK DEX

> Hay **dos modos** en este repositorio:
> 1. `runtime/`: el flujo clásico tipo Synapse/DEX — abres un juego, ejecutas el script en un runtime compatible y se genera un place `.rbxl/.rbxlx`.
> 2. `src/`: plugin de Roblox Studio para proyectos abiertos directamente en Studio.


ZK DEX es una recreación **para Roblox Studio y proyectos autorizados** de la parte útil de la experiencia clásica DEX/Synapse: Explorer, Properties y exportación del mapa.

## Qué incluye

- panel tipo DEX dentro de Studio;
- árbol de `Workspace`;
- inspector de propiedades comunes y Attributes;
- sincronización con `Selection`;
- **Save Selection** usando el diálogo oficial de Studio;
- **Save Workspace Map** para guardar el mapa como modelo de Roblox;
- contador de instancias del DataModel;
- un archivo principal **autocontenido**, para poder guardarlo directamente como Local Plugin.

## Qué no incluye

No incluye inyector de cliente, evasión de anti-cheat ni técnicas para ejecutar código dentro de experiencias ajenas. Para un place donde tengas permiso de edición, Studio accede al DataModel completo y es más fiable que reconstruir un mapa desde un cliente parcial.

## Instalación rápida

1. Abre Roblox Studio.
2. Inserta un **Script** en `ServerStorage`.
3. Copia dentro el contenido de `src/ZKDexPlugin.server.lua`.
4. Selecciona ese Script.
5. En **Plugins**, elige **Save as Local Plugin / Guardar como complemento local**.
6. Abre **ZK DEX** desde la barra de plugins.

Roblox documenta oficialmente este flujo para crear plugins locales.

## Guardar un mapa

- **Save Selection** guarda los objetos actualmente seleccionados.
- **Save Workspace Map** selecciona temporalmente todos los hijos de primer nivel de `Workspace` salvo `Camera`, abre `Plugin:PromptSaveSelectionAsync()` y luego restaura tu selección anterior.

Esto genera un archivo de modelo de Roblox que puedes volver a insertar en Studio.

## Estructura

```
src/
  ZKDexPlugin.server.lua     # plugin autocontenido
  modules/                   # versión modular para desarrollo
    Explorer.lua
    Inspector.lua
    Exporter.lua
default.project.json
```

## Próximas mejoras útiles

- búsqueda y filtros tipo DEX;
- árbol expandible/colapsable en vez de lista completa;
- soporte específico para Lighting, Terrain y servicios adicionales;
- snapshot A/B y diff de instancias;
- exportador de dependencias de MeshId, TextureID, SoundId y AnimationId;
- empaquetado automático como `.rbxm`.

## Enfoque

La meta es conservar la experiencia visual de DEX y la capacidad de llevar un mapa autorizado a Studio, usando APIs oficiales del editor y sin depender de un executor externo.


## Modo Runtime — el que replica Synapse + DEX

Para el flujo que buscabas, usa `runtime/`.

### Guardado inmediato del place cargado

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZKYONA/DEX/main/runtime/autosave.lua", true))()
```

El archivo generado queda en el directorio de archivos/workspace que exponga tu runtime y luego se abre con Roblox Studio.

### DEX visual + Save Instance

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZKYONA/DEX/main/runtime/dex.lua", true))()
```

Este loader instala primero un wrapper `saveinstance` basado en **UniversalSynSaveInstance (USSI)** fijado a una versión conocida y después abre DeX Explorer.

### Diagnóstico

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZKYONA/DEX/main/runtime/diagnostics.lua", true))()
```

El runtime debe proporcionar como mínimo `loadstring`, `game:HttpGet` y `writefile` para el guardado por USSI.

**UniversalSynSaveInstance https://discord.gg/wx4ThpAsmw**

USSI: https://github.com/luau/UniversalSynSaveInstance  
DeX Explorer: https://github.com/FusionWTF/DeX-Explorer
