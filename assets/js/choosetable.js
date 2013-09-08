$('.submitTable').click(sendForm); 

function sendForm() {
    var tableID = $('#tableID').val();
    var formData = new FormData();
    formData.append('userid', '0');
    formData.append('roomID', tableID);
    if (tableID) {
        window.location = '/player' + '?userID=' + userID + '&roomID=' + tableID;
    }
}
