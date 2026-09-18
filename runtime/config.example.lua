-- ZK DEX safety configuration.
-- Replace example IDs only with places/universes you are authorized to test.

getgenv().ZKDEX_CONFIG = {
	Authorization = {
		Acknowledgement = "I_HAVE_PERMISSION_TO_TEST_THIS_PLACE",

		AllowedPlaceIds = {
			-- [1234567890] = true,
		},

		AllowedGameIds = {
			-- [9876543210] = true,
		},

		AllowedCreatorIds = {
			-- [12345678] = true,
		},

		RequirePrivateServer = true,
	},

	MapOnly = true,
	AllowStreamingIncomplete = false,
	MaxInstances = 400000,
	SettleSeconds = 3,
	AllowRepeat = false,
	RepeatCooldownSeconds = 300,
}
