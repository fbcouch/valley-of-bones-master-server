# (c) 2013 Jami Couch
# APACHE2.0 LICENSE

express = require('express')
app = express();
pg = require('pg')
connectionString = process.env.DATABASE_URL or "pg://secure-caverns:1234@localhost/serverdb"

pg.connect connectionString, (err, client, done) ->
  if err?
    console.log err
    done()
    return
  console.log "database connected"
  client.query(
    """
    CREATE TABLE IF NOT EXISTS games (
      id bigserial primary key,
      version varchar(20),
      date date,
      game text
    );
    """).on 'end', ->
      done()

client = new pg.Client(connectionString)
client.connect()

allowCrossDomain = (req, res, next) ->
  res.header('Access-Control-Allow-Origin', '*')
  res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With')

  if req.method is 'OPTIONS' then res.send(200) else next()

app.use(allowCrossDomain)
app.use(express.bodyParser())

servers = []

app.get '/', (req, res) ->
  res.json(servers)

app.get '/server/:id', (req, res) ->
  server = (server for server in servers when server.id is parseInt(req.params.id))
  if server.length is 0
    res.statusCode = 404
    return res.send('Error 404: No server found')
  res.json(server.pop())

app.post '/server/:id', (req, res) ->
  server = (server for server in servers when server.id is parseInt(req.params.id))
  if (server.length is 0)
    res.statusCode = 404
    return res.send('Error 404: No server found')
  server = server[0]
  server.ip = req.body.ip or server.ip
  server.port = req.body.port or server.port
  server.name = req.body.name or server.name
  server.players = req.body.players or server.players
  server.status = req.body.status or server.status
  res.json({success: true})

app.post '/server', (req, res) ->
  if not (req.body.hasOwnProperty('name'))
    res.statusCode = 400
    console.log req.body
    return res.send('Error 400: Post syntax incorrect')

  newServer =
    id: (servers[servers.length - 1]?.id or 0) + 1
    ip: req.ips?[0] or req.connection.remoteAddress
    port: req.body.port or 54556
    name: req.body.name
    players: req.body.players or 0
    status: req.body.status or 0

  servers.push(newServer)
  res.json({ success: true, id: newServer.id })

app.delete '/server/:id', (req, res) ->
  server = (server for server in servers when server.id is parseInt(req.params.id))
  if server.length is 0
    res.statusCode = 404
    return res.send('Error 404: No server found')

  servers.splice(servers.indexOf(server[0]), 1)
  res.json(true)

app.get '/game/:id', (req, res) ->
  res.statusCode = 501
  return res.send('Error 501: Feature not implemented')

app.get '/game', (req, res) ->
  games = []
  client.query('SELECT * FROM games ORDER BY date DESC').on('row', (result) -> games.push result).on 'end', (result) ->
    res.send(games)

app.post '/game', (req, res) ->
  if not (req.body.hasOwnProperty('version') and req.body.hasOwnProperty('game'))
    res.statusCode = 400
    res.send('Error 400: Post syntax incorrect')

  client.query(
    "INSERT INTO games (date, version, game) VALUES (NOW(), $1, $2)", [req.body.version, req.body.game]
  ).on 'end', (result) ->
    console.log result
    res.send(result)

app.enable('trust proxy')
app.listen process.env.PORT or 4730, ->
  console.log "Listening on #{process.env.PORT or 4730}"