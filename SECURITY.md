# Runtime safety

ZK DEX no longer enforces an internal authorization/allowlist gate.

The runtime still keeps non-authorization safeguards:
- map-only mode by default;
- block incomplete streaming snapshots unless explicitly allowed;
- block repeated saves by default;
- configurable instance-count ceiling;
- third-party visual DEX disabled by default;
- no stealth, concealment, or anti-cheat evasion logic.

Use `runtime/config.example.lua` for the recommended defaults.
