exports.index = function(req, res) {
	res.render('index', {title: 'Start or Join a Pokerama game'});
}
exports.comconsole = function(req, res) {
	res.render('comconsole', {title: 'Start the Pokerama game'});
}