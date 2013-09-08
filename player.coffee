exports.Player =
	class Player
		constructor: (@conn, @venmoId, @venmoAccessToken, @name, @pic) ->
		@seat = 0
		@cards = []
		@nextPlayer = null
		@previousPlayer = null
		@currentBet = 0
		@score = null
		@hasFolded = false
		@hasShownHand = false
