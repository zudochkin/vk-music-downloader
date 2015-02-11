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
  }
  // Setup the player to autoplay the next track
  if ($('#player').length) {

    var a = audiojs.createAll({
      trackEnded: function() {
        var next = $('ol li.playing').next();
        if (!next.length) next = $('ol li').first();
        next.addClass('playing').siblings().removeClass('playing');
        audio.load($('a', next).attr('data-src'));
        audio.play();
      }
    });

    // Load in the first track
    var audio = a[0];
    first = $('ol a').attr('data-src');
    $('ol li').first().addClass('playing');
    audio.load(first);

    // Load in a track on click
    $('ol li').click(function(e) {
      e.preventDefault();
      $(this).addClass('playing').siblings().removeClass('playing');
      audio.load($('a', this).attr('data-src'));
      audio.play();
    });


    socket.on('my_player_music', function(data) {
      if (data.command) {
        if (data.command == 'next_song') {
          var next = $('li.playing').next();
          if (!next.length) next = $('ol li').first();
          next.click();

        } else if (data.command = 'prev_song') {
          var prev = $('li.playing').prev();
          if (!prev.length) prev = $('ol li').last();
          prev.click();
        }
      }
    });

    // Keyboard shortcuts
    $(document).keydown(function(e) {
      var unicode = e.charCode ? e.charCode : e.keyCode;
      // right arrow
      if (unicode == 39) {
        if (!next.length) next = $('ol li').first();
        next.click();
        // back arrow
      } else if (unicode == 37) {
        if (!prev.length) prev = $('ol li').last();
        prev.click();
        // spacebar
      } else if (unicode == 32) {
        audio.playPause();
      }
    })
  }
});

