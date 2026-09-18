# ZK DEX Runtime

Esta carpeta es el flujo que replica lo que recordabas de **Synapse X + DEX**:

```
Abrir juego de Roblox
        ↓
ejecutar Luau en un runtime ya autorizado/compatible
        ↓
ZK DEX instala saveinstance (USSI)
        ↓
captura lo que el cliente tiene replicado
        ↓
.rbxl / .rbxlx
        ↓
abrir archivo en Roblox Studio
```

## Guardado directo

Ejecuta `autosave.lua`. Por defecto:

- usa USSI fijado al commit `936066265affb4e4c9889179a8223064514c7820`;
- `mode = "optimized"`;
- salida binaria `.rbxl`;
- `SafeMode = true`;
- no intenta decompilar scripts;
- genera un nombre con PlaceId, nombre del juego y fecha.

Configuración opcional antes de ejecutarlo:

```lua
getgenv().ZKDEX_CONFIG = {
    FilePath = "MiMapa", -- USSI agrega .rbxl
    Binary = true,
    SafeMode = true,
    Decompile = false,
    SaveBytecode = false,
}
```

## DEX visual

Ejecuta `dex.lua`. Primero instala nuestro wrapper de `saveinstance` y luego carga
DeX Explorer. Así el botón **Save Instance** usa USSI aunque el runtime no tenga
un `saveinstance` nativo.

## Diagnóstico

Ejecuta `diagnostics.lua` para comprobar las APIs disponibles.

## Límite real

Este modo corre desde el **cliente**, igual que el flujo antiguo. Por eso guarda
lo que ese cliente recibió. No puede inventar `ServerStorage`,
`ServerScriptService`, DataStores ni estado exclusivamente de servidor.

No se incluye un injector ni evasión de anti-cheat.
