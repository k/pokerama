exports.Player =
class Player
	constructor: (@uuid, @name, @seat) ->
		@cards = []
		@nextPlayer = null
		@previousPlayer = null
		@currentBet = 0
		@isFolded = false
	go: ->
		@uuid.write 'ABCD MOTHERFUCKER'


