var sockjs_url = '/poker';
var sockjs = new SockJS(sockjs_url);
var callAmount = 0;
var minRaise = 0;
var canGo = false;
var position = null;
var card1 = null;
var card2 = null;


sockjs.onopen = function() {
};

sockjs.onmessage = function(e) {
    var info = JSON.parse(e.data);
    if (info.joinRoom) {
        // Add UI (profile_pic, name)
        console.log(info.joinRoom);
    } else if (info.showCard) {
        // show card in UI
        if (card1) {
            card2 = info.card.c;
        } else {
            card1 = info.card.c;
        }
        console.log(showCard);
    }else if (info.checkCall) {
        // Not your turn, or some other error
        console.log(info.checkCall);
    } else if (info.raise) {
        // Not your turn, or some other error
        console.log(info.raise);
    } else if (info.fold) {
        // Not your turn, or some other error
        console.log(info.fold);
    } else if (info.status) {
        callAmount = info.info.callAmount;
        minRaise = info.info.raiseAmount;
        canGo = info.info.canGo;
        if (canGo) {
            // make buttons usable and update
        }
        console.log(info.status);
    } else if (info.handOver) {
        // clear cards
        card1 = null;
        card2 = null;
        console.log(handOver);
    }


};

sockjs.onclose = function() {
    console.log("socket closed");
};
