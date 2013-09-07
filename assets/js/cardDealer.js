/*cardDealer.js*/
function burnCard(){
	//check if a card has been burned yet
	if($('.burnCard').length == 0){
		var newBurn = $('.burnPile').append("<div class='burnCard'></div>");
		newBurn.find($('.burnCard')).css({left: 0, top: 10, display:"none"});
		newBurn.find($('.burnCard')).fadeIn('fast');
	} // if there was, just set it a bit further down
	else{
		var lastLeft = $('.burnCard').last().css("left");
		var lastLeftVal = lastLeft.split('p',2);
		var lastTop = $('.burnCard').last().css("top");
		var lastTopVal = lastTop.split('p',2);
		var oldBurn = $('.burnPile').children().last('.burnCard');
		$('.burnPile').append("<div class='burnCard'></div>");
		var newBurn = $('.burnPile').children().last('.burnCard');
		var newLeftVal = parseInt(lastLeftVal[0]) + 10;
		var newTopVal = parseInt(lastTopVal[0]) + 2;
		newBurn.css({left: newLeftVal + "px", top: newTopVal + "px", display: "none"});
		newBurn.fadeIn('fast');
	}
}
$('.burnButton').click(burnCard);
$(function(){
	$('.showButton').click(function(){
		showCard("As");
	});
})
function showCard(card){
	console.log(card);
	$('.showCards').append("<div class='showCard' id="+card+"><img src='assets/img/cards/"+card+".jpg' width='150' height='218'/></div>");
}