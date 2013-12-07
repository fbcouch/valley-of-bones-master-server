# (c) 2013 Jami Couch
# APACHE2.0 LICENSE

express = require('express')
app = express();

app.use(express.bodyParser())

servers = []

app.get '/', (req, res) ->
  res.json(servers)

app.get '/server/random', (req, res) ->
  id = Math.floor(Math.random() * servers.length)
  res.json(servers[id])

app.get '/server/:id', (req, res) ->
  server = (server for server in servers when server.id is parseInt(req.params.id))
  if server.length is 0
    res.statusCode = 404
    return res.send('Error 404: No server found')
  res.json(server.pop())

app.post '/server', (req, res) ->
  if not (req.body.hasOwnProperty('ip') and req.body.hasOwnProperty('name'))
    res.statusCode = 400
    console.log req.body
    return res.send('Error 400: Post syntax incorrect')

  newServer =
    id: (servers[servers.length - 1]?.id or 0) + 1
    ip: req.body.ip
    port: req.body.port or 54556
    name: req.body.name

  servers.push(newServer)
  res.json({ success: true, id: newServer.id })

app.delete '/server/:id', (req, res) ->
  server = (server for server in servers when server.id is parseInt(req.params.id))
  if server.length is 0
    res.statusCode = 404
    return res.send('Error 404: No server found')

  servers.splice(servers.indexOf(server[0]), 1)
  res.json(true)

app.listen process.env.PORT or 4730, ->
  console.log "Listening on #{process.env.PORT or 4730}"