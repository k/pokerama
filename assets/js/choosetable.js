$('.submitTable').click(sendForm); 

function sendForm() {
    var tableID = $('#tableID').text;
    var formData = new FormData();
    formData.append('userid', '0');
    formData.append('roomID', tableID);

    console.log("FUCK");

    var xhr =  new XMLHttpRequest();
    xhr.open('POST', '/player', true);
    xhr.send(formData);

    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4 && xhr.status == 200) {
            window.location = '/player' + '?userid=' + userID;
        }
    };
}
