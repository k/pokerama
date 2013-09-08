var request = require('request');

var CLIENT_ID = 1350;
var CLIENT_SECRET = "9hYxvrdWxWqb3BuFSmpa2bYSEPFscyfW";

exports.temp = {};

exports.index = function(req, res) {
	res.render('index', {title: 'Start or Join a Pokerama game'});
};
exports.comconsole = function(req, res) {
	res.render('comconsole', {title: 'Start the Pokerama game'});
};
exports.player = function(req, res) {
    var userID = req.query.userID;
    var roomID = req.query.roomID;
    console.log(userID);
    console.log(roomID);
    // put these two vars in the 'render' call to send to the client
	res.render("player", {title: 'Player', 'userid': userID, 'room': roomID});
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
        console.log(info);
        exports.temp[''+info.user.id] = info;
        res.render('choosetable', {title: 'Enter your table ID', userID: info.user.id});
    });

};
