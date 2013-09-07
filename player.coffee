exports.Player =
class Player
	constructor: (@conn,@uuid, @name, @pic, @token) ->
		@seat = 0
		@cards = []
		@nextPlayer = null
		@previousPlayer = null
		@currentBet = 0
		@isFolded = false


