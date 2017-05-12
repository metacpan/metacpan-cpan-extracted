var div = document.getElementById('message');

function update_buttons() {
  var clickers = YAHOO.util.Dom.getElementsByClassName('clicker');
  for(var i=0; i < clickers.length; i++) {
    x10remote(clickers[i].id, 'status');
  }
}

function toggle(device) {
  var button = document.getElementById(device);
  var newstatus = (button.value == "on") ? "off" : "on";
  x10remote(device, newstatus);
  update_button(device, ""); // Button blank
}

function update_button(button_name, show) {
    var color = "";
    var button = document.getElementById(button_name);

    if(show == "on") {
        color = "green"; button.value = show;
    } else if(show == "") {
        color = "white";
    } else {
        color = "red"; button.value = show;
    }
          
    YAHOO.util.Dom.setStyle(button_name, 'backgroundColor', color);
}

var handleSuccess = function(o){
    div.innerHTML = ""; // Clear status line

    if(o.argument.cmd == 'status') {
          // chop newline
        o.responseText = o.responseText.substring(0, 
                           o.responseText.length-1);
        update_button(o.argument.device, o.responseText);
    } else {
        update_button(o.argument.device, o.argument.cmd);
    }
}

var handleFailure = function(o){
    div.innerHTML = "Error: " + o.status + " " + o.statusText;
}

function x10remote(device, action) {
    var callback = {
      success:  handleSuccess, 
      failure:  handleFailure, 
      argument: { }
    };

    var url = "/cgi/x10.cgi?action=" + 
               action + "&device=" + device;
    callback.argument.device = device;
    callback.argument.cmd    = action;
    YAHOO.util.Connect.asyncRequest('GET', url, callback); 
    div.innerHTML = "Request: " + device + " " + action;
}
