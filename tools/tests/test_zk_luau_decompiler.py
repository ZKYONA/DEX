import importlib.util
from pathlib import Path
import sys

MODULE_PATH = Path(__file__).resolve().parents[1] / "zk_luau_decompiler.py"
spec = importlib.util.spec_from_file_location("zk_luau_decompiler", MODULE_PATH)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)

SAMPLE = """Function 0 (math):
LOADN R0 5
LOADN R1 10
ADD R2 R0 R1
RETURN R2 1

Function 1 (branch):
LOADB R0 1
JUMPIFNOT R0 L0
LOADN R1 7
JUMP L1
L0:
LOADN R1 9
L1:
RETURN R1 1
"""

def test_parse_functions():
    p = mod.parse_disassembly(SAMPLE)
    assert len(p.functions) == 2
    assert p.functions[0].name == "math"
    assert p.functions[0].instructions[2].opcode == "ADD"

def test_pseudocode_arithmetic():
    p = mod.parse_disassembly(SAMPLE)
    out = mod.PseudoDecompiler(p.functions[0]).run()
    assert "(5 + 10)" in out
    assert "return (5 + 10)" in out

def test_cfg_has_branch_and_fallthrough():
    p = mod.parse_disassembly(SAMPLE)
    cfg = mod.build_cfg(p.functions[1])
    kinds = [e["kind"] for e in cfg["edges"]]
    assert "branch" in kinds
    assert "fallthrough" in kinds
    assert p.functions[1].labels["L0"] == 4
    assert p.functions[1].labels["L1"] == 5

def test_unknown_opcode_is_preserved():
    p = mod.parse_disassembly("Function 0 (x):\nWEIRDOP R0 R1\nRETURN R0 1\n")
    out = mod.PseudoDecompiler(p.functions[0]).run()
    assert "unsupported: WEIRDOP R0 R1" in out
