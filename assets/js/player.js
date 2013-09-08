// (function($) {
//     $.QueryString = (function(a) {
//         if (a == "") return {};
//         var b = {};
//         for (var i = 0; i < a.length; ++i)
//         {
//             var p=a[i].split('=');
//             if (p.length != 2) continue;
//             b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
//         }
//         return b;
//     })(window.location.search.substr(1).split('&'));
// })(jQuery);
var sockjs_url = '/poker';
var sockjs = new SockJS(sockjs_url);
var callAmount = 0;
var minRaise = 0;
var canGo = false;
var position = null;
var card1 = null;
var card2 = null;

sockjs.onopen = function() {
    console.log(roomID);
    sockjs.send(JSON.stringify({'action': 'joinRoom', 'room': roomID, 'userID': userID}));
};

sockjs.onmessage = function(e) {
    var info = JSON.parse(e.data);
    if (info.action == 'joinRoom') {
        // Add UI (profile_pic, name)
        console.log(info.roomID);
    } else if (info.action == 'showCard') {
        // show card in UI
        if (card1!==null) {
            card2 = info.card.c;
            dealCard(card2);
        } else {
            card1 = info.card.c;
            dealCard(card1);
        }
        console.log(showCard);
    }else if (info.action == 'checkCall') {
        // Not your turn, or some other error
        toast(info.response);
        console.log(info.checkCall);
    } else if (info.action == 'raise') {
        // Not your turn, or some other error
        toast(info.response);
        console.log(info.raise);
    } else if (info.action == 'fold') {
        // Not your turn, or some other error
        toast(info.response);
        console.log(info.fold);
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
        console.log(info.status);
    } else if (info.action == 'handOver') {
        // clear cards
        card1 = null;
        card2 = null;
        console.log(handOver);
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
        $('.playCards').append("<div class='playCard' style='display:none;' id='"+card+"'></div>");
    },200);
    //wait for newCard DOM object to load before sliding it in, like a bawss
    newCard.onload = function(){
        slideCard(newCard);
    };
    newCard = $('.playCards').children().last('.playCard');    
}
function slideCard(newCard){
    $(newCard).fadeIn('fast');
    $(newCard).css({background: url("assets/img/burncard.jpg")});
}
$(document).ready(function(){
    var firstCard = $('.playCards').children().first('.playCard');
    var secondCard = $('.playCards').children().last('.playCard');
    var firstCardVal = $('.playCards').children().first('.playCard').attr('id');
    var secondCardVal = $('.playCards').children().last('.playCard').attr('id');
    var firstCardLoc = $('#firstCardImg').attr("src");
    var secondCardLoc = $('#secondCardImg').attr("src");
    $(".playCards").bind('mousedown', function(){
        firstCard.css({background: "url('"+firstCardLoc+"')"});
        secondCard.css({background: "url('"+secondCardLoc+"')"});
    }).bind('mouseup', function(){
        firstCard.css({background: "url('assets/img/burncard.jpg')"});
        secondCard.css({background: "url('assets/img/burncard.jpg')"});
    });
});

sockjs.onclose = function() {
    console.log("socket closed");
};
