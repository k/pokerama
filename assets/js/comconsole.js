var sockjs_url = '/poker';
var sockjs = new SockJS(sockjs_url);
var roomID = -1;
var players = [];
var cards = [];

$('.startGame').click(function () {
    if (roomID > 0) {
        sockjs.send(JSON.stringify({action: 'startGame'}));
    }
});

sockjs.onopen = function() {
    sockjs.send(JSON.stringify({action: 'createRoom'}));
};
sockjs.onmessage = function(e) {
    var info = JSON.parse(e.data);
    if (info.roomID > 0) {
        roomID = info.roomID;
    } else if (info.startGame) {
        console.log(info.startGame);
        if (info.startGame.response == "Have fun") {
            // startGame();
        } else if (info.startGame.response == "Not enough players") {
            // Update UI to show that there are not enough players
        }
    } else if (info.playerJoined) {
        // Add player to UI (id, profile_pic, name)
        players.append(info.playerData);
        console.log(info.playerJoined);
    } else if (info.burn) {
        // Burn a card
        console.log(info.burn);
    } else if (info.showCard) {
        // Show a card
        card.append(info.card);
        console.log(info.showCard);
    } else if (info.status) {
        // update text with fold/check/call/raise/bet
    }


};

sockjs.onclose = function() {
    console.log("socket closed");
};
