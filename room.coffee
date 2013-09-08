PokerEvaluator = require 'poker-evaluator'
{Venmo} = require './venmo'
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
		@transactions = []

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
			p.hasFolded = false
			p.hasShownHand = false
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
				st = "dealer"
			else if pp == smallBlind
				st = "smallBlind"
			else if pp == bigBlind
				st = "bigBlind"
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
		@hostConn.write JSON.stringify("action":"hasTurn","userID":@currentPlayer.uuid)

	addPlayer: (conn,player) ->
		if @players.length == 9
			return false
		@players.push player
		player.seat = @players.length
		@hostConn.write JSON.stringify("action":"playerJoined","playerData":{"name":player.name,"picture":player.pic, "userid":player.uuid,"seat":@players.length})
		return true


	checkCall: (aConn) ->
		return "action":"checkCall","response":"Game is over" if @gameEnded
		return "action":"checkCall","response":"Not your turn" if @currentPlayer.conn != aConn
		console.log @currentPlayer.name + " check/Call from " + @currentPlayer.currentBet + " to " + @currentBet
		if @currentPlayer.currentBet < @currentBet
			@hostConn.write JSON.stringify("action":"call","userID":@currentPlayer.uuid,"name":@currentPlayer.name,"amount":@currentBet)
		else
			@hostConn.write JSON.stringify("action":"check","userID":@currentPlayer.uuid,"name":@currentPlayer.name)
		@currentPlayer.currentBet = @currentBet
		do @step
		

	raise: (aConn, amount) ->
		return "action":"raise","response":"Game is over" if @gameEnded
		return "action":"raise","response":"Not your turn" if @currentPlayer.conn != aConn
		return "action":"raise","response":"Too low" if amount < @lastRaise
		@currentBet += amount
		@hostConn.write JSON.stringify("action":"raise","userID":@currentPlayer.uuid,"amount":amount,"stakes":@currentBet)
		console.log @currentPlayer.name + " raises by " + amount + " to total " + @currentBet
		@lastRaise = amount
		@currentPlayer.currentBet = @currentBet
		@terminatingPlayer = @currentPlayer
		do @step
	
	fold: (aConn, bet) ->
		return "action":"fold","response":"Game is over" if @gameEnded
		return "action":"fold","response":"Not your turn" if @currentPlayer.conn != aConn
		console.log @currentPlayer.name + "folds"
		@currentPlayer.hasFolded = true
		do @step

	step: () ->
		return @sadEnding(@lonelyPlayer()) if @lonelyPlayer()?
		for p in @players
			p.conn.write JSON.stringify("action":"status","info":{"callAmount":@currentBet-p.currentBet,"raiseAmount":@lastRaise,"canGo":false})
		op = @currentPlayer
		@currentPlayer = @currentPlayer.nextPlayer
		while @currentPlayer != @terminatingPlayer
			if not @currentPlayer.hasFolded
				console.log op.name + "->" + @currentPlayer.name
				@currentPlayer.conn.write JSON.stringify("action":"status","info":{"callAmount":@currentBet-@currentPlayer.currentBet,"raiseAmount":@lastRaise,"canGo":true})
				if not @terminatingPlayer?
					@terminatingPlayer = @currentPlayer
				@hostConn.write JSON.stringify("action":"hasTurn","userID":@currentPlayer.uuid)
				return null
			@currentPlayer = @currentPlayer.nextPlayer
		do @nextRound

	
	lonelyPlayer: () ->
		loner = null
		for p in @players
			if loner? and not p.hasFolded
				return null
			if not p.hasFolded
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
		orderedPlayers = []
		max = -1
		for p in @players
			hand = p.cards.concat @communalCards
			p.score = PokerEvaluator.evalHand(hand)
			orderedPlayers.push(p)
			console.log p.name + "\n" + JSON.stringify(p.score)
		
		orderedPlayers.sort (a,b) ->
			b.score.value - a.score.value

		for p in orderedPlayers
			if not p.hasFolded
				max = p.score.value
				break

		winners = []
		for p in orderedPlayers
			if not p.hasFolded
				p.hasShownHand = true
				if p.score.value == max
					winners.push(p)

		@splitPot winners
	

	splitPot: (winners) ->
		@gameEnded = true

		pot = 0
		for p in @players
			pot += p.currentBet

		winningUsers = []
		for w in winners
			totalWinnings = 0
			for p in @players
				payOut = (p.currentBet / winners.length)
				totalWinnings += payOut
				if p != w
					message = @generateHumiliatingMessage(w, p, payOut)
					payment = {"payer":p, "payee":w, "amount":payOut, "message":message}
					@transactions.push payment
					console.log "Making Payment: " + p.name + " to " + w.name + " (" + payOut + ") " + message
					#Venmo.makePayment(p.venmoAccessToken, w.venmoId, payOut, message)

			winningUsers.push({"userID":w.uuid,"name":w.name,"amount":totalWinnings.toFixed(2)})

		for p in @players
			p.conn.write JSON.stringify("action":"handOver","winners":winningUsers)
		@hostConn.write JSON.stringify("action":"handOver","winners":winningUsers)
		return null

	reverseTransactions: () ->
		for t in @transactions
			console.log "Reversing Payment: " + t.payer.name + " to " + t.payee.name + " (" + t.amount + ") " + t.message
			#Venmo.makePayment(t.payee.venmoAccessToken, t.payer.venmoId, t.amount, "reverse " + t.message)

	newHand: (conn) ->
		return "action":"newHand","response":"No." if conn != @hostConn
		return "action":"newHand","response":"Game currently in progress" if not @gameEnded
		for p in @players
			p.conn.write JSON.stringify("action":"clearTable")
		@hostConn.write JSON.stringify("action":"clearTable")
		do @initHand
		@currentDealer = @currentDealer.nextPlayer
		@hostConn.write JSON.stringify("action":"moveDealer","userID":@currentDealer.uuid)
		do @dealHand
		return null

	generateHumiliatingMessage: (winner, loser, payoutAmount) ->
		if winner.hasShownHand
			return winner.name + " beat " + loser.name + " with a " + winner.score.handName + " and won " + payoutAmount
		else
			return winner.name + " may have bluffed " + loser.name + " out of " + payoutAmount
	
