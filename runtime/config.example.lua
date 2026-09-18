-- ZK DEX runtime configuration example

getgenv().ZKDEX_CONFIG = {
	-- Recommended capture profile:
	MapOnly = true,
	Binary = true,
	SafeMode = true,

	-- Set true only if you intentionally want a partial snapshot when
	-- Workspace.StreamingEnabled is active.
	AllowStreamingIncomplete = false,

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
