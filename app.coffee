express = require 'express'
sockjs = require 'sockjs'
routes = require './routes'
path = require 'path'
{Room} = require './room'
{Player} = require './player'
conns = {}
rooms = {}
playerInfo = {}
roomCounter = 9001


echo = sockjs.createServer()
echo.on 'connection', (conn) ->
	console.log 'connected'
	conn.on 'data', (message) ->
		if message == "cr"
			obj = "action":"createRoom"
		else if /jr (\d+)/.exec(message)?
			m = /jr (\d+)/.exec(message)
			rm = rooms[m[1]]
			console.log rm
			if not rm?
				conn.write JSON.stringify("action":"joinRoom","response":"No such room")
				return
			console.log routes.temp
			pl = new Player(conn, 'userID', '1000', "player", null)
			if rm.addPlayer conn, pl
				conns[conn] = rm
				conn.write JSON.stringify("action":"joinRoom","response":rm.status)
				return
			else
				conn.write JSON.stringify("action":"joinRoom","response":"cannot join room")
				return
		else if message == "start"
			obj = "action":"startGame"
		else if message == "fold"
			obj = "action":"fold"
		else if message == "check" or message == "call" or message == "c"
			obj = "action":"checkCall"
		else if message == "nextHand"
			obj = "action":"nextHand"
		else if message == "unfuck" or message == "communism"
			obj = "action":"reverseTransactions"
		else if /raise (\d+)/.exec(message)?
			m = /raise (\d+)/.exec(message)
			obj = "action":"raise","amount":parseInt(m[1])
		else
			try
				obj = JSON.parse(message)
				console.log obj
			catch
				console.log "FLAILURE: " + message
				return
		if obj.action == "createRoom"
			rm = new Room(conn,roomCounter++)
			if not rm?
				conn.write JSON.stringify({"roomID":-1})
				return
			rooms["#{rm.id}"] = rm
			conn.write JSON.stringify({'roomID':rm.id})
			conns[conn] = rm
		else if obj.action == "startGame"
			if conns[conn]?
				ret = conns[conn].startGame(obj.blind)
				conn.write JSON.stringify(ret) if ret != null
			else
				console.log "CRY MOTHERFUCKER."
		else if obj.action == "joinRoom"
			console.log "JOIN ROOM"
			rm = rooms["#{obj.room}"]
			if not rm?
				conn.write JSON.stringify("action":"joinRoom","response":"No such room")
				return
			player = routes.temp[''+obj.userID]
			if not player.access_token? or not player.user?
				conn.write "fuck you"
				return
			pl = new Player(conn, obj.userID, player.access_token, player.user.name, player.user.picture)
			routes.temp[''+obj.userID] = null
			if rm.addPlayer conn, pl
				console.log rm.status
				conns[conn] = rm
				conn.write JSON.stringify("action":"joinRoom","response":rm.status)
				return
			else
				console.log "JOIN FAIL"
				conn.write JSON.stringify("action":"joinRoom","response":"cannot join room")
				return
		else if obj.action == "checkCall"
			ret = conns[conn].checkCall conn
			conn.write JSON.stringify(ret) if ret?
		else if obj.action == "raise"
			ret = conns[conn].raise(conn,obj.amount)
			conn.write JSON.stringify(ret) if ret?
		else if obj.action == "fold"
			ret = conns[conn].fold conn
			conn.write JSON.stringify(ret) if ret?
		else if obj.action == "nextHand"
			ret = conns[conn].nextHand conn
			conn.write JSON.stringify(ret) if ret?
		else if obj.action == "reverseTransactions"
			ret = do conns[conn].reverseTransactions
			conn.write JSON.stringify(ret) if ret?
		else
			console.log obj
	conn.on 'close', ->
		console.log 'conn close'
		console.log conns[conn]

app = express()
server = require('http').createServer(app)

echo.installHandlers server, prefix:'/poker'

app.set 'port', process.env.PORT || 3000
app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'
app.use express.favicon()
app.use express.logger('dev')
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use '/assets', express.static('assets')
app.get '/', routes.index
app.get '/comconsole', routes.comconsole
app.get '/choosetable', routes.choosetable
app.get '/player', routes.player

server.listen app.get('port'), '0.0.0.0'

