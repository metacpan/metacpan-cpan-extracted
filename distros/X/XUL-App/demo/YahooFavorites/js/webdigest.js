var webdigestMain = {

   user : null,

   showTmpEngine : false,

   init : function(){

     //register progess listener for login status checking
     registerWebdigestProgressListener();

     //add extra elements to context menu
     webdigestContextMenu.register();

     //apply different style sheet to different platform
     var platform = webdigestMain.getPlatform();
     var docStyleSheets =  document.styleSheets;
     if(platform=="mac"){

        for(var i=0; i<docStyleSheets.length; ++i){

           if(docStyleSheets[i].href=="webdigest.css")
              docStyleSheets[i].disabled = true;
           else if(docStyleSheets[i].href=="webdigest_mac.css")
              docStyleSheets[i].disabled = false;
        }
     }
     else{
        for(var i=0; i<docStyleSheets.length; ++i){

           if(docStyleSheets[i].href=="webdigest_mac.css")
              docStyleSheets[i].disabled = true;
	   else if(docStyleSheets[i].href=="webdigest.css")
              docStyleSheets[i].disabled = false;
        }
     }


     //has the user hidden our menu?
     if(webdigestMain.isMenuHidden()){
          var menu = document.getElementById("webdigest-menu");
          menu.setAttribute("hidden", true);
     }

     //mac would always say engine is not installed
     //as we do not have permission to modify webdigest.js
     //暂不支持搜索
     if(!webdigestMain.isEngineInstalled()){
     	//webdigestMain.installEngine();
     }
     else if(webdigestMain.shouldShowTmpEngine()){
        //webdigestMain.addTmpEngine();
     }

     //add observer
     var os = Components.classes["@mozilla.org/observer-service;1"]
                                     .getService(Components.interfaces.nsIObserverService);
     os.addObserver(webdigestObserver, "webdigest:update-login-status", false);
     os.addObserver(webdigestObserver, "webdigest:hide-menu", false);

     //check for the first time start
     webdigestMain.firstTimeStart();
     setTimeout("webdigestMain.delayInit()", 250);
   },

   delayInit : function(){

     //set login status
     var user = webdigestMain.getUser();
     if(user)
       webdigestMain.storeUser(user);
     else
       webdigestMain.storeUser();

     //update the toolbar buttons
     webdigestMain.updateToolbarButtons();
   },

   uninit : function(){

     unregisterWebdigestProgressListener();

     webdigestContextMenu.unregister();

     var os = Components.classes["@mozilla.org/observer-service;1"]
                                     .getService(Components.interfaces.nsIObserverService);
     os.removeObserver(webdigestObserver, "webdigest:update-login-status");
     os.removeObserver(webdigestObserver, "webdigest:hide-menu");
   },

   isMenuHidden : function(){

     var pref = Components.classes["@mozilla.org/preferences-service;1"]
			.getService(Components.interfaces.nsIPrefBranch);
     try{
       var bool = pref.getBoolPref("webdigest.menu.hidden");
       if(bool)
	 return true;
     }
     catch(e){
        pref.setBoolPref("webdigest.menu.hidden", false);
     }

   return false;
   },

   setMenuHiddenInPref : function(){

     var pref = Components.classes["@mozilla.org/preferences-service;1"]
			.getService(Components.interfaces.nsIPrefBranch);
     pref.setBoolPref("webdigest.menu.hidden", true);
   },

   isEngineInstalled : function(){

     try{
       var pref = Components.classes["@mozilla.org/preferences-service;1"]
			.getService(Components.interfaces.nsIPrefBranch);
       var bool = pref.getBoolPref("webdigest.engine.installed");
       if(bool){
	  return true;
       }
     }
     catch(e){}

   return false;
   },

   installEngine : function(){

      var dirService = Components.classes['@mozilla.org/file/directory_service;1']
      			.getService(Components.interfaces.nsIProperties);		
      var srcfile = dirService.get("SrchPlugns", Components.interfaces.nsILocalFile);	
      srcfile.append("webdigest.src");

      var prosrcfile = dirService.get("ProfD", Components.interfaces.nsILocalFile);	
      prosrcfile.append("searchplugins");
      prosrcfile.append("webdigest.src");

      //extract src and graphic if necessary
      if(!srcfile.exists() && !prosrcfile.exists()){

         var jarfile = dirService.get("ProfD", Components.interfaces.nsILocalFile);	
         jarfile.append("extensions");
         jarfile.append("{17cc9b7a-e4c0-11da-974c-0050baed0569}");
         jarfile.append("chrome"); jarfile.append("myweb.cn.yahoo.com.jar");

         var zipReader = Components.classes["@mozilla.org/libjar/zip-reader;1"]
	                    .createInstance(Components.interfaces.nsIZipReader);
         zipReader.init(jarfile);
         zipReader.open();
	
         var entries = zipReader.findEntries("*.src");
         if(entries){
  	
  	    var nsIZipEntry = Components.interfaces.nsIZipEntry;
	    while(entries.hasMoreElements()) {
		
		var entry = entries.getNext().QueryInterface(nsIZipEntry);
		//remove searchplugins and path separator		
		var filename = entry.name.substring(14);

		var target = dirService.get("SrchPlugns", Components.interfaces.nsILocalFile);	
		target.append(filename);

		if(!target.exists()){
		
		    try{
		  	target.create( Components.interfaces.nsIFile.NORMAL_FILE_TYPE, 0664);
		    	if(target.exists() && target.isFile())	
				zipReader.extract(entry.name, target);
		    }
		    catch(e){}
		}
		
		var oEntry = zipReader.getEntry(entry.name.replace(".src",".gif"));
		if(oEntry != null){
		
		   filename = oEntry.name.substring(14);
	    	   target = target.parent;
	 	   target.append(filename);
		    	
	   	   if(!target.exists()){
	   	
	   	       try{
	 	          target.create( Components.interfaces.nsIFile.NORMAL_FILE_TYPE, 0664);
		          if(target.exists() && target.isFile())	
			      zipReader.extract(oEntry.name, target);
		       }
		       catch(e){}
		   }
		}
      	     }
	 }
	
	 zipReader.close();

        //need this function to show the engine after restarting the browser for the first time
        setTimeout("webdigestMain.addTmpEngine()", 500);
      }	

      this.setEngineInList();
      this.overwriteOwnDefaultPref("webdigest.engine.installed", "pref(\"webdigest.engine.installed\",true);");
   },

   setEngineInList : function(){

     try{
      var pref = Components.classes["@mozilla.org/preferences-service;1"]
   			.getService(Components.interfaces.nsIPrefBranch);
     /*
      pref.setCharPref("browser.search.order.3",
                            "Yahoo");
      pref.setCharPref("browser.search.order.1",
                                "webdigest");
    */
     }
     catch(e){}
   },

   shouldShowTmpEngine : function(){

       var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"]
                      .getService(Components.interfaces.nsIWindowMediator);
       var enumerator = wm.getEnumerator("navigator:browser");
       while(enumerator.hasMoreElements()) {
          var win = enumerator.getNext();
          if(win != window){
             if(win.webdigestMain){
                return win.webdigestMain.showTmpEngine;
             }
          }
       }

   return false;
   },

   //restart after installing the extension, the webdigest engine does not appear, this is a function to fix it
   addTmpEngine : function(){

        var rdfService = Components.classes["@mozilla.org/rdf/rdf-service;1"]
                                 .getService(Components.interfaces.nsIRDFService);

        const kNC_Name= rdfService.GetResource("http://home.netscape.com/NC-rdf#Name");
        const kNC_Icon= rdfService.GetResource("http://home.netscape.com/NC-rdf#Icon");
        var dirService = Components.classes['@mozilla.org/file/directory_service;1']
              	  	  	.getService(Components.interfaces.nsIProperties);		
        var handler = Components.classes["@mozilla.org/network/protocol;1?name=file"].
       	               createInstance(Components.interfaces.nsIFileProtocolHandler);
        var searchbar = document.getElementById("searchbar");       	
        var menupopup = document.getAnonymousElementByAttribute (searchbar, 'anonid', 'searchbar-popup');
        var ds = Components.classes["@mozilla.org/rdf/rdf-service;1"]
                                 .getService(Components.interfaces.nsIRDFService).GetDataSource("rdf:internetsearch");
     	if(!menupopup) return;

    	// See mozilla/xpcom/io/nsAppDirectoryServiceDefs.h for param[0]
	var srcfile = dirService.get("SrchPlugns", Components.interfaces.nsILocalFile);	
     	srcfile.append("webdigest.src");
     	     	
     	if(srcfile.exists()){

     	   var grpfile = dirService.get("SrchPlugns", Components.interfaces.nsILocalFile);	
           grpfile.append("webdigest.gif");
   	
   	   var id = "engine://"+encodeURIComponent(srcfile.path);
      	   var menuitem = document.createElement("menuitem");   		
     	   menuitem.setAttribute("type", "checkbox");
     	   menuitem.setAttribute("id", id);
     	   menuitem.setAttribute("value", id);
     	   if(grpfile.exists())
     	     	menuitem.setAttribute("src", handler.getURLSpecFromFile(grpfile));
     	   else
     	        menuitem.setAttribute("src", "");
     	   menuitem.setAttribute("label", "webdigest");
   	   if(!document.getElementById(id)){
     	     	
     	     var child = menupopup.childNodes;
     	     if(child.length>0)
     		menupopup.insertBefore(menuitem, menupopup.firstChild);
     	     else
     		menupopup.appendChild(menuitem);
     	
     	     //in order to fix the icons does not display on the rdf:
     	     var rEngine = rdfService.GetResource(id);	
     	     ds.Assert(rEngine, kNC_Name, rdfService.GetLiteral("webdigest"),true);
     	     if(grpfile.exists())
     	        ds.Assert(rEngine, kNC_Icon, rdfService.GetLiteral(handler.getURLSpecFromFile(grpfile)) ,true);
     	     else
     	        ds.Assert(rEngine, kNC_Icon, rdfService.GetLiteral("") ,true);
     	   }
     	   this.showTmpEngine = true;
     	}
   },

   overwriteOwnDefaultPref : function(aPrefName, aNewPrefStr){
   	
      //this does not save the bool pref into the extension 1.0.X
      //so we need to open the file and rewrite it.
      //the webdigest.js on Mac has read-only permission so we cannot rewrite it
      var dirService = Components.classes['@mozilla.org/file/directory_service;1']
      			.getService(Components.interfaces.nsIProperties);		
      var file = dirService.get("ProfD", Components.interfaces.nsILocalFile);	
      file.append("extensions");
      file.append("{17cc9b7a-e4c0-11da-974c-0050baed0569}");
      file.append("defaults");
      file.append("preferences");
      file.append("webdigest.js");
	
      var prefName = aPrefName;
      var prefStr = aNewPrefStr;
      var oString = "";
      if (file.exists()){
	
 	    var is = Components.classes["@mozilla.org/network/file-input-stream;1"]
                        .createInstance(Components.interfaces.nsIFileInputStream);
	    is.init(file, 0x01, 0444, 0);
            is.QueryInterface(Components.interfaces.nsILineInputStream);
	
	    var line = {};
            var lines = [], hasmore;
            do {
	        hasmore = is.readLine(line);
	        lines.push(line.value);
	    } while(hasmore);
	
            var replaced = false;
            for(var i=0; i<lines.length; i++){

		if(lines[i].indexOf(prefName)>-1){
		   oString += prefStr+"\r\n";
		   replaced = true;
		}
		else
		   oString += lines[i]+"\r\n";
            }

            is.close();
      }
	      	
      if(oString.length ==0 || !replaced)
        oString += prefStr+"\r\n";

      try{
        var os = Components.classes["@mozilla.org/network/file-output-stream;1"]
		.createInstance( Components.interfaces.nsIFileOutputStream);
        os.init(file, 0x04 | 0x08 | 0x20, 0664, 0);
        os.write(oString, oString.length);
        os.close();
      }
      catch(e){
        //should not have this error except for mac
      }

      try{
        var prefInt = Components.classes["@mozilla.org/preferences;1"]
    			.getService(Components.interfaces.nsIPref);
        prefInt.SetDefaultBoolPref(aPrefName, true);
      }
      catch(e){}
   },

   firstTimeStart : function(){

     var bundle = document.getElementById("bundle_webdigest");
     var pref = Components.classes["@mozilla.org/preferences-service;1"]
     	 			.getService(Components.interfaces.nsIPrefBranch);
     var currentVersionNum  = bundle.getString("wd_versionNum");
     var addButtons = false;
     try{
     	var num = pref.getCharPref("webdigest.version.number");
     	if(num!=currentVersionNum){
     	  pref.setCharPref("webdigest.version.number", currentVersionNum);
     	  addButtons = true;
     	}
     }
     catch(e){
        pref.setCharPref("webdigest.version.number", currentVersionNum);
        addButtons = true;
     }

     if(addButtons){

    	var toolbox = document.getElementById("navigator-toolbox");
    	var toolboxDocument = toolbox.ownerDocument;

    	var hasWebdigestButton = false, hasTagPageButton = false;
    	for (var i = 0; i < toolbox.childNodes.length; ++i) {
    	    var toolbar = toolbox.childNodes[i];
    	    if (toolbar.localName == "toolbar" && toolbar.getAttribute("customizable")=="true") {
    			
    		if(toolbar.currentSet.indexOf("web-button-webdigest")>-1)
    			hasWebdigestButton = true;	
    		if(toolbar.currentSet.indexOf("web-button-tagPage")>-1)
    			hasTagPageButton = true;
    	    }
    	}
    		
    	if(!hasWebdigestButton || !hasTagPageButton){
    		
    	  for (var i = 0; i < toolbox.childNodes.length; ++i) {
    	    toolbar = toolbox.childNodes[i];
    	    if (toolbar.localName == "toolbar" &&  toolbar.getAttribute("customizable")=="true" && toolbar.id=="nav-bar") {
    					
    	   	var newSet = "";
    	   	var child = toolbar.firstChild;
    	   	while(child){
    		   	
    	   	   if(!hasWebdigestButton && (child.id=="web-button-tagPage" || child.id=="urlbar-container")){		   	
    		      newSet += "web-button-webdigest,";
    		      hasWebdigestButton = true;
    	   	   }
    	   	
    	   	   if(!hasTagPageButton && child.id=="urlbar-container"){
    		      newSet += "web-button-tagPage,";
    	   	      hasTagPageButton = true;
    		   }

    		   newSet += child.id+",";
    		   child = child.nextSibling;
    		}
    		
    		newSet = newSet.substring(0, newSet.length-1);
    		toolbar.currentSet = newSet;
    		
    		toolbar.setAttribute("currentset", newSet);
    		toolboxDocument.persist(toolbar.id, "currentset");
    		BrowserToolboxCustomizeDone(true)
    		break;
    	    }
    	  }
    	}
     }
   },

   storeUser : function(aUser){
   	
      if(aUser)
        this.user = aUser;
      else
        this.user = null;
   },

   getUser : function() {

     var domain  = ".myweb.cn.yahoo.com";
     var name    = "cn_challenge";
     var user    = null;

     var cookieManager = Components.classes["@mozilla.org/cookiemanager;1"]
     				.getService(Components.interfaces.nsICookieManager);
     var iter = cookieManager.enumerator;
     while (iter.hasMoreElements()){

         var cookie = iter.getNext();
         if (cookie instanceof Components.interfaces.nsICookie){
                 if (cookie.host == domain && cookie.name == name){
                             //user = cookie.value.split(/%20/)[0];
                             user = "login";
                 };
         }
     }

   return user;
   },

   getPlatform : function(){

    var platform = new String(navigator.platform);
    var str = "";
    if(!platform.search(/^Mac/))
       str = "mac";
    else if(!platform.search(/^Win/))
       str = "win";
    else
       str = "unix";

   return str;
   },

   getAppVersionNum : function(){

     var num = "";
     var pref = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
     try{
        num = pref.getCharPref("general.useragent.vendorSub");
     }
     catch(e){}

     try{
        if(num.length==0){
          var str = pref.getCharPref("general.useragent.extra.firefox");
          var pos = str.indexOf("/")
          if(pos>-1)
            num = str.substring(pos+1);
          else
            num = str;
        }
     }
     catch(e){}

   return num;
   },

   getExtVersionNum : function(){

        var bundle = document.getElementById("bundle_webdigest");
        var num  = bundle.getString("wd_versionNum");

   return num;
   },

   //the properties used in the loadTagPage and loadTagLink functions
   openPopupWindow : function(aPath){

      //make it center	
      var width = 440, height = 440;
      var left = parseInt((screen.availWidth/2) - (width/2));
      var top  = parseInt((screen.availHeight/2) - (height/2));

      var props = "width="+width+",height="+height+",left="+left+",top="+top+",menubar=0,toolbar=0,location=0,status=1,resizable=1,scrollbars=1";
      window.open(aPath, "", props);
   },

   //for tag this page with notes
   getSelectedText : function(charlen) {

       var focusedWindow = document.commandDispatcher.focusedWindow;
       var searchStr = focusedWindow.getSelection();
       searchStr = searchStr.toString();

       var originalSearchStrLength = searchStr.length;

       if (!charlen)
            charlen = 4096;
       if (charlen < searchStr.length) {

          var pattern = new RegExp("^(?:\\s*.){0," + charlen + "}");
          pattern.test(searchStr);
          searchStr = RegExp.lastMatch;
       }

       searchStr = searchStr.replace(/^\s+/, "");
       searchStr = searchStr.replace(/\s+$/, "");
       searchStr = searchStr.replace(/\s+/g, " ");

    return {str:searchStr, len:originalSearchStrLength};
   },

   //get domain path and append additional path to it
   getWebdigestPath : function(aPath){

      var domainPath = "http://myweb.cn.yahoo.com";
      var rPath;

      if(aPath)
        rPath = domainPath + aPath;
      else
        rPath = domainPath;

   return rPath;
   },

   loadWebdigestPage : function(){

      var user = this.getUser();
      if(!user)
        loadURI(this.getWebdigestPath("/"));
      else
        //loadURI(this.getWebdigestPath("/my.html"+user));
        //loadURI(this.getWebdigestPath("/my.html"));
        loadURI(this.getWebdigestPath("/"));

      //onStateChange would handle the login status
   },

   loadTagPage: function(){

      var notes ="";
      var selectedObj = this.getSelectedText(4096);
      if(selectedObj && selectedObj.len>4096){

          var bundle = document.getElementById("bundle_webdigest");
	  var promptService = Components.classes["@mozilla.org/embedcomp/prompt-service;1"]
	  	.getService(Components.interfaces.nsIPromptService);
	  promptService.alert(null, bundle.getString("wd_notesLimitErrorDialogTitle"), bundle.getFormattedString("wd_notesLimitError", [selectedObj.len, "4096"]));	

      return;	
      }
      else{
      	if(selectedObj.str)
      	  notes = selectedObj.str;
      }

      var location, title;
      var browser = window.getBrowser();
      var webNav = browser.webNavigation;
      if(webNav.currentURI)
          location = webNav.currentURI.spec;
      else
          location = gURLBar.value;

      if(webNav.document.title){
       title = webNav.document.title;
      }
      else
       title = location;

      var user = this.getUser();
      this.openPopupWindow(this.getWebdigestPath("/popadd.html?url="+encodeURIComponent(location)+"&title="+encodeURIComponent(title)+"&summary="+encodeURIComponent(notes)+"&src=ffext"+this.getExtVersionNum()+"&f=D3_B"));
   },

   loadTagLink : function(aURL, aText){

      var user = this.getUser();
      this.openPopupWindow(this.getWebdigestPath("/popadd.html?url="+encodeURIComponent(aURL)+"&title="+encodeURIComponent(aText)+"&summary=&src=ffext"+this.getExtVersionNum()+"&f=D3_B"));
   },

   loadShowRelatedPage : function(){

      var location;
      var browser = getBrowser();
      if(browser && browser.currentURI)
          location = browser.currentURI.spec;
      else
          location = gURLBar.value;

      loadURI(this.getWebdigestPath("/url?url="+encodeURIComponent(location)));
   },

   loadRelevantPage : function(aStr){

      var user = this.user;

      switch(aStr){
        case "login":
	  if(!user)
            loadURI(this.getWebdigestPath("/login"));
          else
            loadURI(this.getWebdigestPath("/logout"));
        break;
        case "mywebdigest":
          if(!user)
            loadURI(this.getWebdigestPath("/my.html"));
          else
            loadURI(this.getWebdigestPath("/my.html"));
        break;
        case "inbox":
          if(!user)
            loadURI(this.getWebdigestPath("/login"));
          else
           loadURI(this.getWebdigestPath("/inbox/"+user));
        break;
        case "for":
          if(!user)
            loadURI(this.getWebdigestPath("/login"));
          else
           loadURI(this.getWebdigestPath("/for/"+user));
        break;
        case "popular":
          loadURI(this.getWebdigestPath("/hoturls.html"));

        break;
        case "new":
          loadURI(this.getWebdigestPath("/newurls.html"));

        break;
        case "settings":
          if(!user)
            loadURI(this.getWebdigestPath("/login"));
          else
            loadURI(this.getWebdigestPath("/settings/"+user+"/profile"));

        break;
        case "about":
          loadURI('http://help.cn.yahoo.com/answerpage.html?product=myweb');
        break;
        case "help":
          loadURI('http://help.cn.yahoo.com/answerpage.html?product=myweb');
        break;
        default:
            loadURI(this.getWebdigestPath());
        break;
      }
   },

   //ensure the status is setup properly
   updateMenuItems : function(){

        //in case the use clear the cookies
        var user = this.getUser();
        if(user)
          this.storeUser(user);
        else
          this.storeUser();

        var bundle = document.getElementById("bundle_webdigest");

        var statusItem = document.getElementById("web-menu-loginStatus");
        var elem = ["web-menu-myWebdigest","web-menu-inbox","web-menu-for","web-menu-mySettings"];

        if(user){
          statusItem.setAttribute("label", document.getElementById("bundle_webdigest").getString("wd_logout"));
  	  for(var i=0; i<elem.length; i++)
  	  	document.getElementById(elem[i]).removeAttribute("disabled");
        }	
        else{	
          statusItem.setAttribute("label", document.getElementById("bundle_webdigest").getString("wd_login"));
  	  for(var i=0; i<elem.length; i++)
	    document.getElementById(elem[i]).setAttribute("disabled", true);
        }

        //notify other window instances to update login status
	Components.classes["@mozilla.org/observer-service;1"]
		 .getService(Components.interfaces.nsIObserverService)
	      	         .notifyObservers(null, "webdigest:update-login-status", user);
   },

   hideMenu : function(){

      var bundle = document.getElementById("bundle_webdigest");

      var prompts = Components.classes["@mozilla.org/embedcomp/prompt-service;1"]
                        .getService(Components.interfaces.nsIPromptService);
      var check = {value: false};
      var flags = prompts.STD_YES_NO_BUTTONS;
      var button = prompts.confirmEx(window, bundle.getString("wd_hideMenuWindowTitle"), bundle.getString("wd_hideMenuWarning"), flags,
             null, null, null, null, check);
      if(button==0){

       //set menu hidden in default pref file
       this.setMenuHiddenInPref();

       //notify other window instances to hide menu
       Components.classes["@mozilla.org/observer-service;1"]
         		 .getService(Components.interfaces.nsIObserverService)
         	         .notifyObservers(null, "webdigest:hide-menu", "1");
      }
   },

   updateToolbarButtons : function(){

       var bundle = document.getElementById("bundle_webdigest");

       var webdigestButton = document.getElementById("web-button-webdigest");
       if(webdigestButton){

          if(this.user)
              webdigestButton.setAttribute("tooltiptext", bundle.getString("wd_mywebdigest"));
          else
              webdigestButton.setAttribute("tooltiptext", bundle.getString("wd_webdigest"));
       }
   }
}

