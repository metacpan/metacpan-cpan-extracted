// *******************************************************************
// * js-app/init.js
// *******************************************************************
// * A primary design goal of JS-App is to support maximum browser
// * compatibility.  At the same time, we want our core software to
// * be riding the wave of the latest browser functionality.
// * (Our design philosophy is not merely to choose a least-common
// * denominator approach at a snapshop in time.)
// * 
// * To do this, we start by loading the init.js file.
// * This file must always be compatible (in syntax) with the very
// * oldest Javascript versions ever implemented.  Its job is to
// * decide which other Javascript files must be loaded in order
// * to provide the full functionality.
// * 
// * The following properties are supported since NN2/IE3, shown
// * with sample values from a recent version of Firefox.
// *
// *   window.location:        http://www.foo.com/app.html?w=1
// *   navigator.userAgent:    Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.6) Gecko/20050317 Firefox/1.0.2
// *   navigator.appCodeName:  Mozilla
// *   navigator.appName:      Netscape
// *   navigator.appVersion:   5.0 (Windows; en-US)
// *
// * 1. DETERMINE JAVASCRIPT VERSION (LOAD APPROPRIATE FILES)
// * All we need to determine within init.js is what variant/version
// * of Javascript/DOM is supported.  Then we load up the files that
// * are friendly to that Javascript engine to get a context object
// * instantiated.  The context object will then be responsible for
// * loading up other files particular to the theme and nationality.
// *
// * 2. LOAD DEPLOYMENT CONFIGURATION
// * All we need to determine within init.js is what variant/version
// *******************************************************************

// Before we ever get here, the application was supposed to run
// JavaScript which defines the "appOptions" object and the "appConf"
// object.
//    var appOptions; -- app values + browser values (deployment)
//    var appConf;    -- configuration of the app (development)
// Then it runs this file (js-app/init.js) to load the JS-App
// framework.  JS-App reacts to some of the parameters set in
// "appOptions" and "appConf".
appInit();

// *******************************************************************
// * Currently, we just load up the standard "app.js".
// * In the future, we will detect the 
// *******************************************************************
function appInit () {
    var html;

    appOptionsInit();

    if (appOptions.appName != null) {
        html = '<script type="text/javascript" src="' + appOptions.urlDocDir + "/" +
            appOptions.appName + '-conf.js" language="JavaScript"></script>';
        document.writeln(html);
    }

    html = '<script type="text/javascript" src="' +
        appOptions.urlDocRoot + '/js-app/app.js" language="JavaScript"></script>';

    document.writeln(html);
}

// *******************************************************************
// * appOptionsInit() - Autodetect deployment values
// * The appOptions object is initially populated with values by the
// * application.  However, we can auto-detect other values and fill
// * them in if they have not been supplied.
// *******************************************************************

// Example: http://localhost/1.0.4/members/app/edit.html?x=1&y=2
//    (a web page)
//    urlFull       = http://localhost/1.0.4/members/app/edit.html?x=1&y=2
//    urlBase       = http://localhost/1.0.4/members/app/edit.html
//    urlParams     = ?x=1&y=2
//    urlDir        = http://localhost/1.0.4/members/app
//    urlFile       = edit.html
//    appName       = edit
//    urlDocRoot    = http://localhost/1.0.4                     (a guess)
//    urlScriptRoot = http://localhost/cgi-bin/1.0.4             (a guess)
//    urlDocDir     = http://localhost/1.0.4/members/app         (same as urlDir)
//    urlScriptDir  = http://localhost/cgi-bin/1.0.4/members/app (add cgi-bin)

// Example: http://localhost/cgi-bin/1.0.4/members/app/edit?x=1&y=2
//    (a cgi program)
//    urlFull       = http://localhost/cgi-bin/1.0.4/members/app/edit?x=1&y=2
//    urlBase       = http://localhost/cgi-bin/1.0.4/members/app/edit
//    urlParams     = ?x=1&y=2
//    urlDir        = http://localhost/cgi-bin/1.0.4/members/app
//    urlFile       = edit.html
//    appName       = edit
//    urlDocRoot    = http://localhost/1.0.4                 (a guess)
//    urlScriptRoot = http://localhost/cgi-bin/1.0.4         (a guess)
//    urlScriptDir  = http://localhost/cgi-bin/1.0.4/members/app (same as urlDir)
//    urlDocDir     = http://localhost/1.0.4/members/app     (remove cgi-bin)

