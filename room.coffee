PokerEvaluator = require 'poker-evaluator'
exports.Room =
class Room
	constructor: (@hostConn,@id) ->
		@currentPlayer = null
		@currentDealer = null
		@terminatingPlayer = null
		@players = []
		do @initHand
	
	initHand: () ->
		@deck = this.makeDeck()
		@currentRound = 0
		@communalCards = []
		@status = "waiting"
		@currentBet = 0
		@lastRaise = 0
		@gameEnded = false

	makeDeck: () ->
		arr = [].concat.apply([],((c + s for s in ['c','d','h','s']) for c in ['2','3','4','5','6','7','8','9','T','J','Q','K','A']))
		((a) ->
			i = a.length
			while --i > 0
				j = ~~(Math.random() * (i+1))
				t = a[j]
				a[j] = a[i]
				a[i] = t
			a) arr
	
	startGame: () ->
		if @players.length < 3
			return "action":"startGame","response":"Not enough players"
		@currentDealer = @players[0]
		p = @players[0]
		p.prevPlayer = @players[@players.length-1]
		i = 1
		while i < @players.length
			p.nextPlayer = @players[i]
			@players[i].prevPlayer = p
			p = p.nextPlayer
			i++
		p.nextPlayer = @players[0]
		this.dealHand()
		return "action":"startGame","response":"Have fun"

	dealHand: () ->
		@gameEnded = false
		for p in @players
			p.currentBet = 0
			p.cards = []
			p.isFolded = false
		dealerCount = 0
		smallBlind = @currentDealer.nextPlayer #small
		smallBlind.currentBet = 25
		bigBlind = smallBlind.nextPlayer
		bigBlind.currentBet = 50 #big
		@round = 0
		@currentBet = 50
		@lastRaise = @currentBet
		for pp in @players
			st = ""
			if pp == @currentDealer
				pp.name = st = "dealer"
			else if pp == smallBlind
				pp.name = st = "smallBlind"
			else if pp == bigBlind
				pp.name = st = "bigBlind"
			pp.conn.write JSON.stringify("action":"handSetup","status":st)

		@terminatingPlayer = bigBlind.nextPlayer
		p = smallBlind
		while dealerCount != 2
			c = @deck.pop()
			p.cards.push(c)
			p.conn.write JSON.stringify("action":"showCard","card":c)
			dealerCount++ if p == @currentDealer
			p = p.nextPlayer
		@currentPlayer = @terminatingPlayer
		for p in @players
			console.log "currentBet: " + @currentBet + ",p.currentBet: " + p.currentBet
			p.conn.write JSON.stringify("action":"status","info":{"callAmount":@currentBet-p.currentBet,"raiseAmount":@lastRaise,"canGo": p == @currentPlayer})

	addPlayer: (player) ->
		if @players.length == 9
			return false
		@players.push player
		player.seat = @players.length
		@hostConn.write JSON.stringify("action":"playerJoined","player":{"name":player.name,"picture":player.pic, "userid":player.uuid,"seat":@players.length})
		return true


	checkCall: (aConn) ->
		return "action":"checkCall","response":"Not your turn" if @currentPlayer.conn != aConn
		console.log @currentPlayer.name + " check/Call from " + @currentPlayer.currentBet + " to " + @currentBet
		@currentPlayer.currentBet = @currentBet
		do @step
		

	raise: (aConn, amount) ->
		return "action":"raise","response":"Not your turn" if @currentPlayer.conn != aConn
		return "action":"raise","response":"Too low" if amount < @lastRaise
		@currentBet += amount
		console.log @currentPlayer.name + " raises by " + amount + " to total " + @currentBet
		@lastRaise = amount
		@currentPlayer.currentBet = @currentBet
		@terminatingPlayer = @currentPlayer
		do @step
	
	fold: (aConn, bet) ->
		return "action":"fold","response":"Not your turn" if @currentPlayer.conn != aConn
		console.log @currentPlayer.name + "folds"
		@currentPlayer.isFolded = true
		do @step

	step: () ->
		return @sadEnding(@lonelyPlayer()) if @lonelyPlayer()?
		for p in @players
			p.conn.write JSON.stringify("action":"status","info":{"callAmount":@currentBet-p.currentBet,"raiseAmount":@lastRaise,"canGo":false})
		op = @currentPlayer
		@currentPlayer = @currentPlayer.nextPlayer
		while @currentPlayer != @terminatingPlayer
			if not @currentPlayer.isFolded
				console.log op.name + "->" + @currentPlayer.name
				@currentPlayer.conn.write JSON.stringify("action":"status","info":{"callAmount":@currentBet-@currentPlayer.currentBet,"raiseAmount":@lastRaise,"canGo":true})
				if not @terminatingPlayer?
					@terminatingPlayer = @currentPlayer
				return null
			@currentPlayer = @currentPlayer.nextPlayer
		do @nextRound

	
	lonelyPlayer: () ->
		loner = null
		for p in @players
			if loner? and not p.isFolded
				return null
			if not p.isFolded
				loner = p
		return loner


	nextRound: () ->
		switch @currentRound
			when 0
				#flop
				for [1..2]
					@deck.pop()
					@hostConn.write JSON.stringify("action":"burn")
				for [1..3]
					c = @deck.pop()
					@hostConn.write JSON.stringify("action":"showCard","card":c)
					@communalCards.push(c)

			when 1, 2
				@deck.pop()
				@hostConn.write JSON.stringify("action":"burn")
				c = @deck.pop()
				@hostConn.write JSON.stringify("action":"showCard","card":c)
				@communalCards.push(c)

			when 3
				return @endHand()

		@currentRound++
		@currentPlayer = @currentDealer
		@terminatingPlayer = null
		do @step
		return null

	sadEnding: (player) ->
		@splitPot [player]

	endHand: () ->
		results = []
		max = -1
		for p in @players
			hand = p.cards.concat @communalCards

			score = PokerEvaluator.evalHand(hand)
			results.push([p,score])
			console.log p.name + "\n" + JSON.stringify(score)
		
		results.sort (a,b) ->
			b[1].value - a[1].value

		max = results[0][1].value
		winners = []
		for pair in results
			winners.push(pair[0]) if pair[1].value == max and not pair[0].isFolded

		@splitPot winners
	
	splitPot: (winners) ->
		pot = 0
		for p in @players
			pot += p.currentBet
		winnings = (pot / winners.length).toFixed(2)

		for p in @players
			cashOut = 0
			for w in winners
				if w == p
					cashOut = winnings
					break
			p.conn.write JSON.stringify("action":"handOver","winnings": cashOut)
		for p in @players
			p.conn.write JSON.stringify("action":"status","info":{"callAmount":0,"raiseAmount":0,"canGo":false})
		@gameEnded = true
		return null

	newHand: (conn) ->
		return "action":"newHand","response":"No." if conn != @hostConn
		return "action":"newHand","response":"Game currently in progress" if not @gameEnded
		do @initHand
		@currentDealer = @currentDealer.nextPlayer
		do @dealHand
		return null