var webdigestObserver = {

  observe : function(aSubject, aTopic, aData){

     switch(aTopic){
        case "webdigest:update-login-status":
	   webdigestMain.user = aData;
           webdigestMain.updateToolbarButtons();
        break;
        case "webdigest:hide-menu":
   	    var menu = document.getElementById("webdigest-menu");
            if(menu){
              if(aData=="1"){
   	         menu.setAttribute("hidden", true);
   	       }
   	       else{
   	         menu.removeAttribute("hidden");
   	       }
   	    }
        break;
     }
  }
}

var webdigestContextMenu = {

   register : function(){

     var menu = document.getElementById("contentAreaContextMenu");
     if(menu){
         menu.addEventListener("popupshowing", webdigestContextMenu.setup, false);
     }

     //hidden menuitems
     document.getElementById("web-context-tagCurrent-aftersearch").hidden = true;
     document.getElementById("web-context-tagCurrent").hidden = true;
     document.getElementById("web-context-tagLink").hidden = true;
   },

   unregister : function(){

     var menu = document.getElementById("contentAreaContextMenu");
     if(menu){
         menu.removeEventListener("popupshowing", webdigestContextMenu.setup, false);
     }

     //hidden menuitems
     document.getElementById("web-context-tagCurrent-aftersearch").hidden = true;
     document.getElementById("web-context-tagCurrent").hidden = true;
     document.getElementById("web-context-tagLink").hidden = true;
   },

   setup : function(){

       if(gContextMenu){

         gContextMenu.showItem("web-context-tagCurrent-aftersearch",  gContextMenu.isTextSelected);
         gContextMenu.showItem("web-context-tagCurrent",  !gContextMenu.isTextSelected && !( gContextMenu.isContentSelected || gContextMenu.onTextInput || gContextMenu.onLink || gContextMenu.onImage ));
         gContextMenu.showItem("web-context-tagLink", gContextMenu.onLink && !gContextMenu.onMailtoLink );
       }
   }
}

