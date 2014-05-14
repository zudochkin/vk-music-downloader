express = require('express')
http = require('http')
path = require('path')
fs = require('fs')
url = require('url')

nconf = require('nconf')
async = require('async')
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
app.set "port", process.env.PORT or 3000
app.set "views", path.join(__dirname, "views")
app.set "view engine", "jade"
app.use express.favicon()
app.use express.logger("dev")
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
app.use express.cookieParser("your secret here")
app.use express.session()
app.use app.router
app.use express.static(path.join(__dirname, "public"))

# development only
app.use express.errorHandler()  if "development" is app.get("env")


downloadFileWget = (audioObj, callback) ->
  fileName = "#{audioObj.aid}.mp3"

  fs.exists "#{DOWNLOAD_DIR}/#{fileName}", (exists) ->
    if exists
      console.log fileName + " already exists"
      callback()
    else
      wget = "wget #{audioObj.url} -O #{DOWNLOAD_DIR}/#{fileName}"

      child = exec(wget, (err, stdout, stderr) ->
        if err
          throw err
        else
          callback()
          console.log fileName + " downloaded to " + DOWNLOAD_DIR
      )


vkontakte = require("vkontakte")

app.get "/download_all", (req, res) ->
  if req.session.accessToken
    vk = vkontakte(req.session.accessToken)

    vk "audio.get", {}, (err, audios) ->
      throw err if err

      q = async.queue (audio, callback) ->
        console.log("start processing audio with AID=#{audio.aid}")
        downloadFileWget audio, callback
      , 5

      q.drain = -> res.end "completed"

      audios.forEach (audio) ->
        q.push audio, (err) -> console.log "#{audio.aid} has been processed"
  else
    res.redirect "/"

app.get "/", (req, res) ->
  if req.session.accessToken
    res.locals.req = req
    vk = vkontakte(req.session.accessToken)
    vk "audio.get", {}, (err, audios) ->
      throw err  if err

      # array of
      #
      #      { aid: 281280726,
      #        owner_id: 4319716,
      #        artist: 'Infected Mushroom Feat Perry Farrell',
      #        title: 'Killing Time (Astrix Remix)',
      #        duration: 410,
      #        url: 'http://cs4960.vk.me/u14444345/audios/6b4233da0ed3.mp3?extra=kwnz0QXNtdp3ZXLsT68Tl6dKMkCeJOnLwElERmT6yHhLpuAVOEkNYASXZXamrbRve8oS5VWlb86emK8RoFvD6bN5GESCrQ',
      #        lyrics_id: '5571287',
      #        genre: 11
      #       }
      #
      res.render "authorized",
        audios: audios

  else
    if req.query.code
      link = "https://oauth.vk.com/access_token?" + "&client_id=" + APP_ID + "&client_secret=" + APP_SECRET + "&redirect_uri=" + REDIRECT_URL + "&code=" + req.query.code
      request = require("request")

      request
        method: "GET"
        uri: link
      , (error, response, body) ->
        throw error  if error
        req.session.accessToken = JSON.parse(body).access_token
        res.redirect "/"

    else
      link = "https://oauth.vk.com/authorize?response_type=code&display=mobile" + "&client_id=" + APP_ID + "&redirect_uri=" + REDIRECT_URL + "&scope=" + "audio"
      res.render "unathorized",
        link_href: link

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
