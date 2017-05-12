if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_GETREQUEST_FILE     = "getRequest.js";
  const JS_GETREQUEST_LOADED   = true;
  
  include(jslib_dictionary);
  
  function 
  GetRequest (baseuri)
  {
    this.baseu = baseuri;
    this.parameters = new Dictionary;
  }
  
  GetRequest.prototype = 
  {
    baseu: null,
    method: "GET",
    parameters: null,
    cnttype: null,
    cntenc: null,
  
    put: function (key,value) 
    {
      this.parameters.put(key,value);
      return this;
    },
  
    getRequestUri: function () 
    {
      var uri = "";
      uri += this.baseu + "?";
      this.parameters.resetIterator();
      while (this.parameters.hasMoreElements())
      {
        var param = this.parameters.next();
        uri+= escape(param.key)+"="+escape(param.value)+"&";
      }
      uri = uri.slice(0,-1) //discard & or ?
      return uri;
    },
  
    getRequestMethod: function () { return this.method; },
  
    setRequestHeaders: function (p) { return null; },
  
    getBody: function () { return null; }
  }
  
  jslibLoadMsg(JS_GETREQUEST_FILE);

} else { dump("Load Failure: getRequest.js\n"); }

