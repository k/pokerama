var sockjs_url = '/poker';
var sockjs = new SockJS(sockjs_url);
var callAmount = 0;
var minRaise = 0;
var canGo = false;
var position = null;
var card1 = null;
var card2 = null;

$('.check').click(function() {
    sockjs.send(JSON.stringify({'action': 'checkCall'}));
});
$('.call').click(function() {
    sockjs.send(JSON.stringify({'action': 'checkCall'}));
});
$('.fold').click(function() {
    sockjs.send(JSON.stringify({'action': 'fold'}));
    $('.playActions div').addClass('hidden');
});
$('.menuOpen').click(function(){
    $('.raiseMenu').removeClass("hidden");
});
$('.hideMenu').click(function(){
    $('.raiseMenu').addClass("hidden");
});
sockjs.onopen = function() {
    console.log(roomID);
    sockjs.send(JSON.stringify({'action': 'joinRoom', 'room': roomID, 'userID': userID}));
};

sockjs.onmessage = function(e) {
    var info = JSON.parse(e.data);
    if (info.action == 'joinRoom') {
        // Add UI (profile_pic, name)
    } else if (info.action == 'showCard') {
        // show card in UI
        if (card1!==null) {
            card2 = info.card;
            dealCard(card2);
        } else {
            card1 = info.card;
            dealCard(card1);
        }
    } else if (info.action == 'checkCallError') {
        // Not your turn, or some other error
        toast(info.response);
    } else if (info.action == 'raiseError') {
        // Not your turn, or some other error
        toast(info.response);
    } else if (info.action == 'foldError') {
        // Not your turn, or some other error
        toast(info.response);
    } else if (info.action == 'status') {
        callAmount = info.info.callAmount;
        minRaise = info.info.raiseAmount;
        canGo = info.info.canGo;
        if (canGo) {
            $('.fold').removeClass("hidden");
            $('.options').removeClass("hidden");
            if(callAmount === 0){
                $('.check').removeClass("hidden");
                $('.bet').removeClass("hidden");
                window.ondevicemotion = function(event) {
                    var z = event.acceleration.z;
                    console.log(z*z);
                    if (z*z > 10) {
                        sockjs.send(JSON.stringify({'action': 'checkCall'}));
                        window.ondevicemotion = null;
                    }
                };
            } else{
                $('.raise').removeClass("hidden");
                $('.call').removeClass("hidden");
            }
            updateRaises(minRaise);
        } else {
                $('.playActions div').addClass("hidden");
                $('.raiseMenu').addClass("hidden");
        }
    } else if (info.action == 'handOver') {
        window.ondevicemotion = null;
        toast(info.winners[0].name + " won!");
    } else if (info.action == 'hasTurn') {
        $('.currentTurn').text(info.name + "'s turn.");
    } else if (info.action == 'clearTable') {
        // clear cards
        card1 = null;
        card2 = null;
        clearCards();
    } else if (info.action == 'check') {
        toast(info.name + ' checked.');
    } else if (info.action == 'call') {
        toast(info.name + ' called.');
    } else if (info.action == 'raise') {
        toast(info.name + ' raised $' + info.amount + '.');
    } else if (info.action == 'fold') {
        toast(info.name + ' folded.');
    }
};

function updateRaises(minRaise){
   $('li.little').text(minRaise);
   $('li.big').text(parseFloat(minRaise)*2);
}
$('li.standard').click(function(){
    var raiseAmt = parseFloat($(this).text());
    sockjs.send(JSON.stringify({'action': 'raise', 'amount': raiseAmt}));
});
$('li.custom .submitCustom').click(function(){
    var raiseAmt = parseFloat($('#customRaise').val());
    sockjs.send(JSON.stringify({'action': 'raise', 'amount': raiseAmt}));
});
function clearCards(){
    $('.playActions div').addClass("hidden");
    $('.playCards .playCard').remove();
    toast("Waiting for round to begin");
}
function toast(msg){
    $('.lastAction').text(msg);
}
function dealCard(card){
    var newCard;
    //wait 200ms before creating DOM object for appearance of linearity
    setTimeout(function(){
        $('.playCards').append("<div class='playCard' id='"+card+"'></div>");
    },200);
    //wait for newCard DOM object to load before sliding it in, like a bawss
    newCard = $('.playCards').children().last('.playCard');    
    slideCard(newCard);
}
function slideCard(newCard){
    $(newCard).fadeIn('fast');
    $(newCard).css({'background': 'url("../assets/img/burncard.jpg")','display': 'inline-block'});
}
$(document).ready(function(){
    $(".playCards").bind('mousedown', function(e){
        card1Path = "../assets/img/cards/"+card1+".jpg";
        card2Path = "../assets/img/cards/"+card2+".jpg";
        console.log("card1Path: " + card1Path);
        console.log("card2Path: " + card2Path);
        $('.playCards').children().last('.playCard').css({'background': 'url(' + card1Path + ')'});
        $('.playCards').children().first('.playCard').css({'background': 'url(' + card2Path + ')'});
    }).bind('mouseup', function(e){
        $('.playCards').children().last('.playCard').css({'background': 'url("../assets/img/burncard.jpg")'});
        $('.playCards').children().first('.playCard').css({'background': 'url("../assets/img/burncard.jpg")'});
    });
    $(".playCards").bind('touchstart', function(e){
        card1Path = "../assets/img/cards/"+card1+".jpg";
        card2Path = "../assets/img/cards/"+card2+".jpg";
        console.log("card1Path: " + card1Path);
        console.log("card2Path: " + card2Path);
        $('.playCards').children().last('.playCard').css({'background': 'url(' + card1Path + ')'});
        $('.playCards').children().first('.playCard').css({'background': 'url(' + card2Path + ')'});
    }).bind('touchend', function(e){
        $('.playCards').children().last('.playCard').css({'background': 'url("../assets/img/burncard.jpg")'});
        $('.playCards').children().first('.playCard').css({'background': 'url("../assets/img/burncard.jpg")'});
    });
});

sockjs.onclose = function() {
    sockjs.send(JSON.stringify({'action': 'fold'}));
    console.log("socket closed");
};
