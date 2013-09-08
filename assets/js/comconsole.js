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
        $('#tableID').text(roomID);
    } else if (info.action == 'startGame') {
        console.log(info.startGame);
        if (info.startGame.response == "Have fun") {
            // startGame();
            $('#startGameWrap').hide();
        } else if (info.startGame.response == "Not enough players") {
            // Update UI to show that there are not enough players
        }
    } else if (info.action == 'playerJoined') {
        // Add player to UI (id, profile_pic, name)
        console.log(info.playerData);
        addPlayer(info.playerData.userID, info.playerData.name, info.playerData.picture);
        players.push(info.playerData);
    } else if (info.action == 'burn') {
        // Burn a card
        burnCard();
        console.log(info.burn);
    } else if (info.action == 'showCard') {
        // Show a card
        card.push(info.card);
        showCard(info.card);
        console.log(info.showCard);
    } else if (info.action == 'hasTurn') {
        $('.hasTurn').removeClass('hasTurn');
        $('#_'+info.userID).addClass('hasTurn');
        // add class hasTurn to current player class info.userID
    } else if (info.action == 'fold') {
        toast(info.name + " folded.");
        $('#_'+info.userID).addClass('hasFolded');
        // fold user
        console.log(info.fold);
    } else if (info.action == 'check') {
        toast(info.name + " checked.");
        console.log(info.check);
    } else if (info.action == 'call') {
        toast(info.name + " called.");
        // update player pot
        updatePlayerPot(info.userID,info.amount);
        console.log(info.call);
    } else if (info.action == 'raise') {
        toast(info.name + " raised " + info.amtRaised);
        // update player pot
        updatePlayerPot(info.userID,info.amount);
        console.log(info.raise);
    }


};
function updatePlayerPot(id,amt){
    var delta;
    delta.onload = function() {
        $('.player#_'+id +'.playerStatus').val("$"+amt);
        updateTotalPot(delta);
    };
    delta = parseFloat(amt) - parseFloat($('.player#_'+id + '.playerStatus .playAmt').val());  
}
function updateTotalPot(delta){
    $('#currTotal').val(parseFloat($('#currTotal').val()) + parseFloat(delta));
}
function addPlayer(id, name, pic){
    $('.playerList').append("<li class='player' id='_"+
        id+
        "'><img class='playerThumb' src='"+ 
        pic+
        "' /><div class='playerName'>"+
        name+
        "</div><div class='playerStatus'>$0</div></li>");
}
sockjs.onclose = function() {
    console.log("socket closed");
};
