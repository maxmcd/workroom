express = require('express')
app = express()
http = require('http')
server = http.Server(app)
io = require('socket.io')(server)
redis = require("redis")
client = redis.createClient()

# set a views folder
app.set('views', './views')


app.set('view engine', 'jade')
app.engine('jade', require('jade').__express);

app.use(express.static(process.cwd() + '/public'));

# server
server.listen 8000, () ->
  console.log('listening on *:8000');

app.get '/',  (req, res) ->
    client.get "content", (err, reply) ->
        res.render('index', {content: reply})



io.on 'connection', (socket) ->

    socket.on 'change', (change) ->
        console.log(change)
        client.set('content', change.all_content, redis.print)
        socket.broadcast.emit('remote_change', change.change)

    socket.on 'disconnect', ->
        console.log('a user disconnected')