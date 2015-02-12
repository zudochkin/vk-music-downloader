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


# TODO: replace with CURL with automatically resume transfer
downloadFileWget = (audioObj, callback) ->
  fileName = sanitizeFilename "#{audioObj.artist} - #{audioObj.title}.mp3"

  fs.exists "#{DOWNLOAD_DIR}/#{fileName}", (exists) ->
    if exists
      # console.log "#{fileName} already exists"
      callback()
    else
      wget = "wget #{audioObj.url} -O \"#{DOWNLOAD_DIR}/#{fileName}\""

      child = exec(wget, (err, stdout, stderr) ->
        if err
          throw err
        else
          callback()
          # console.log "#{fileName} downloaded to #{DOWNLOAD_DIR}"
      )

vk = vkontakte nconf.get('access_token')

vk 'audio.get', {}, (err, audios) ->
  throw err if err

  q = async.queue (audio, callback) ->
    # console.log "start processing audio '#{audio.artist} - #{audio.title}'"
    downloadFileWget audio, callback
  , 2

  q.drain = -> console.log 'completed'

  bar = new ProgressBar('  downloading [:bar] :percent :etas (:current/:total)', total: audios.length)

  audios.forEach (audio) ->
    q.push audio, (err) ->
      bar.tick()
      # console.log "#{audio.artist} - #{audio.title} has been processed"

