nconf = require 'nconf'
async = require 'async'
exec = require('child_process').exec
sanitizeFilename = require 'sanitize-filename'
vkontakte = require 'vkontakte'
fs = require 'fs'

ProgressBar = require 'progress'

nconf.argv()
  .env()
  .file({ file: './config/credentials.json' })

unless nconf.get('access_token')
  console.error 'You dont have access token; Run npm start first'
  exit(1)

APP_ID = nconf.get('vk_app_id')
APP_SECRET = nconf.get('vk_app_secret')
DOWNLOAD_DIR = './music'


execCurl = (audioObj, fileName, callback) ->
  command = "curl #{audioObj.url} -o \"#{DOWNLOAD_DIR}/#{fileName}\""

  exec(command, (err, stdout, stderr) ->
    throw err if err
    callback()
  )


downloadFileCurl = (audioObj, callback) ->
  fileName = sanitizeFilename "#{audioObj.artist} - #{audioObj.title}.mp3"

  fs.exists "#{DOWNLOAD_DIR}/#{fileName}", (exists) ->
    if exists
      command = "curl -sI #{audioObj.url} | grep Content-Length | awk '{print $2}'"

      exec(command, (err, stdout, stderr) ->
        size = fs.statSync("#{DOWNLOAD_DIR}/#{fileName}")['size']

        if parseInt(stdout) == size
          callback()
        else
          execCurl audioObj, fileName, callback
      )
    else
      execCurl audioObj, fileName, callback

vk = vkontakte nconf.get('access_token')

vk 'audio.get', {}, (err, audios) ->
  throw err if err

  q = async.queue (audio, callback) ->
    downloadFileCurl audio, callback
  , 4

  q.drain = -> console.log 'completed'

  bar = new ProgressBar('  downloading [:bar] :percent :etas (:current/:total)', total: audios.length)

  audios.forEach (audio) ->
    q.push audio, (err) ->
      bar.tick()