var webdigestProgressListener = {

    onLocationChange: function(aWebProgress, aRequest, aURI) {
    	return 0;
    },

    onStateChange: function(aWebProgress, aRequest, aStateFlags, aStatus) {
    	const nsIChannel = Components.interfaces.nsIChannel;
    	const nsIWebProgressListener = Components.interfaces.nsIWebProgressListener;
	
    	if(aStateFlags & nsIWebProgressListener.STATE_STOP) {
    		
	     if (aRequest) {
			
        	var channel;
        	try { channel = aRequest.QueryInterface(nsIChannel);} catch(e) { };
        	if (channel) {
	
        	    var URI = channel.URI;		
        	    if(URI.spec.indexOf("myweb.cn.yahoo.com")>-1){
        	
        	       var user = webdigestMain.getUser();
        	       if(user){
        	         webdigestMain.storeUser(user);
        	       }
        	       else{
        	         webdigestMain.storeUser();
        	       }
        	
		      //notify other window instances to update login status
	  	     Components.classes["@mozilla.org/observer-service;1"]
			 .getService(Components.interfaces.nsIObserverService)
	      		         .notifyObservers(null, "webdigest:update-login-status", user);
        	    }
             	}
             }	
	}

    	return 0;
    },

    onProgressChange: function(aWebProgress, aRequest,
                               aCurSelfProgress, aMaxSelfProgress,
                               aCurTotalProgress, aMaxTotalProgress) {
    	return 0;
    },

    onStatusChange: function(aWebProgress, aRequest, aStatus, aMessage) {

    	return 0;
    },

    onSecurityChange: function(aWebProgress, aRequest, aState) {

    	return 0;
    },

    onLinkIconAvailable: function() {

    	return 0;
    },

    QueryInterface: function(aIID) {
    	if (aIID.equals(Components.interfaces.nsIWebProgressListener) ||
	        aIID.equals(Components.interfaces.nsISupportsWeakReference) ||
    	    aIID.equals(Components.interfaces.nsISupports))
    		return this;
    	throw Components.results.NS_NOINTERFACE;
    }
}

function registerWebdigestProgressListener() {
    window.getBrowser().addProgressListener(webdigestProgressListener, Components.interfaces.nsIWebProgress.NOTIFY_STATE_ALL);
}

function unregisterWebdigestProgressListener(){
    window.getBrowser().removeProgressListener(webdigestProgressListener);
}

//init main
window.addEventListener("load", webdigestMain.init, false);
window.addEventListener("unload", webdigestMain.uninit, false);
