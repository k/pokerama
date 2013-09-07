/*play.js*/
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