var express = require('express');
var router = express.Router();

var fs = require('fs');

/* GET users listing. */
router.get('/', function(req, res, next) {
  

  fs.readdir('./public/music', function(err, files) {
    if (err) throw err;

    res.render('music', { files: files.filter(function(file) { return file.substr(-4) === '.mp3'; }) });
  });
});

module.exports = router;
