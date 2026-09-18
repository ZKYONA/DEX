# ZK DEX

ZK DEX es una recreación **para Roblox Studio y proyectos autorizados** de la parte útil de la experiencia clásica DEX/Synapse: Explorer, Properties y exportación del mapa.

## Qué incluye

- panel tipo DEX dentro de Studio;
- árbol de `Workspace`;
- inspector de propiedades comunes;
- sincronización con `Selection`;
- botón para guardar la selección como archivo de modelo de Roblox;
- botón **Save Workspace Map** que selecciona temporalmente los objetos de nivel superior de Workspace y abre el diálogo oficial de guardado de Studio;
- diagnóstico de cantidad de instancias.

## Qué no incluye

No incluye inyector de cliente, evasión de anti-cheat ni técnicas para ejecutar código dentro de experiencias ajenas. Para un place donde tengas permiso de edición, Studio ya tiene acceso al DataModel completo y resulta más fiable que intentar reconstruirlo desde un cliente parcial.

## Instalación rápida

1. Abre Roblox Studio.
2. Crea un Script local de plugin y pega `src/ZKDexPlugin.server.lua`.
3. Guarda el Script como **Local Plugin**.
4. Activa **ZK DEX** desde la barra de plugins.

## Guardar un mapa

- **Save Selection** guarda los objetos seleccionados usando `Plugin:PromptSaveSelectionAsync()`.
- **Save Workspace Map** toma los hijos de primer nivel de `Workspace`, los selecciona temporalmente, abre el diálogo de guardado y luego restaura tu selección original.

Roblox documenta `PromptSaveSelectionAsync` como una API oficial de plugins para guardar la selección.

## Estructura

```
src/
  ZKDexPlugin.server.lua
  modules/
    Explorer.lua
    Inspector.lua
    Exporter.lua
default.project.json
```

## Enfoque

La meta es replicar el flujo visual de DEX y la capacidad de sacar el mapa a Studio cuando trabajas con un proyecto autorizado, sin depender de executors externos.
