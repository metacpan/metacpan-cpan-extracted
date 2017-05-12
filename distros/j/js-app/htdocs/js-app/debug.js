
function write_navigator () {
    // platform : "Win32",
    // appCodeName : "Mozilla",
    // appName : "Netscape",
    // appVersion : "5.0 (Windows; en-US)",
    // language : "en-US",
    // oscpu : "Windows NT 5.1",
    // vendor : "Firefox",
    // vendorSub : "1.0.2",
    // product : "Gecko",
    // productSub : "20050317",
    // userAgent : "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.6) Gecko/20050317 Firefox/1.0.2",
    // cookieEnabled : true,
    // javaEnabled : function,
    document.writeln("<pre>");
    document.writeln("*navigator.userAgent:       " + navigator.userAgent);       // NN2, IE3
    document.writeln("*navigator.appCodeName:     " + navigator.appCodeName);     // NN2, IE3
    document.writeln("*navigator.appName:         " + navigator.appName);         // NN2, IE3
    document.writeln("*navigator.appVersion:      " + navigator.appVersion);      // NN2, IE3
    document.writeln(" navigator.appMinorVersion: " + navigator.appMinorVersion); //      IE4
    document.writeln(" navigator.cookieEnabled:   " + navigator.cookieEnabled);   //      IE4
    document.writeln(" navigator.browserLanguage: " + navigator.browserLanguage); //      IE4
    document.writeln(" navigator.language:        " + navigator.language);        // NN4     
    document.writeln(" navigator.oscpu:           " + navigator.oscpu);           //         
    document.writeln(" navigator.platform:        " + navigator.platform);        // NN4, IE4
    document.writeln(" navigator.product:         " + navigator.product);         //         
    document.writeln(" navigator.productSub:      " + navigator.productSub);      //         
    document.writeln(" navigator.vendor:          " + navigator.vendor);          // 
    document.writeln(" navigator.vendorSub:       " + navigator.vendorSub);       // 
    document.writeln(" navigator.javaEnabled():   " + navigator.javaEnabled());   // NN3, IE4
    document.writeln("</pre>");
}

function write_screen () {
    // top : 0,
    // left : 0,
    // width : 1024,
    // height : 768,
    // pixelDepth : 32,
    // colorDepth : 32,
    // availWidth : 1024,
    // availHeight : 738,
    // availLeft : 0,
    // availTop : 0
    document.writeln("<pre>");
    document.writeln("screen.top:         " + screen.top);
    document.writeln("screen.left:        " + screen.left);
    document.writeln("screen.width:       " + screen.width);
    document.writeln("screen.height:      " + screen.height);
    document.writeln("screen.pixelDepth:  " + screen.pixelDepth);
    document.writeln("screen.colorDepth:  " + screen.colorDepth);
    document.writeln("screen.availWidth:  " + screen.availWidth);
    document.writeln("screen.availHeight: " + screen.availHeight);
    document.writeln("screen.availLeft:   " + screen.availLeft);
    document.writeln("screen.availTop:    " + screen.availTop);
    document.writeln("</pre>");
}

function write_window () {
    // scrollX : 0,
    // scrollY : 0,
    // closed : false,
    // innerWidth : 811,
    // innerHeight : 598,
    // outerWidth : 1025,
    // outerHeight : 738,
    // screenX : 0,
    // screenY : 0,
    // pageXOffset : 0,
    // pageYOffset : 0,
    // scrollMaxX : 0,
    // scrollMaxY : 0,
    // length : 0,
    // fullScreen : false,
    document.writeln("<pre>");
    document.writeln("*window.location:    " + window.location);     // NN2, IE3
    document.writeln("*window.status:      " + window.status);       // NN2, IE3
    document.writeln(" window.closed:      " + window.closed);       // NN3, IE4
    document.writeln(" window.innerWidth:  " + window.innerWidth);   // NN4
    document.writeln(" window.innerHeight: " + window.innerHeight);  // NN4
    document.writeln(" window.outerWidth:  " + window.outerWidth);   // NN4
    document.writeln(" window.outerHeight: " + window.outerHeight);  // NN4
    document.writeln(" window.pageXOffset: " + window.pageXOffset);  // NN4
    document.writeln(" window.pageYOffset: " + window.pageYOffset);  // NN4
    document.writeln(" window.length:      " + window.length);       //      IE4
    document.writeln(" window.scrollX:     " + window.scrollX);      //
    document.writeln(" window.scrollY:     " + window.scrollY);      //
    document.writeln(" window.screenX:     " + window.screenX);      //
    document.writeln(" window.screenY:     " + window.screenY);      //
    document.writeln(" window.scrollMaxX:  " + window.scrollMaxX);   //
    document.writeln(" window.scrollMaxY:  " + window.scrollMaxY);   //
    document.writeln(" window.fullScreen:  " + window.fullScreen);   //
    document.writeln("</pre>");
}

function write_document () {
    document.writeln("<pre>");
    document.writeln("document.title:                  " + document.title);                   // NN2, IE3
    document.writeln("document.referrer:               " + document.referrer);                // NN2, IE3
    document.writeln("document.baseURI:                " + document.baseURI);                 // NN2, IE3
    document.writeln("document.documentURI:            " + document.documentURI);             // NN2, IE3
    document.writeln("document.doctype:                " + document.doctype);                 // NN2, IE3
    document.writeln("document.width:                  " + document.width);                   // NN2, IE3
    document.writeln("document.height:                 " + document.height);                  // NN2, IE3
    document.writeln("document.alinkColor:             " + document.alinkColor);              // NN2, IE3
    document.writeln("document.linkColor:              " + document.linkColor);               // NN2, IE3
    document.writeln("document.vlinkColor:             " + document.vlinkColor);              // NN2, IE3
    document.writeln("document.bgColor:                " + document.bgColor);                 // NN2, IE3
    document.writeln("document.fgColor:                " + document.fgColor);                 // NN2, IE3
    document.writeln("document.domain:                 " + document.domain);                  // NN2, IE3
    document.writeln("document.characterSet:           " + document.characterSet);            // NN2, IE3
    document.writeln("document.contentType:            " + document.contentType);             // NN2, IE3
    document.writeln("document.lastModified:           " + document.lastModified);            // NN2, IE3
    document.writeln("document.actualEncoding:         " + document.actualEncoding);          // NN2, IE3
    document.writeln("</pre>");
}

