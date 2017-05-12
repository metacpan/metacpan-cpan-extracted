if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_REMOTEFILE_FILE     = "remoteFile.js";
  const JS_REMOTEFILE_LOADED   = true;
  
  const JS_REMOTEFILE_URI_CID  = "@mozilla.org/network/simple-uri;1";
  const JS_REMOTEFILE_URI_I_ID = jslibI.nsIURI;
  
  const JS_REMOTEFILE_IOSERVICE_CID  = "@mozilla.org/network/io-service;1";
  const JS_REMOTEFILE_I_IOSERVICE    = jslibI.nsIIOService;
  const JS_REMOTEFILE_IOSERVICE      = jslibGetService(JS_REMOTEFILE_IOSERVICE_CID,
                                                       "nsIIOService");
                                                                                                      
  function 
  RemoteFile (aURL) 
  {
    if (!aURL)
      return jslibError("NS_ERROR_XPC_NOT_ENOUGH_ARGS");
  
    try {
      var url = jslibCreateInstance(JS_REMOTEFILE_URI_CID, 
                                    "nsIURI");
  
      url.spec = aURL;
  
      var protocol = url.scheme;
  
      if (protocol != "http") {
        jslibDebug("RemoteFile URL: "+aURL);
        jslibDebug("RemoteFile: Sorry, only http is implemented! not ["+protocol+"]");
        return null;
      }
  
      this.mURI = aURL;
    } catch (e) { jslibError(e); }
  
    return JS_LIB_OK; 
  } 
  
  RemoteFile.prototype  = 
  {
    mURI : null,
    mInputStream : null,
    mOutputStream : null,
    mContent : null,
    mContentType : null,
  
    open : function () 
    {
      var rf = new XMLHttpRequest();
      rf.open("GET", this.mURI, false);
      // to prevent leaks see Mozilla bug #206947
      rf.overrideMimeType("text/xml");
      rf.send(null);

      if (rf.status!=200)
        jslibDebug("Status Code: "+rf.status);

      this.mContent = rf.responseText;
      this.mContentType = rf.getResponseHeader("Content-type");

      return true;
    },
  
    read : function () 
    {
      if (!this.mContent)
        throw "No remote file instance available you must use open first";
  
      return this.mContent;
    },
  
    get nsIURI () 
    {
      if (!this.mURI) return "";

      return (JS_REMOTEFILE_IOSERVICE.newURI(this.mURI, null, null));
    },
  
    get contentType () 
    {
      if (!this.mURI) return "";

      if (this.mContentType)
        return this.mContentType;
  
      var xml = new XMLHttpRequest;
      xml.open("HEAD", this.mURI, false);
      xml.overrideMimeType("text/xml");
      xml.send(null);

      return xml.getResponseHeader("Content-type");
    },
  
    exists : function () 
    {
      if (!this.mURI) return false;;
  
      var rv = false;
      var xml = new XMLHttpRequest();
      xml.open("HEAD", this.mURI, false);
      xml.overrideMimeType("text/xml");
      xml.send(null);
  
      if (xml.status != 404)
        rv = true;
  
      return rv;
    },
  
    /**
     * returns a javascript Date object
     * for the Last-Modified timestamp of the 
     * remote url
     */
    get dateModified () { return this.lastModified; },
  
    get lastModified () 
    {
      if (!this.mURI)
        return null;
  
      var rv = null;
      var xml = new XMLHttpRequest();
      xml.open("HEAD", this.mURI, false);
      xml.overrideMimeType("text/xml");
      xml.send(null);

      rv = xml.getAllResponseHeaders();
      rv = rv.match(/Last-Modified: .*/);
  
      if (!rv)
        return null;
  
      rv = rv[0];
  
      return (new Date(rv.substring(15, rv.length)));
    },
  
    get help() 
    {
      const help =
        "\n\nFunction and Attribute List:\n"        +
        "nsIURI\n"                                  +
        "open()\n"                                  +
        "read()\n"                                  +
        "contentType\n"                             +
        "exists()\n"                                +
        "\n";                  
  
      return help;
    } 
  } 
  
  jslibLoadMsg(JS_REMOTEFILE_FILE);

} else { dump("Load Failure: remoteFile.js\n"); }

  