function appOptionsInit () {
    var appName, urlFull, urlBase, urlDir, urlFile, urlParams;
    var urlDocRoot, urlScriptRoot, urlDocDir, urlScriptDir;
    var pos, pos2;

    // augment the deployment values with values we can autodetect
    // Do some sanity checks
    if (!window.appOptions) {
        appOptions = new Object();
    }

    // if (appOptions.urlDocRoot == null) {
    //     alert("ERROR: appOptions.urlDocRoot not set\nDefine 'var appOptions = { urlDocRoot : 'value' }; in your app deployment values");
    // }
    // if (appOptions.urlScriptRoot == null) {
    //     alert("ERROR: appOptions.urlScriptRoot not set\nDefine 'var appOptions = { urlScriptRoot : 'value' }; in your app deployment values");
    // }
    
    // This parsing is (or should be) 100% JavaScript 1.0 (!) compatible

    urlFull = document.location.href;

    pos = urlFull.lastIndexOf("?");
    if (pos > 0) {
        urlParams = urlFull.substring(pos, urlFull.length);
        urlBase   = urlFull.substring(0, pos);
    }
    else {
        urlParams = "";
        urlBase   = urlFull;
    }
    pos = urlBase.lastIndexOf("/");
    if (pos > 0 && pos < urlBase.length - 1) {
        urlFile   = urlBase.substring(pos+1, urlBase.length);
        urlDir    = urlBase.substring(0, pos);
    }
    else {
        urlFile   = "";
        urlDir    = urlBase;
    }
    pos = urlFile.lastIndexOf(".");
    if (pos > 0) {
        appName   = urlFile.substring(0, pos);
    }
    else if (urlFile) {
        appName   = urlFile;
    }
    else {
        appName   = "main";
    }

    pos = urlDir.lastIndexOf("/cgi-bin/");
    if (pos >= 0) {
        var part1 = urlFull.substring(0, pos);
        var part2 = urlFull.substring(pos+8, urlFull.length);
        urlDocDir = part1 + part2;
        urlScriptDir = urlDir;
    }
    else {   // no "/cgi-bin/"
        urlDocDir = urlDir;
        pos = urlDir.indexOf("http");
        if (pos == 0) {
            pos = urlDir.indexOf("/",9);
            urlScriptDir = urlDir.substring(0,pos) + "/cgi-bin" + urlDir.substring(pos,urlDir.length);
        }
        else {
            urlScriptDir = "/cgi-bin" + urlDir;
        }
    }

    pos = urlDocDir.indexOf("http");
    if (pos == 0) {
        pos = urlDocDir.indexOf("/",9);
        pos2 = urlDocDir.indexOf("/",pos+1);
        urlDocRoot = urlDocDir.substring(0,pos2);
        urlScriptRoot = urlDocDir.substring(0,pos) + "/cgi-bin" + urlDocDir.substring(pos,pos2);

        // alert("urlDocRoot = " + urlDocRoot + "\n" +
        //       "urlScriptRoot = " + urlScriptRoot + "\n" +
        //       "urlDocDir = " + urlDocDir + "\n" +
        //       "urlScriptDir = " + urlScriptDir + "\n" +
        //       "pos = " + pos + "; pos2 = " + pos2);
    }
    else {
        pos = urlDocDir.indexOf("/",1);
        urlDocRoot = urlDocDir.substring(0,pos);
        urlScriptRoot = "/cgi-bin" + urlDocDir.substring(0,pos);
    }

    if (appOptions.urlFull       == null) appOptions.urlFull       = urlFull;
    if (appOptions.urlBase       == null) appOptions.urlBase       = urlBase;
    if (appOptions.urlDir        == null) appOptions.urlDir        = urlDir;
    if (appOptions.urlFile       == null) appOptions.urlFile       = urlFile;
    if (appOptions.urlParams     == null) appOptions.urlParams     = urlParams;
    if (appOptions.urlDocRoot    == null) appOptions.urlDocRoot    = urlDocRoot;
    if (appOptions.urlScriptRoot == null) appOptions.urlScriptRoot = urlScriptRoot;
    if (appOptions.urlDocDir     == null) appOptions.urlDocDir     = urlDocDir;
    if (appOptions.urlScriptDir  == null) appOptions.urlScriptDir  = urlScriptDir;
    if (appOptions.appName       == null) appOptions.appName       = appName;

    // Only during development time would you allow the person
    // at the browser to overwrite your deployment values.
    // To enable this, set appOptions.urlConfigOK = 1.
    // alert("urlConfigOK=" + appOptions.urlConfigOK);
    if (appOptions.urlConfigOK != null && appOptions.urlConfigOK != 0) {
        urlParams = appOptions.urlParams;
        if (urlParams != "") {
            // get rid of leading "?"
            urlParams = urlParams.substring(1,urlParams.length);
        }
        var urlParamAssignment, urlParam, urlParamValue;
        // I might need to do some unescaping here. We'll see.
        while (urlParams != "") {
            pos = urlParams.indexOf("&");
            if (pos > 0) {
                urlParamAssignment = urlParams.substring(0,pos);
                urlParams = urlParams.substring(pos+1,urlParams.length);
            }
            else {
                urlParamAssignment = urlParams;
                urlParams = "";
            }
            pos = urlParamAssignment.indexOf("=");
            if (pos > 0) {
                urlParam = urlParamAssignment.substring(0,pos);
                urlParamValue = urlParamAssignment.substring(pos+1,urlParamAssignment.length);
            }
            else {
                urlParam = urlParamAssignmen;
                urlParamValue = 1;
            }
            appOptions[urlParam] = urlParamValue;
            // alert("urlConfig: " + urlParam + "=" + urlParamValue);
        }
    }

    // These values have wide cross-browser support.
    // They are useful for determining what JavaScript features/bugs are supported.
    //    navigator.userAgent:    Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.6) Gecko/20050317 Firefox/1.0.2
    //    navigator.appCodeName:  Mozilla
    //    navigator.appName:      Netscape
    //    navigator.appVersion:   5.0 (Windows; en-US)
    if (appOptions.userAgent      == null) appOptions.userAgent      = navigator.userAgent;
    if (appOptions.appCodeName    == null) appOptions.appCodeName    = navigator.appCodeName;
    if (appOptions.appName        == null) appOptions.appName        = navigator.appName;
    if (appOptions.appVersion     == null) appOptions.appVersion     = navigator.appVersion;

    // These are (or should be) derived from the above 4 "standard" values
    if (appOptions.browserVersion == null) appOptions.browserVersion = parseInt(navigator.appVersion);
    if (appOptions.lang           == null) appOptions.lang           = 'en';
    if (appOptions.langx          == null) appOptions.langx          = 'en-US';

    // These must have some default value if they are not set already
    if (appOptions.theme          == null) appOptions.theme          = 'js-app';

    // ***************************************************************
    // Now start adding my own derived types.
    // ***************************************************************

    // This is legacy stuff from earlier code.
    // Each of these decisions should be revalidated.
    if (appOptions.browserVendor == null) {
        
        var agent = navigator.userAgent.toLowerCase();

        appOptions.browserVendor = "unknown";

        // if (navigator.appName == "Netscape") {
        //    appOptions.browserVendor = "NS";
        // }
        // if (navigator.appName.indexOf("Microsoft") != -1) {
        //    appOptions.browserVendor = "IE";
        // }
        // if (agent.indexOf("opera") != -1) {
	//         appOptions.browserVendor = "NS";
        // }
        // if (agent.indexOf("staroffice") != -1) {
	//         appOptions.browserVendor = "NS";
        // }
        // if (agent.indexOf("beonex") != -1) {
        // 	appOptions.browserVendor = "";
        // }
        // if (agent.indexOf("chimera") != -1) {
        // 	appOptions.browserVendor = "";
        // }
        // if (agent.indexOf("netpositive") != -1) {
        // 	appOptions.browserVendor = "";
        // }
        // if (agent.indexOf("phoenix") != -1) {
        // 	appOptions.browserVendor = "";
        // }
        // if (agent.indexOf("firefox") != -1) {
	//         appOptions.browserVendor = "IE";
        // }
        // if (agent.indexOf("safari") != -1) {
        // 	appOptions.browserVendor = "";
        // }
        // if (agent.indexOf("skipstone") != -1) {
        // 	appOptions.browserVendor = "";
        // }
        // if (agent.indexOf("msie") != -1) {
	//         appOptions.browserVendor = "IE";
        // }
        // if (agent.indexOf("netscape") != -1) {
	//         appOptions.browserVendor = "NS";
        // }
        // if (agent.indexOf("mozilla/5.0") != -1) {
        // 	appOptions.browserVendor = "NS";
        // }
    }
}

