# VK.com simple music downloader

To download the whole music from your VK.com audio collection, you should do those simple steps:

* `cp config/credentials.example.json config/credentials.json`
* change APP_ID and APP_SECRET with your own credentials [Applications list](http://vk.com/apps?act=settings)
* install dependencies `npm install`
* start application by running `npm start`
* follow the link [http://localhost:3000](http://localhost:3000)
* click **Sign in** link and allow access to your music collection
* If everything is alright, you should see **Download all** link
* By clicking it you'll start downloading process
* Then go get a beer so you can relax while your music is downloading

![Downloading process screenshot](https://raw.githubusercontent.com/vredniy/vk-music-downloader/master/screenshots/screenshot.png)

#### Extra Bonus

Stom downloader server and run another one from **_webserver** folder with command `node bin/www`.

Symlink music folder to public (folders not yet supported) and that's it.

Webserver with js player. You will be able to play next or previous song over local network or internet. On computer with powerful acoustic you should open browser
on http://localhost:3000/music page. For remote control follow the  http://localhost:3000/music page and you'll see two links: one for next and one for prev
song playback control.

![Webserver for music playback control](https://raw.githubusercontent.com/vredniy/vk-music-downloader/master/screenshots/screenshot_webserver.png)
