window.socket = io.connect('http://' + location.host.split(':')[0] + ':3001');

$(function() {
  if ($('#control').length) {

    $('._next-song').click(function() {
      socket.emit('my_player_control', { command: 'next_song' });
      return false;
    });

    $('._prev-song').click(function() {
      socket.emit('my_player_control', { command: 'prev_song' });
      return false;
    });

    $('._play-pause').click(function() {
      socket.emit('my_player_control', { command: 'play_pause' });
      return false;
    });
  }
  // Setup the player to autoplay the next track
  if ($('#player').length) {
    var $musicList = $('#music > a');

    var a = audiojs.createAll({
      trackEnded: function() {
        var next = $('#music > a.active').next();
        if (!next.length) next = $musicList.first();
        next.addClass('active').siblings().removeClass('active');
        audio.load($(next).attr('data-src'));
        audio.play();
      }
    });

    // Load in the first track
    var audio = a[0];
    first = $musicList.attr('data-src');
    $musicList.first().addClass('active');
    audio.load(first);

    // Load in a track on click
    $musicList.click(function(e) {
      e.preventDefault();
      $(this).addClass('active').siblings().removeClass('active');
      audio.load($(this).attr('data-src'));
      audio.play();
    });

    socket.on('my_player_music', function(data) {
      if (data.command) {
        if (data.command == 'next_song') {
          var next = $('#music > a.active').next();
          if (!next.length) next = $musicList.first();
          next.click();
        } else if (data.command == 'prev_song') {
          var prev = $('#music > a.active').prev();
          if (!prev.length) prev = $musicList.last();
          prev.click();
        } else if (data.command == 'play_pause') {
          audio.playPause();
        }
      }
    });

    // Keyboard shortcuts
    $(document).keydown(function(e) {
      var unicode = e.charCode ? e.charCode : e.keyCode;
      // right arrow
      if (unicode == 39) {
        if (!next.length) next = $musicList.first();
        next.click();
        // back arrow
      } else if (unicode == 37) {
        if (!prev.length) prev = $musicList.last();
        prev.click();
        // spacebar
      } else if (unicode == 32) {
        audio.playPause();
      }
    })
  }
});
