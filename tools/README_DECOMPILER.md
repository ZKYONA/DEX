# ZK Luau Decompiler V1

Offline educational decompiler for Luau **text disassembly** produced by the official `luau-compile` CLI.

This tool is intentionally separated from the Roblox runtime path. It does not attach to Roblox, inject code, read another process, evade Hyperion, or download protected game content.

## What V1 does

```text
local .luau source
    -> official luau-compile --text
    -> parser
    -> structured IR
    -> control-flow graph (CFG)
    -> Luau-like pseudocode
```

Supported families include constants/register moves, globals/imports/upvalues, arithmetic, basic table operations, calls/returns, closure placeholders, jumps/CFG edges, loop metadata, and conservative preservation of unknown opcodes.

## Requirements

- Python 3.10+
- Official `luau-compile` executable when using `--source`

Start reversing experiments with `-O0 -g2`; optimized bytecode loses more source-level information.

## Fast test without Luau installed

```powershell
python tools/zk_luau_decompiler.py `
  --disasm tools/examples/sample.disasm `
  --format all
```

## Compile and decompile a local Luau file

```powershell
python tools/zk_luau_decompiler.py `
  --source tools/examples/example.luau `
  --format pseudo
```

With an explicit compiler path:

```powershell
python tools/zk_luau_decompiler.py `
  --source tools/examples/example.luau `
  --luau-compile "C:\Tools\Luau\luau-compile.exe" `
  -O 0 -g 2 `
  --format all `
  -o recovered.txt
```

Equivalent manual pipeline:

```powershell
luau-compile.exe --text --dump-constants -O0 -g2 tools/examples/example.luau > sample.disasm
python tools/zk_luau_decompiler.py --disasm sample.disasm --format pseudo
```

## Output modes

- `pseudo`: Luau-like readable pseudocode
- `ir`: parsed instruction representation as JSON
- `cfg`: instruction-level control-flow graph as JSON
- `all`: all three

## Tests

```powershell
python -m pip install pytest
python -m pytest -q tools/tests
```

## V1 limitations

- consumes the official text dump rather than Roblox client memory;
- does not parse a raw Roblox client bytecode blob;
- full structured `if/elseif/else`, `while`, numeric `for` and generic `for` recovery is not complete;
- original local names are not always recoverable;
- optimized `FASTCALL`, inlining and constant folding reduce fidelity;
- closure/upvalue reconstruction is intentionally conservative.

## V2 roadmap

1. Basic-block CFG.
2. Dominators/post-dominators.
3. `if/else` pattern reconstruction.
4. Natural-loop detection.
5. SSA-like register versioning.
6. Expression folding without duplicated side effects.
7. Nested prototype/closure reconstruction.
8. Opcode coverage tied to current Luau definitions.
9. Golden tests generated at O0/O1/O2.

Use it only on source/bytecode you own or are authorized to analyze.
