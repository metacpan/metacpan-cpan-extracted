if (typeof(JS_LIB_LOADED) == "boolean") 
{
  const JS_DEBUG_LOADED     = true;
  const JS_DEBUG_FILE       = "debug.js";
  const jslibConsoleService = jslibGetService("@mozilla.org/consoleservice;1", 
                                              "nsIConsoleService");

  /****************************************************************
  * void jslibDebug(aOutString)                                   *
  * aOutString is an argument of string debug message             *
  * returns void                                                  *
  *   eg:                                                         * 
  *       var msg="Testing function";                             *
  *       jslibDebug(msg);                                        *
  *                                                               *
  *   outputs: Testing function                                   *
  ****************************************************************/

  function 
  jslibDebug (aMsg) 
  {
    if (!JS_LIB_DEBUG)
      return; 

    if (JS_LIB_DEBUG_ALERT)
      alert(aMsg);

    jslibDumpInternal(aMsg+"\n");
  }

  function 
  jslibDebugSep (aMsg)
  {
    if (!JS_LIB_DEBUG)
    return;

    jslibPrintSep(aMsg);
  }

  function 
  jslibPrint (aMsg) { jslibDumpInternal(aMsg+"\n"); }

  function 
  jslibPrintMatch (aMsg, aMatch) 
  {
    var pat = "/" +aMatch+ "/g";
    var regex = new RegExp(pat);

    if (regex.test(aMsg))
      jslibDumpInternal(aMsg+"\n");
  }

  function 
  jslibPrintDebug (aMsg, aOutString) 
  {
    if (!aMsg) aMsg = "JSLIB_DEBUG: ";
    jslibDumpInternal(aMsg+" "+aOutString+"\n");
  }

  function 
  jslibDebugMsg (aMsg, aOutString) { jslibPrintDebug(aMsg, aOutString); }

  function 
  jslibDebugMsgBracket (aMsg, aOutString) 
  { 
    jslibPrintDebug(aMsg, "["+aOutString+"]"); 
  }

  function 
  jslibPrintBracket (aOutString) 
  {
    jslibDumpInternal("["+aOutString+"]\n");
  }

  function 
  jslibPrintMsg () 
  {
    var out = "";
    var len = arguments.length;

    for (var i=0; i<len; i++)
    {
      var sep = "";

      if (i != len-1) sep = ":";

      out += arguments[i] + sep;
    }

    jslibDumpInternal(out+"\n");
  }

  function 
  jslibPrintMsgMatch (aOutStr1, aOutStr2, aMatch) 
  {
    var pat = "/" +aMatch+ "/g";
    var regex = new RegExp(pat);

    if (regex.test(aOutStr2))
      jslibDumpInternal(aOutStr1+": "+aOutStr2+"\n");
  }

  function 
  jslibPrintLine () { jslibDumpInternal("\n"); }
  var jslibPrintLn = jslibPrintLine;

  function 
  jslibPrintSep (aMsg)
  {
    jslibPrintLine();
    jslibPrint("*********************");
    jslibPrint(aMsg);
    jslibPrint("*********************");
    jslibPrintLine();
  }

  function 
  jslibPrintStart ()
  {
    jslibPrint("START *********************");
  }

  function 
  jslibPrintEnd ()
  {
    jslibPrint("END ***********************");
  }


  /****************************************************************
  * void jslibError(e)                                            *
  * e        - argument of results exception                      *
  * returns e.result                                              *
  *   Ex:                                                         * 
  *       jslibError(e)                                           *
  *                                                               *
  *   outputs:                                                    *
  *       -----======[ ERROR ]=====-----                          *
  *       Error in jslib.js: include:  Missing file path argument *
  *                                                               *
  *       NS_ERROR_NUMBER:   NS_ERROR_XPC_NOT_ENOUGH_ARGS         *
  *       ------------------------------                          *
  *                                                               *
  ****************************************************************/

  function 
  jslibError (aE) 
  {
    if (jslibTypeIsStr(aE))
      return jslibErrorMsg(aE);

    var rv = null;
    var errMsg="";
    if (/^TypeError/.test(aE))
      return jslibErrorString(aE);

    if (jslibTypeIsObj(aE)) {
      var m, n, r, l, ln, fn = "";
      try {
        rv = -aE.result;
        m  = aE.message;
        fn = aE.filename;
        l  = aE.location; 
        ln = l.lineNumber; 
      } catch (e) { }
      errMsg+="FileName:          "+fn+"\n"           +
              "Result:            "+rv+"\n"           +
              "Message:           "+m+"\n"            +
              "LineNumber:        "+ln+"\n";
    }

    errMsg = "\n-----======[ jsLib ERROR ]=====-----\n" + errMsg;
    errMsg += "-------------------------------------\n";

    jslibDebug(errMsg);

    return rv;
  }

  function 
  jslibErrorWarn (e)
  {
    jslibDebug("jsLib warn: "+e);
    return null;
  }

  function 
  jslibErrorString (e)
  {
    jslibDebug(e);
    return -1;
  }

  function 
  jslibErrorMsg (e, comment)
  {
    typeof(comment) == "string" ? jslibDebugMsgBracket(e, comment) : jslibDebug(e);
    return -jslibRes[e];
  }

  function 
  jslibDisplayProperties (aObj)
  {
    var props = jslibGetProperties(aObj);
    if (props.length > 1)
      props = props.sort();

    var rv = "";
    for (var i=0; i<props.length; i++)
      rv += typeof(aObj[props[i]]) + " : " + props[i] + "\n";

    jslibDumpInternal(rv);

    return rv;
  }

  function 
  jslibPrintProperties (aObj)
  {
    var props = jslibGetProperties(aObj);
    if (props.length > 1)
      props = props.sort();

    var rv = "";
    for (var i=0; i<props.length; i++)
      rv += props[i] + "\n";

    jslibDumpInternal(rv);

    return rv;
  }

  function 
  jslibMatchProperties (aObj, aMatch)
  {
		var pat = new RegExp(aMatch, "i");
    var out = "";

    for (var list in aObj)
			if (pat.test(list)) 
        out += list + "\n";

    if (out)
      jslibDumpInternal(out);
  }

  function 
  jslibGetMatchProperties (aObj, aMatch)
  {
    var rv = new Array;
		var pat = new RegExp(aMatch, "i");

    for (var list in aObj)
			if (pat.test(list))
        rv.push(list);

    return rv;
  }

  function 
  jslibGetProperties (aObj)
  {
    var out = new Array;
    for (var list in aObj)
      out.push(list);

    return out;
  }

  function 
  jslibPropertyCount (aObj)
  {
    if (!aObj) return null;

    return jslibGetProperties(aObj).length;
  }

  function 
  jslibAlertProperties (aObj)
  {
    var out = "";
    for (var list in aObj)
      out += list+"\n";

    alert(out);
  }

  function 
  jslibWriteProperties (aObj)
  {
    include(jslib_dirutils);
    include(jslib_file);

    var f = new File( (new DirUtils).getTmpDir() );
    f.append("jslib-obj-properties.txt");
    f.open("w");
    f.write(jslibPrintProperties(aObj));
    f.close();

  }

  function jslibPrintCallStack (aFunc)
  {
    if (!jslibTypeIsFunc(aFunc)) 
      jslibPrintMsg("ERROR", "argument must be a function");

    var a = new Array;
    var c = aFunc.caller;
    a.push(aFunc.name);

    while (c)
    {
      if (c.name == "") break;
      a.push(c.name);
      c = c.caller;  
    }

    a = a.reverse();
  
    for (var i=0; i<a.length; i++) 
      jslibPrintMsg(i, a[i] + "()");
  
  }

  function 
  jslibPrintType (aObj)
  {
    jslibPrint(typeof(aObj));
  }

  function 
  jslibPrintTypeWName (aName, aObj)
  {
      jslibPrint("Name: "+aName+" JSType: "+typeof(aObj));
  }

  function 
  jslibTypeIsObj (aType) 
  { 
    return (aType && typeof(aType) == "object"); 
  }

  function 
  jslibTypeIsFunc (aType) 
  { 
    return (aType && typeof(aType) == "function"); 
  }

  function 
  jslibTypeIsStr (aType) 
  { 
    return (aType && typeof(aType) == "string"); 
  }

  function 
  jslibTypeIsNum (aType) 
  { 
    return (aType && typeof(aType) == "number"); 
  }

  function 
  jslibTypeIsUndef (aType) 
  { 
    return (aType && typeof(aType) == "undefined"); 
  }

  var jslibTypeIsObject    = jslibTypeIsObj;
  var jslibTypeIsFunction  = jslibTypeIsFunc;
  var jslibTypeIsString    = jslibTypeIsStr;
  var jslibTypeIsNumber    = jslibTypeIsNum;
  var jslibTypeIsUndefined = jslibTypeIsUndef;

  // possible undefined types -  use w/ typeof 
  // eg: 
  //   jslibUTypeIsObj(typeof(window));

  function jslibUTypeIsObj   (aType) { return (aType == "object"); }
  function jslibUTypeIsFunc  (aType) { return (aType == "function"); }
  function jslibUTypeIsStr   (aType) { return (aType == "string"); }
  function jslibUTypeIsNum   (aType) { return (aType == "number"); }
  function jslibUTypeIsUndef (aType) { return (aType == "undefined"); }

  var jslibUTypeIsObject    = jslibUTypeIsObj;
  var jslibUTypeIsFunction  = jslibUTypeIsFunc;
  var jslibUTypeIsString    = jslibUTypeIsStr;
  var jslibUTypeIsNumber    = jslibUTypeIsNum;
  var jslibUTypeIsUndefined = jslibUTypeIsUndef;

  function 
  jslibDumpConsole (aMsg)
  {
    jslibConsoleService.logStringMessage(aMsg);
  }

  function 
  jslibGetConsoleMessages ()
  {
    var rv = new Array;
    var out = {};
    jslibConsoleService.getMessageArray(out, {});

    if (!out) 
    {
      rv = [];
    } 
      else 
    {
      var m = out.value;
      for (var i=0; i<m.length; i++) 
      {
        var err;
        try 
        {
          err = m[i].QueryInterface(jslibI.nsIScriptError);
        } 
          catch (e) 
        {
          err = m[i].message;
        }

        rv.push(err);
      }
    }

    return rv;
  }

  function 
  jslibDumpConsoleMessages ()
  {
    var m = jslibGetConsoleMessages();
    var rv = "";
    for (var i=0; i<m.length; i++)
      rv += m[i] + "\n";
      
    dump(rv);

    return rv; 
  }

  function 
  jslibDumpInternal (aMsg)
  {
    dump(aMsg);
    jslibDumpConsole(aMsg);
  }

  function 
  jslibLoadMsg (aFileName)
  {
    jslibDebug("*** load: "+aFileName+" OK");
  }

  function 
  jslibErrorLookUp (aErrorNum)
  {
    var errCode, rv = null;
    if (jslibTypeIsNum(aErrorNum)) {
      errCode = Math.abs(aErrorNum);
      for (var list in jslibRes)
        if(errCode == jslibRes[list]) {
          rv = list;
          break;
        }
    } else if (jslibTypeIsString(aErrorNum)) {
      errCode = aErrorNum;
      if (errCode in jslibRes) 
        rv = -jslibRes[errCode];
    }

    return rv;
  }

  function 
  jslibInstanceOf (aObj, aIface)
  {
    return (aObj instanceof jslibI[aIface]);
  }

  // Welcome message
  jslibLoadMsg(JS_DEBUG_FILE);

  if (JS_LIB_VERBOSE)
    jslibDebug(JS_LIB_HELP);

  jslibDebugSep("JS_LIB DEBUG IS ON");
 
} else { dump("Load Failure: debug.js\n"); }

