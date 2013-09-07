pokerEvaluator = require 'poker-evaluator'
exports.Room =
class Room
	constructor: (@hostConn,@id) ->
		@players = []
		@currentPlayer = null
		@currentDealer = null
		this.makeDeck
		@terminatingPlayer = null
		@currentRound = 0
		@communalCards = []
		@status = "waiting"
		@currentBet = 0
		@lastBet = 0

	makeDeck: () ->
		arr = [].concat.apply([],((c + s for s in ['c','d','h','s']) for c in ['2','3','4','5','6','7','8','9','T','J','Q','K','A']))
		@deck = ((a) ->
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
		return "action":"startGame","response":"Have fun!"

	dealHand: () ->
		for p in @players
			p.currentBet = 0
			p.cards = []
			p.isFolded = false
		dealerCount = 0
		p = @currentDealer.nextPlayer
		p.currentBet = 25
		p.nextPlayer.currentBet = 50
		for pp in players
			st = ""
			if pp == @currentDealer
				st = "dealer"
			else if pp == p
				st = "smallBlind"
			else if pp == p.nextPlayer
				st = "bigBlind"
			pp.conn.write JSON.stringify("action":"handSetup","status":st)

		@terminatingPlayer = p.nextPlayer
		while dealerCount != 2
			c = @deck.pop()
			p.cards.push(c)
			p.conn.write JSON.stringify("action":"showCard","card":c)
			dealerCount++ if p == @currentDealer
			p = p.nextPlayer
		@currentPlayer = @terminatingPlayer.nextPlayer
		for p in @players
			p.conn.write JSON.stringify("action":"status","info":{"callAmount":@currentBet-p.currentBet,"raiseAmount":@lastBet,"canGo": p == @currentPlayer})

	addPlayer: (player) ->
		if @player.length == 9
			return false
		@players.push player
		player.seat = @players.length
		@hostConn.write JSON.stringify("action":"playerJoined","player":{"name":player.name,"picture":player.pic, "userid":player.uuid,"seat":@players.length})
		return true


	checkCall: (aConn) ->
		return "action":"checkCall","response":"Not your turn" if @currentPlayer.conn != aConn
		@currentPlayer.currentBet = @currentBet
		do step
		

	raise: (aConn, bet) ->
		return "action":"checkCall","response":"Not your turn" if @currentPlayer.conn != aConn
		@currentBet += bet
		@lastBet = bet
		@currentPlayer.currentBet = @currentBet
		@terminatingPlayer = @currentPlayer
		do step
	
	fold: (aConn, bet) ->
		return "action":"checkCall","response":"Not your turn" if @currentPlayer.conn != aConn
		@currentPlayer.isFolded = true
		do step

	step: () ->
		do endHand if hasLonelyPlayer()
		for p in players
			p.conn.write JSON.stringify("action":"status","info":{"callAmount":@currentBet-p.currentBet,"raiseAmount":@lastBet,"canGo":false})
		while @currentPlayer.nextPlayer != @terminatingPlayer
			@currentPlayer = @currentPlayer.nextPlayer
			if not @currentPlayer.isFolded
				@currentPlayer.conn.write JSON.stringify("action":"status","info":{"callAmount":@currentBet-p.currentBet,"raiseAmount":@lastBet,"canGo":true})
				return
		do nextRound
	
	hasLonelyPlayer: () ->
		i = 0
		for p in players
			i++ if p.isFolded
		return i == @players.length - 1

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
					@communalCards.add(c)

			when 1, 2
				@deck.pop()
				@hostConn.write JSON.stringify("action":"burn")
				c = @deck.pop()
				@hostConn.write JSON.stringify("action":"showCard","card":c)
				@communalCards.add(c)

			when 3
				do endHand

		@currentRound++


	endHand: () ->
		results = []
		max = -1
		for p in @player
			hand = []
			for c in p.cards
				hand.add(c)
			for c in @communalCards
				hand.add(c)

			score = PokerEvaluator.evalHand(hand)
			results.add([p,score])
		
		results.sort (a,b) ->
			b[1].value - a[1].value

		max = results[0][1].value
		winners = []
		for pair in results
			winners.add(pair[0]) if pair[1].value == max
		pot = 0
		for p in @players
			pot += p.currentBet
		winnings = (pot / winners.length).toFixed(2)

		for p in @players
			cashOut = p in winners ? winnings : 0
			p.conn.write JSON.stringify("action":"handOver","winnings": cashOut)


