#!/usr/bin/env python3
"""
ZK Luau Decompiler V1
=====================

Safe, offline educational decompiler for the *text disassembly* emitted by the
official `luau-compile --text --dump-constants` CLI.

It does not attach to Roblox, inject code, read another process, bypass anti-cheat,
or fetch protected game content.

The goal is to turn Luau VM instructions into:
  1. a structured IR,
  2. a control-flow graph (CFG), and
  3. readable Luau-like pseudocode.

V1 intentionally preserves unknown instructions as comments instead of guessing.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Optional, Tuple

FUNCTION_RE = re.compile(r"^\s*Function\s+(\d+)\s+\((.*?)\):\s*$")
LABEL_RE = re.compile(r"^\s*(L\d+):\s*$")
SOURCE_RE = re.compile(r"^\s*\d+:\s")
INSTR_RE = re.compile(r"^\s*([A-Z][A-Z0-9_]*)\b(?:\s+(.*?))?\s*$")
REG_RE = re.compile(r"^R(\d+)$")
K_RE = re.compile(r"^K(\d+)$")
BRACKET_RE = re.compile(r"\[(.*)\]\s*$")

BRANCH_OPS = {
    "JUMP", "JUMPBACK", "JUMPIF", "JUMPIFNOT",
    "JUMPIFEQ", "JUMPIFLE", "JUMPIFLT", "JUMPIFNOTEQ",
    "JUMPIFNOTLE", "JUMPIFNOTLT",
    "JUMPXEQKNIL", "JUMPXEQKB", "JUMPXEQKN", "JUMPXEQKS",
    "FORNPREP", "FORNLOOP", "FORGPREP", "FORGLOOP",
}

BINARY_OPS = {
    "ADD": "+", "SUB": "-", "MUL": "*", "DIV": "/", "IDIV": "//",
    "MOD": "%", "POW": "^", "AND": "and", "OR": "or",
}
BINARYK_OPS = {
    "ADDK": "+", "SUBK": "-", "MULK": "*", "DIVK": "/", "IDIVK": "//",
    "MODK": "%", "POWK": "^",
}

@dataclass
class Instruction:
    index: int
    opcode: str
    args: List[str]
    raw: str
    annotation: Optional[str] = None

@dataclass
class FunctionIR:
    function_id: int
    name: str
    instructions: List[Instruction]
    labels: Dict[str, int]
    constants: Dict[str, str]

@dataclass
class ProgramIR:
    functions: List[FunctionIR]

def split_annotation(rest: str) -> Tuple[str, Optional[str]]:
    rest = rest.rstrip()
    m = BRACKET_RE.search(rest)
    if not m:
        return rest, None
    return rest[:m.start()].rstrip(), m.group(1).strip()

def tokenize_args(rest: str) -> List[str]:
    if not rest:
        return []
    return [p.rstrip(",") for p in rest.split() if p]

def parse_disassembly(text: str) -> ProgramIR:
    functions: List[FunctionIR] = []
    current: Optional[FunctionIR] = None
    pending_labels: List[str] = []
    index = 0
    in_constants = False

    for raw_line in text.splitlines():
        line = raw_line.rstrip()

        fm = FUNCTION_RE.match(line)
        if fm:
            if current:
                functions.append(current)
            current = FunctionIR(int(fm.group(1)), fm.group(2), [], {}, {})
            pending_labels = []
            index = 0
            in_constants = False
            continue

        if current is None:
            continue

        stripped = line.strip()
        if not stripped:
            continue

        if stripped.startswith("Constants"):
            in_constants = True
            continue

        if in_constants:
            m = re.match(r"^\s*(K\d+|\[\d+\])\s*=\s*(.+?)\s*$", line)
            if m:
                key = m.group(1)
                if key.startswith("["):
                    key = "K" + key[1:-1]
                current.constants[key] = m.group(2)
                continue
            if INSTR_RE.match(stripped) or FUNCTION_RE.match(stripped) or SOURCE_RE.match(stripped):
                in_constants = False

        lm = LABEL_RE.match(line)
        if lm:
            pending_labels.append(lm.group(1))
            continue

        if SOURCE_RE.match(line) or stripped.startswith(("REMARK ", "LOCALS", "TYPE", ";")):
            continue

        im = INSTR_RE.match(line)
        if not im:
            continue

        opcode = im.group(1)
        if opcode in {"Function", "Constants"}:
            continue

        rest = im.group(2) or ""
        operands_text, annotation = split_annotation(rest)
        args = tokenize_args(operands_text)

        if not args and opcode not in {"NOP", "BREAK", "COVERAGE"}:
            continue

        for label in pending_labels:
            current.labels[label] = index
        pending_labels.clear()

        current.instructions.append(
            Instruction(index=index, opcode=opcode, args=args, raw=stripped, annotation=annotation)
        )
        index += 1

    if current:
        functions.append(current)

    return ProgramIR(functions)

def reg_index(token: str) -> Optional[int]:
    m = REG_RE.match(token)
    return int(m.group(1)) if m else None

def parse_annotation_value(annotation: Optional[str]) -> Optional[str]:
    if not annotation:
        return None
    a = annotation.strip()
    if len(a) >= 2 and a[0] in {"'", '"'} and a[-1] == a[0]:
        return a
    if a in {"true", "false", "nil"} or re.match(r"^-?\d+(?:\.\d+)?$", a):
        return a
    return a

class PseudoDecompiler:
    def __init__(self, func: FunctionIR):
        self.func = func
        self.regs: Dict[int, str] = {}
        self.declared: set[int] = set()
        self.lines: List[str] = []
        self.unsupported: Dict[str, int] = {}

    def expr(self, token: str) -> str:
        ri = reg_index(token)
        if ri is not None:
            return self.regs.get(ri, f"r{ri}")
        if K_RE.match(token):
            return self.func.constants.get(token, token.lower())
        return token

    def set_reg(self, token: str, value: str, emit: bool = True):
        ri = reg_index(token)
        if ri is None:
            return
        self.regs[ri] = value
        if emit:
            if ri not in self.declared:
                self.lines.append(f"local r{ri} = {value}")
                self.declared.add(ri)
            else:
                self.lines.append(f"r{ri} = {value}")

    def annotation_or_constant(self, ins: Instruction, arg_index: int = 1) -> str:
        ann = parse_annotation_value(ins.annotation)
        if ann is not None:
            return ann
        if len(ins.args) > arg_index:
            return self.expr(ins.args[arg_index])
        return "nil"

    def call_args(self, base: int, count: int) -> List[str]:
        if count < 0:
            return ["..."]
        return [self.regs.get(base + 1 + i, f"r{base + 1 + i}") for i in range(count)]

    def branch_target(self, ins: Instruction) -> str:
        for arg in reversed(ins.args):
            if re.match(r"^L\d+$", arg):
                return arg
        return "<?>"

    def emit_instruction(self, ins: Instruction):
        op, a = ins.opcode, ins.args

        if op == "NOP":
            return
        if op == "LOADNIL" and a:
            self.set_reg(a[0], "nil")
        elif op == "LOADB" and len(a) >= 2:
            self.set_reg(a[0], "true" if a[1] not in {"0", "false"} else "false")
        elif op == "LOADN" and len(a) >= 2:
            self.set_reg(a[0], a[1])
        elif op in {"LOADK", "LOADKX"} and a:
            self.set_reg(a[0], self.annotation_or_constant(ins))
        elif op == "MOVE" and len(a) >= 2:
            self.set_reg(a[0], self.expr(a[1]))
        elif op in {"GETGLOBAL", "GETIMPORT"} and a:
            value = parse_annotation_value(ins.annotation)
            if value is None and len(a) >= 2:
                value = self.expr(a[1])
            self.set_reg(a[0], value or "_G")
        elif op == "GETUPVAL" and len(a) >= 2:
            self.set_reg(a[0], f"upvalue_{a[1]}")
        elif op == "SETUPVAL" and len(a) >= 2:
            self.lines.append(f"upvalue_{a[1]} = {self.expr(a[0])}")
        elif op == "SETGLOBAL" and a:
            name = parse_annotation_value(ins.annotation) or (a[1] if len(a) > 1 else "global")
            self.lines.append(f"{name} = {self.expr(a[0])}")
        elif op == "NEWTABLE" and a:
            self.set_reg(a[0], "{}")
        elif op == "DUPTABLE" and a:
            self.set_reg(a[0], "{ --[[ duplicated table constant ]] }")
        elif op in BINARY_OPS and len(a) >= 3:
            self.set_reg(a[0], f"({self.expr(a[1])} {BINARY_OPS[op]} {self.expr(a[2])})")
        elif op in BINARYK_OPS and len(a) >= 3:
            rhs = parse_annotation_value(ins.annotation) or self.expr(a[2])
            self.set_reg(a[0], f"({self.expr(a[1])} {BINARYK_OPS[op]} {rhs})")
        elif op == "SUBRK" and len(a) >= 3:
            lhs = parse_annotation_value(ins.annotation) or self.expr(a[1])
            self.set_reg(a[0], f"({lhs} - {self.expr(a[2])})")
        elif op == "DIVRK" and len(a) >= 3:
            lhs = parse_annotation_value(ins.annotation) or self.expr(a[1])
            self.set_reg(a[0], f"({lhs} / {self.expr(a[2])})")
        elif op == "NOT" and len(a) >= 2:
            self.set_reg(a[0], f"(not {self.expr(a[1])})")
        elif op == "MINUS" and len(a) >= 2:
            self.set_reg(a[0], f"(-{self.expr(a[1])})")
        elif op == "LENGTH" and len(a) >= 2:
            self.set_reg(a[0], f"#{self.expr(a[1])}")
        elif op == "CONCAT" and len(a) >= 3:
            b, c = reg_index(a[1]), reg_index(a[2])
            if b is not None and c is not None and c >= b:
                parts = [self.regs.get(i, f"r{i}") for i in range(b, c + 1)]
                self.set_reg(a[0], "(" + " .. ".join(parts) + ")")
            else:
                self.set_reg(a[0], f"({self.expr(a[1])} .. {self.expr(a[2])})")
        elif op == "GETTABLE" and len(a) >= 3:
            self.set_reg(a[0], f"{self.expr(a[1])}[{self.expr(a[2])}]")
        elif op == "GETTABLEN" and len(a) >= 3:
            self.set_reg(a[0], f"{self.expr(a[1])}[{a[2]}]")
        elif op == "GETTABLEKS" and len(a) >= 2:
            key = parse_annotation_value(ins.annotation) or (a[2] if len(a) > 2 else "key")
            key = key.strip("'\"")
            self.set_reg(a[0], f"{self.expr(a[1])}.{key}")
        elif op == "SETTABLE" and len(a) >= 3:
            self.lines.append(f"{self.expr(a[1])}[{self.expr(a[2])}] = {self.expr(a[0])}")
        elif op == "SETTABLEN" and len(a) >= 3:
            self.lines.append(f"{self.expr(a[1])}[{a[2]}] = {self.expr(a[0])}")
        elif op == "SETTABLEKS" and len(a) >= 2:
            key = parse_annotation_value(ins.annotation) or (a[2] if len(a) > 2 else "key")
            key = key.strip("'\"")
            self.lines.append(f"{self.expr(a[1])}.{key} = {self.expr(a[0])}")
        elif op == "SETLIST" and len(a) >= 3:
            table = self.expr(a[0])
            start = reg_index(a[1])
            try:
                count = int(a[2])
            except ValueError:
                count = -1
            if start is not None and count >= 0:
                for i in range(count):
                    self.lines.append(f"table.insert({table}, {self.regs.get(start+i, f'r{start+i}')})")
            else:
                self.lines.append(f"-- SETLIST {table}: variable-length list")
        elif op == "NAMECALL" and len(a) >= 2:
            method = (parse_annotation_value(ins.annotation) or (a[2] if len(a) > 2 else "method")).strip("'\"")
            self.set_reg(a[0], f"{self.expr(a[1])}.{method}")
        elif op == "CALL" and len(a) >= 3:
            base = reg_index(a[0])
            if base is None:
                return
            try:
                argc = int(a[1])
                retc = int(a[2])
            except ValueError:
                argc, retc = -1, 0
            fn = self.regs.get(base, f"r{base}")
            args = self.call_args(base, argc)
            call = f"{fn}({', '.join(args)})"
            if retc == 0:
                self.lines.append(call)
            elif retc == 1:
                self.set_reg(a[0], call)
            elif retc > 1:
                names = []
                for i in range(retc):
                    self.regs[base+i] = f"r{base+i}"
                    if base+i not in self.declared:
                        self.declared.add(base+i)
                    names.append(f"r{base+i}")
                self.lines.append(f"{', '.join(names)} = {call}")
            else:
                self.set_reg(a[0], call + " --[[ multret ]]")
        elif op in {"CLOSURE", "DUPCLOSURE"} and a:
            name = parse_annotation_value(ins.annotation)
            if name:
                self.set_reg(a[0], f"{name} --[[ closure ]]")
            else:
                proto = a[1] if len(a) > 1 else "?"
                self.set_reg(a[0], f"function(...) --[[ proto {proto} ]] end")
        elif op == "CAPTURE":
            self.lines.append(f"-- capture {' '.join(a)}")
        elif op == "RETURN":
            if len(a) < 2:
                self.lines.append("return")
            else:
                base = reg_index(a[0])
                try:
                    count = int(a[1])
                except ValueError:
                    count = 0
                if count <= 0:
                    self.lines.append("return")
                elif base is not None:
                    vals = [self.regs.get(base+i, f"r{base+i}") for i in range(count)]
                    self.lines.append("return " + ", ".join(vals))
                else:
                    self.lines.append("return " + self.expr(a[0]))
        elif op == "JUMP":
            self.lines.append(f"-- goto {self.branch_target(ins)}")
        elif op == "JUMPBACK":
            self.lines.append(f"-- loop back -> {self.branch_target(ins)}")
        elif op in {"JUMPIF", "JUMPIFNOT"} and a:
            cond = self.expr(a[0])
            if op == "JUMPIFNOT":
                cond = f"not ({cond})"
            self.lines.append(f"-- if {cond} then goto {self.branch_target(ins)}")
        elif op.startswith("JUMPIF") and len(a) >= 2:
            self.lines.append(f"-- {op} {' '.join(a)}")
        elif op in {"FORNPREP", "FORNLOOP", "FORGPREP", "FORGLOOP"}:
            self.lines.append(f"-- {op}: {' '.join(a)}")
        elif op.startswith("FASTCALL"):
            self.lines.append(f"-- optimized builtin call: {op} {' '.join(a)}")
        elif op in {"PREPVARARGS", "GETVARARGS"}:
            self.lines.append(f"-- {op}: {' '.join(a)}")
        else:
            self.unsupported[op] = self.unsupported.get(op, 0) + 1
            self.lines.append(f"--[[ unsupported: {ins.raw} ]]")

    def run(self) -> str:
        labels_at: Dict[int, List[str]] = {}
        for label, idx in self.func.labels.items():
            labels_at.setdefault(idx, []).append(label)

        self.lines.append(f"-- Function {self.func.function_id} ({self.func.name})")
        for ins in self.func.instructions:
            if ins.index in labels_at:
                for label in labels_at[ins.index]:
                    self.lines.append(f"-- ::{label}::")
            self.emit_instruction(ins)

        if self.unsupported:
            summary = ", ".join(f"{k} x{v}" for k, v in sorted(self.unsupported.items()))
            self.lines.append(f"-- Unsupported opcode summary: {summary}")
        return "\n".join(self.lines)

def build_cfg(func: FunctionIR) -> dict:
    reverse_labels: Dict[int, List[str]] = {}
    for label, idx in func.labels.items():
        reverse_labels.setdefault(idx, []).append(label)

    nodes = []
    edges = []
    for ins in func.instructions:
        nodes.append({
            "id": ins.index,
            "labels": reverse_labels.get(ins.index, []),
            "opcode": ins.opcode,
            "args": ins.args,
        })

        fallthrough = ins.index + 1
        target = None
        if ins.opcode in BRANCH_OPS:
            for token in reversed(ins.args):
                if token in func.labels:
                    target = func.labels[token]
                    break

        if ins.opcode == "RETURN":
            pass
        elif ins.opcode in {"JUMP", "JUMPBACK"}:
            if target is not None:
                edges.append({"from": ins.index, "to": target, "kind": "jump"})
        elif ins.opcode in BRANCH_OPS:
            if target is not None:
                edges.append({"from": ins.index, "to": target, "kind": "branch"})
            if fallthrough < len(func.instructions):
                edges.append({"from": ins.index, "to": fallthrough, "kind": "fallthrough"})
        elif fallthrough < len(func.instructions):
            edges.append({"from": ins.index, "to": fallthrough, "kind": "fallthrough"})

    return {
        "function_id": func.function_id,
        "name": func.name,
        "nodes": nodes,
        "edges": edges,
    }

def compile_to_text(source: Path, luau_compile: str, optimize: int, debug: int) -> str:
    cmd = [
        luau_compile,
        "--text",
        "--dump-constants",
        f"-O{optimize}",
        f"-g{debug}",
        str(source),
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    if proc.returncode != 0:
        raise RuntimeError("luau-compile failed:\n" + (proc.stderr or proc.stdout or "unknown error"))
    return proc.stdout

def main(argv: Optional[List[str]] = None) -> int:
    ap = argparse.ArgumentParser(
        description="Offline Luau text-disassembly -> IR/CFG/pseudocode decompiler"
    )
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument("--disasm", type=Path, help="Text output from luau-compile --text")
    group.add_argument("--source", type=Path, help="Local .luau source to compile + decompile")
    ap.add_argument("--luau-compile", default="luau-compile", help="Path to official luau-compile executable")
    ap.add_argument("-O", "--optimize", type=int, choices=(0, 1, 2), default=0)
    ap.add_argument("-g", "--debug", type=int, choices=(0, 1, 2), default=2)
    ap.add_argument("--format", choices=("pseudo", "ir", "cfg", "all"), default="pseudo")
    ap.add_argument("-o", "--output", type=Path)
    ns = ap.parse_args(argv)

    if ns.source:
        text = compile_to_text(ns.source, ns.luau_compile, ns.optimize, ns.debug)
    else:
        text = ns.disasm.read_text(encoding="utf-8")

    program = parse_disassembly(text)
    if not program.functions:
        print("No functions were parsed. Is this official luau-compile --text output?", file=sys.stderr)
        return 2

    parts: List[str] = []
    if ns.format in {"pseudo", "all"}:
        parts.append("\n\n".join(PseudoDecompiler(f).run() for f in program.functions))
    if ns.format in {"ir", "all"}:
        parts.append(json.dumps(asdict(program), indent=2, ensure_ascii=False))
    if ns.format in {"cfg", "all"}:
        parts.append(json.dumps([build_cfg(f) for f in program.functions], indent=2, ensure_ascii=False))

    out = "\n\n".join(parts) + "\n"
    if ns.output:
        ns.output.write_text(out, encoding="utf-8")
    else:
        sys.stdout.write(out)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
