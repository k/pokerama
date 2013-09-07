express = require 'express'
sockjs = require 'sockjs'
routes = require './routes'
path = require 'path'

{Player} = require './player'
conns = []
pl = null
echo = sockjs.createServer()
echo.on 'connection', (conn) ->
	conns.push conn
	pl = new Player conn,'b','c'
	console.log 'connected'
	conn.on 'data', (message) ->
		conn.write conns.indexOf conn
		conn.write JSON.parse(message).STUFF
	conn.on 'close', ->
		console.log 'conn close'

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
app.get '/choosetable', routes.choosetable
app.get '/player', routes.playerControl
app.post '/player', routes.player

server.listen app.get('port'), '127.0.0.1'

