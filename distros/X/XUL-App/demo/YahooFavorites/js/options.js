function startup(){

   var showMenuRadioGroup = document.getElementById("showMenuRadioGroup");
   var pref = Components.classes["@mozilla.org/preferences-service;1"]
			.getService(Components.interfaces.nsIPrefBranch);
   try{
       var bool = pref.getBoolPref("webdigest.menu.hidden");
       if(bool){
         document.getElementById("hideMenuRadio").setAttribute("selected", true);
         showMenuRadioGroup.setAttribute("value", "1");
       }
       else{
         document.getElementById("showMenuRadio").setAttribute("selected", true);
         showMenuRadioGroup.setAttribute("value", "0");
       }
   }
   catch(e){
        document.getElementById("showMenuRadio").setAttribute("selected", true);
        showMenuRadioGroup.setAttribute("value", "0");
        pref.setBoolPref("webdigest.menu.hidden", false);
   }
}

function toggleMenuVisibility(){

    var pref = Components.classes["@mozilla.org/preferences-service;1"]
			.getService(Components.interfaces.nsIPrefBranch);
			
    var option = document.getElementById("showMenuRadioGroup").getAttribute("value");
    if(option=="1"){
      pref.setBoolPref("webdigest.menu.hidden", true);

      Components.classes["@mozilla.org/observer-service;1"]
	 .getService(Components.interfaces.nsIObserverService)
   	         .notifyObservers(null, "webdigest:hide-menu", "1");
    }
    else{
      pref.setBoolPref("webdigest.menu.hidden", false);

      Components.classes["@mozilla.org/observer-service;1"]
	 .getService(Components.interfaces.nsIObserverService)
   	         .notifyObservers(null, "webdigest:hide-menu", "0");
    }

    setTimeout("window.close()", 0);
}
