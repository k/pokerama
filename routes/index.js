var request = require('request');

var CLIENT_ID = 1350;
var CLIENT_SECRET = "9hYxvrdWxWqb3BuFSmpa2bYSEPFscyfW";

exports.index = function(req, res) {
	res.render('index', {title: 'Start or Join a Pokerama game'});
};
exports.comconsole = function(req, res) {
	res.render('comconsole', {title: 'Start the Pokerama game'});
};
exports.player = function(req, res) {
	res.send("player");
};

exports.playerControl = function(req, res) {
    res.send("UISHIZNAZYSHIT");
};
exports.choosetable = function(req, res) {
    var data = {
        "client_id" :CLIENT_ID,
        "client_secret" : CLIENT_SECRET,
        "code" : res.req.query.code
    };
    request.post('https://api.venmo.com/oauth/access_token', {form:data}, function(e, r, body) {
        var info = JSON.parse(body);
        if (info.error) {
            res.send(e);
            return;
        }
        console.log(body.name);
        // res.send('Access Token:' + info.access_token + '\n' + info.user.name);
        res.render('choosetable', {title: 'Enter your table ID', userID: info.user.id});
    });

};
