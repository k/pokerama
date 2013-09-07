express = require 'express'
sockjs = require 'sockjs'
routes = require './routes'
path = require 'path'
{Room} = require './room'
{Player} = require './player'
conns = {}
rooms = {}
playerInfo = {}
roomCounter = 0
pl = null


echo = sockjs.createServer()
echo.on 'connection', (conn) ->
	console.log 'connected'
	conn.on 'data', (message) ->
		obj = JSON.parse(message)
		if obj.action == "createRoom"
			rm = new Room(conn,roomCounter++)
			if rm == null
				conn.write JSON.stringify({"roomID":-1})
				return
			rooms[''+rm.id] = rm
			conn.write JSON.stringify({'roomID':rm.id})
			conns[conn] = rm
		else if obj.action == "startGame"
			ret = conns[conn].startGame()
			conn.write JSON.stringify(ret) if ret != null
		else if obj.action == "joinRoom"
			rm = rooms[''+obj.roomID]
			if rm == null
				conn.write JSON.stringify("action":"joinRoom","response":"No such room")
				return
			pl = new Player(conn,"UUID","name")
			if rm.addPlayer pl
				conns[conn] = rm
				conn.write JSON.stringify("action":"joinRoom","response":rm.status)
				return
			else
				conn.write JSON.stringify("action":"joinRoom","response":"cannot join room")
				return
		else if obj.action == "checkCall"
			ret = conns[conn].checkCall conn
			conn.write JSON.stringify(ret) if ret?
		else if obj.action == "raise"
			ret = conns[conn].raise conn obj.bet
			conn.write JSON.stringify(ret) if ret?
		else if obj.action == "fold"
			ret = conns[conn].fold conn
			conn.write JSON.stringify(ret) if ret?
		else
			console.log obj
	conn.on 'close', ->
		console.log 'conn close'
		console.log conns[conn]

app = express()
server = require('http').createServer(app)

echo.installHandlers server, prefix:'/echo'

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
app.get '/player', routes.player
app.get '/choosetable', routes.choosetable

server.listen app.get('port'), '127.0.0.1'

