express = require 'express'
http = require 'http'
path = require 'path'
fs = require 'fs'
url = require 'url'

nconf = require 'nconf'
async = require 'async'
exec = require('child_process').exec

app = express()

nconf.argv()
  .env()
  .file({ file: './config/credentials.json' })

APP_ID = nconf.get('vk_app_id')
APP_SECRET = nconf.get('vk_app_secret')
DOWNLOAD_DIR = './music'

REDIRECT_URL = "http://localhost:#{process.env.PORT or 3000}"

# all environments
app.set 'port', process.env.PORT or 3000
app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'jade'
app.use express.favicon()
app.use express.logger('dev')
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
app.use express.cookieParser('mnas2doiYHcx4vlkweD7SAiooiDSO9')
app.use express.session()
app.use app.router
app.use express.static(path.join(__dirname, 'public'))

# development only
app.use express.errorHandler()  if 'development' is app.get('env')


sanitizeFilename = require 'sanitize-filename'

downloadFileWget = (audioObj, callback) ->
  fileName = sanitizeFilename "#{audioObj.artist} - #{audioObj.title}.mp3"

  fs.exists "#{DOWNLOAD_DIR}/#{fileName}", (exists) ->
    if exists
      console.log "#{fileName} already exists"
      callback()
    else
      wget = "wget #{audioObj.url} -O \"#{DOWNLOAD_DIR}/#{fileName}\""

      child = exec(wget, (err, stdout, stderr) ->
        if err
          throw err
        else
          callback()
          console.log "#{fileName} downloaded to #{DOWNLOAD_DIR}"
      )


vkontakte = require 'vkontakte'

app.get '/download_all', (req, res) ->
  if req.session.accessToken
    vk = vkontakte(req.session.accessToken)

    vk 'audio.get', {}, (err, audios) ->
      throw err if err

      q = async.queue (audio, callback) ->
        console.log "start processing audio '#{audio.artist} - #{audio.title}'"
        downloadFileWget audio, callback
      , 5

      q.drain = -> res.end 'completed'

      audios.forEach (audio) ->
        q.push audio, (err) -> console.log "#{audio.artist} - #{audio.title} has been processed"
  else
    res.redirect '/'

app.get '/', (req, res) ->
  if req.session.accessToken
    nconf.set('access_token', req.session.accessToken)

    nconf.save (err) -> throw err if err

    res.locals.req = req

    vk = vkontakte(req.session.accessToken)
  
    vk 'audio.getAlbums', {}, (err, albums) ->
        throw err  if err
        vk 'audio.get', {}, (err, audios) ->
          throw err  if err 
          
          res.render 'authorized',
            albums: albums, audios: audios   

  else
    if req.query.code
      link = "https://oauth.vk.com/access_token?&client_id=#{APP_ID}&client_secret=#{APP_SECRET}&redirect_uri=#{REDIRECT_URL}&code=#{req.query.code}"
      request = require 'request'

      request
        method: 'GET'
        uri: link
      , (error, response, body) ->
        throw error  if error
        req.session.accessToken = JSON.parse(body).access_token
        res.redirect '/'

    else
      link = "https://oauth.vk.com/authorize?response_type=code&display=mobile&client_id=#{APP_ID}&redirect_uri=#{REDIRECT_URL}&scope=audio,offline"
      res.render 'unathorized',
        link_href: link

http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port #{app.get 'port'}"
