# ZK DEX

ZK DEX combina una versión moderna de **DeX Explorer** con una copia fijada de
**UniversalSynSaveInstance (USSI)** para recuperar la experiencia clásica
"Explorer + Properties + Save Instance" de la época de Synapse X.

## Estado del proyecto

Base investigada el 18-09-2026:

- USSI sigue activo; snapshot integrado desde el commit `936066265affb4e4c9889179a8223064514c7820` (16-09-2026).
- DeX Explorer 2.2 es la base visual/Explorer.
- El fallback de Save Instance ya no depende del antiguo URL `luau/SynSaveInstance`.
- USSI queda embebido dentro de `out.lua` y fijado en este repositorio.
- Se añadió SafeMode por defecto, salida binaria, SaveBytecode opcional,
  guardado no reentrante, mejor manejo de errores y diagnóstico de capacidades.
- No se incluyen rutinas de evasión de anti-cheat ni un inyector/executor.

## Uso

Con un entorno autorizado y compatible que ya pueda ejecutar Luau del lado cliente:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZKYONA/DEX/main/loader.lua", true))()
```

Para revisar compatibilidad antes:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZKYONA/DEX/main/diagnostics.lua", true))()
```

En DeX abre **Save Instance**. Para sacar principalmente el mapa, puedes
desactivar **Decompile Scripts**. Safe Mode queda activado por defecto.

> Úsalo solo en experiencias tuyas o donde tengas autorización. El cliente solo
> puede serializar lo que realmente le fue replicado; contenido exclusivamente
> de servidor no aparece mágicamente en la captura.

## Construcción

```bash
python build.py
```

El resultado es `out.lua`. El build incorpora todos los archivos de `modules/`,
incluyendo el snapshot de USSI.

## Mejoras sobre DeX Explorer 2.2

- USSI fijado y embebido;
- corrección del fallback obsoleto;
- SafeMode por defecto;
- salida binaria y SaveBytecode configurables;
- corrección de UI en labels;
- validación de timeout/hilos;
- parser DecompileIgnore robusto;
- bloqueo de doble guardado y errores sin romper la UI;
- TLS para fallback remoto de decompilación;
- diagnóstico de APIs;
- sin bloque de bypass anti-cheat.

## Licencias y créditos

La distribución completa se publica bajo **GNU AGPL v3** por incluir USSI.
El código derivado de DeX conserva también su aviso MIT.

Crédito requerido por USSI:

**UniversalSynSaveInstance https://discord.gg/wx4ThpAsmw**

Consulta `THIRD_PARTY_NOTICES.md`, `third_party/USSI_LICENSE` y
`third_party/DEX_LICENSE`.

Upstreams:
- https://github.com/luau/UniversalSynSaveInstance
- https://github.com/FusionWTF/DeX-Explorer
