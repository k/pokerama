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

// $('.nextHand').click(function () { });

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
        // addPlayer(info.playerData.userID, info.playerData.picture);
        players.append(info.playerData);
        console.log(info.playerJoined);
    } else if (info.burn) {
        // Burn a card
        burnCard();
        console.log(info.burn);
    } else if (info.showCard) {
        // Show a card
        card.append(info.card);
        showCard(info.card);
        console.log(info.showCard);
    } else if (info.hasTurn) {
        $('.hasTurn').removeClass();
        // add class hasTurn to current player class info.userID
    } else if (info.fold) {
        toast(info.name + " folded.");
        // fold user
        console.log(info.fold);
    } else if (info.check) {
        toast(info.name + " checked.");
        console.log(info.check);
    } else if (info.call) {
        toast(info.name + " called.");
        // update player pot
        console.log(info.call);
    } else if (info.raise) {
        toast(info.name + " raised " + info.amtRaised);
        // update player pot
        console.log(info.raise);
    }


};

sockjs.onclose = function() {
    console.log("socket closed");
};
