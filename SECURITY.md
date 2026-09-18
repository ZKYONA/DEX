# Safety mode

The runtime now fails closed unless the current place or universe is explicitly allowlisted.

Recommended settings:
- explicit authorization acknowledgement;
- allowlisted PlaceId or GameId;
- private/reserved server requirement;
- map-only mode;
- block incomplete streaming snapshots;
- block repeated runs;
- keep third-party visual UI disabled unless intentionally enabled.

Use `runtime/config.example.lua` as the starting configuration.

These safeguards are intended to prevent accidental execution in the wrong environment. They do not provide stealth, concealment, or a guarantee against platform enforcement.
