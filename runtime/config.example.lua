-- ZK DEX runtime configuration example

getgenv().ZKDEX_CONFIG = {
	-- Recommended capture profile:
	MapOnly = true,
	Binary = true,
	SafeMode = true,

	-- Set true only if you intentionally want a partial snapshot when
	-- Workspace.StreamingEnabled is active.
	AllowStreamingIncomplete = false,

	-- Read-only validation mode. When true, autosave exits before downloading
	-- the serializer or writing any file.
	DryRun = false,

	-- Runtime stability guards:
	MaxInstances = 400000,
	SettleSeconds = 3,
	AllowRepeat = false,
	RepeatCooldownSeconds = 300,

	-- Visual DEX downloads third-party UI code.
	AllowExternalDexUI = false,

	-- Optional output name:
	-- FilePath = "MyMap",
}


-- Emergency kill-switch (set at any time before serialization starts):
-- getgenv().ZKDEX_ABORT = true
