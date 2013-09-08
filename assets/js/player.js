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
$('.raise').click(function() {
    sockjs.send(JSON.stringify({'action': 'raise', 'bet': 20}));
});
$('.bet').click(function() {
    sockjs.send(JSON.stringify({'action': 'raise', 'bet': 20}));
});
$('.fold').click(function() {
    sockjs.send(JSON.stringify({'action': 'fold'}));
});
$('.menuOpen').click(function(){
    $('.raiseMenu').show();
});
$('.hideMenu').click(function(){
    $('.raiseMenu').hide();
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
    }else if (info.action == 'checkCall') {
        // Not your turn, or some other error
        toast(info.response);
    } else if (info.action == 'raise') {
        // Not your turn, or some other error
        toast(info.response);
    } else if (info.action == 'fold') {
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
            } else{
                $('.raise').removeClass("hidden");
                $('.call').removeClass("hidden");
            }
        } else {
                $('.playActions div').addClass("hidden");
        }
    } else if (info.action == 'handOver') {
        toast(info.winners[0].name + " won!");
    } else if (info.action == 'clearTable') {
        // clear cards
        card1 = null;
        card2 = null;
    }
};
function clearCards(){
    $('.playActions div').addClass("hidden");
    $('.playCards .playCard').remove();
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
        console.log("FUCK");
        card1Path = "../assets/img/cards/"+card1+".jpg";
        card2Path = "../assets/img/cards/"+card2+".jpg";
        console.log("card1Path: " + card1Path);
        console.log("card2Path: " + card2Path);
        $('.playCards').children().last('.playCard').css({'background': 'url(' + card1Path + ')'});
        $('.playCards').children().first('.playCard').css({'background': 'url(' + card2Path + ')'});
    }).bind('mouseup', function(e){
        console.log("YOU");
        $('.playCards').children().last('.playCard').css({'background': 'url("../assets/img/burncard.jpg")'});
        $('.playCards').children().first('.playCard').css({'background': 'url("../assets/img/burncard.jpg")'});
    });
});

sockjs.onclose = function() {
    console.log("socket closed");
};
