
express = require('express')
app = express()
logger = require('morgan')
app.use(logger('dev',  {
    skip: (req, res) ->  
        req.url.indexOf('/assets/') != -1
        # false

}))
app.use(require("connect-assets")())
app.use(express.static(process.cwd() + '/public'))

http = require('http')
server = http.Server(app)
io = require('socket.io')(server)
redis = require("redis")
redis_client = redis.createClient()
redis_lock = require("redis-lock")(redis_client);

sha1 = require('sha1')


sort_by_time = (a,b) ->
    if a.time < b.time
        return -1
    if a.time > b.time
        return 1
    return 0

# set a views folder
app.set('views', './views')

app.set('view engine', 'jade')
app.engine('jade', require('jade').__express)

# # initialise redis
# redis_client.get "users", (err, reply) ->
#     redis_client.set "users", "[]"

# redis_client.get "rooms", (err, reply) ->
#     redis_client.set "rooms", "[]"


# server
server.listen 8000, () ->
  console.log('listening on *:8000')

app.get '/',  (req, res) ->
    res.render('index')
    # redis_client.get "content", (err, reply) ->
    #     content = reply
    #     redis_client.get "queue", (err, reply) ->
    #         queue = reply
    #         res.render('index', {content: content, queue: queue})

app.get '/:id',  (req, res) ->
    is_ajax_request = req.xhr
    room_name = res.req.params.id

    redis_client.get (room_name + '_content'), (err, reply) ->
        console.log(reply)
        if reply
            content = reply
            redis_client.get "queue", (err, reply) ->
                queue = reply
                room_object = {
                    content: content, 
                    queue: queue,
                    id: room_name
                }
                if is_ajax_request
                    res.json(room_object)
                else
                    res.render('index', room_object)
        else
            if is_ajax_request
                res.status(404).send('Sorry, we cannot find that!');
            else
                res.writeHead 302, {
                  'Location': '/'
                }
                res.end()


io.on 'connection', (socket) ->
    console.log('a user connected')

    if socket.request._query.room_name?
        room_name = socket.request._query.room_name
        socket.join(room_name)
        console.log('user joined' + room_name)

    queue = []

    socket.on 'match', () ->
        redis_lock "users", (done) ->
            redis_client.get "users", (err, reply) ->
                users = JSON.parse(reply)
                console.log(users)
                if users.length > 0
                    matched_user = users[0]
                    users.splice(0,1)
                else
                    users = [socket.id]
                    matched_user = null
                redis_client.set('users', JSON.stringify(users))
                done()
                console.log(matched_user)
                if matched_user?
                    room_name = sha1((new Date).getTime() + Math.random()).slice(0,10)
                    console.log(room_name)
                    io.sockets.connected[matched_user].emit('start', room_name)
                    io.sockets.connected[matched_user].join(room_name)
                    io.sockets.connected[socket.id].emit('start', room_name);
                    io.sockets.connected[socket.id].join(room_name)
                    redis_client.set(room_name + '_content', 'placeholder')


    socket.on 'change', (params = {room_name: null, change: null, time: null}) ->
        socket.broadcast.to(params.room_name).emit('remote_change', {
            change: params.change
        })
        queue.push(params.change)
        queue = queue.sort(sort_by_time)
        redis_client.set(params.room_name + '_queue', JSON.stringify(queue))

    socket.on 'save', (params = {content: null, room_name: null}) ->
        redis_client.set(params.room_name + '_queue', null)
        redis_client.set(params.room_name + '_content', params.content, redis.print)

    socket.on 'disconnect', ->
        console.log('a user disconnected')