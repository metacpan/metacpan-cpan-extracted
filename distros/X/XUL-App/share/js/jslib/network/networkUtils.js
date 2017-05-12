if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_NETWORKUTILS_FILE     = "networkUtils.js";
  const JS_NETWORKUTILS_LOADED   = true;
  
  function 
  NetworkUtils () {} 
  
  NetworkUtils.prototype  = 
  {
    mCallBack    :null,
    mValidateURI :null,

    _callback : function ()
    {
      if (jslibTypeIsFunc(this.callback))
        this.callback();
      else
        jslibDebug("callback is not a function ...");
    },

    get callback ()
    {
      return this.mCallBack;
    },

    set callback (aVal)
    {
      this.mCallBack = aVal;
    }, 

    fixupURI : function (aURI)
    {
      if (!aURI)
        return jslibError("NS_ERROR_XPC_NOT_ENOUGH_ARGS");

      var rv = null;
      try {
        var fixupURI = jslibCreateInstance("@mozilla.org/docshell/urifixup;1",
                                           "nsIURIFixup");

        // FIXUP_FLAG_NONE = 0
        var uri = fixupURI.createFixupURI(aURI, 0);

        if (uri)
          rv = uri;

      } catch (e) { jslibError(e); }

      return rv;
    },

    validateURI : function (aURI)
    {
      if (!aURI)
        return jslibError("NS_ERROR_XPC_NOT_ENOUGH_ARGS");

      var uri = aURI;

      if (jslibInstanceOf(aURI, "nsIURI"))
        uri = aURI.spec;
        
      this.mValidateURI = uri;

      var rv = JS_LIB_OK;
      try {
        uri = this.fixupURI(uri);

        var checker = jslibCreateInstance("@mozilla.org/network/urichecker;1",
                                          "nsIURIChecker");
        checker.init(uri);
        checker.loadFlags = jslibI.nsIRequest.LOAD_BYPASS_CACHE;

        checker.asyncCheck(this, null);
   
      } catch (e) { rv = jslibError(e); } 

      return rv;
    },

    QueryInterface : function (iid)
    {
      if (!iid.equals(jslibI.nsIRequestObserver) &&
          !iid.equals(jslibI.nsISupports) &&
          !iid.equals(jslibI.nsIInterfaceRequestor))
        throw jslibRes.NS_ERROR_NO_INTERFACE;

      return this;
    },

    onStartRequest : function (aRequest, aContext) {},

    onStopRequest : function (aRequest, aContext, aStatus)
    {
      var cb = this.callback;
      if (aStatus == 0) {
        jslibDebugMsg("URI is GOOD", this.mValidateURI);
        if (jslibTypeIsFunc(this.callback))
          setTimeout(cb, 1, true);
      } else {
        if (jslibTypeIsFunc(this.callback))
          setTimeout(cb, 1, false);
        jslibDebugMsg("URI is INVALID", this.mValidateURI);
      }
      aRequest.cancel(jslibRes.NS_ERROR_ABORT);
    }
  };

  jslibLoadMsg(JS_NETWORKUTILS_FILE);

} else { dump("Load Failure: networkUtils.js\n"); }

  
