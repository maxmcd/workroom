express = require('express')
app = express()
app.use(require("connect-assets")())

http = require('http')
server = http.Server(app)
io = require('socket.io')(server)
redis = require("redis")
client = redis.createClient()

sort_by_time = (a,b) ->
    if a.time < b.time
        return -1
    if a.time > b.time
        return 1
    return 0

# set a views folder
app.set('views', './views')

app.set('view engine', 'jade')
app.engine('jade', require('jade').__express);

# server
server.listen 8000, () ->
  console.log('listening on *:8000');

app.get '/',  (req, res) ->
    client.get "content", (err, reply) ->
        content = reply
        client.get "queue", (err, reply) ->
            queue = reply
            res.render('index', {content: content, queue: queue})


io.on 'connection', (socket) ->

    queue = []

    socket.on 'change', (change) ->
        console.log(change)
        socket.broadcast.emit('remote_change', {change: change.change, time: change.time})
        queue.push(change)
        queue = queue.sort(sort_by_time)
        client.set('queue', JSON.stringify(queue))

    socket.on 'save', (all_content) ->
        queue = []
        client.set('queue', queue)
        client.set('content', all_content, redis.print)

    socket.on 'disconnect', ->
        console.log('a user disconnected')