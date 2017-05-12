if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_POSTREQUEST_FILE     = "postRequest.js";
  const JS_POSTREQUEST_LOADED   = true;
  
  include(jslib_dictionary);
  
  function 
  PostRequest (baseuri)
  {
    this.baseu = baseuri;
    this.parameters = new Dictionary();
  }
  
  PostRequest.prototype = 
  {
    baseu: null,
    method: "POST",
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
      uri += this.baseu;

      return uri;
    },
  
    getRequestMethod: function () { return this.method; },
  
    setRequestHeaders: function (p) 
    {
      p.setRequestHeader("Content-type","application/x-www-form-urlencoded");
    },
  
    getBody: function () 
    {
      var uri = "";
      this.parameters.resetIterator();
      while (this.parameters.hasMoreElements())
      {
        var param = this.parameters.next();
        if (this.parameters.hasMoreElements()) {
          uri+= escape(param.key)+"="+escape(param.value)+"&";
        } else {
          uri+= escape(param.key)+"="+escape(param.value);
          break;
        }
      }

      return uri;
    }
  }
  
  jslibLoadMsg(JS_POSTREQUEST_FILE);

} else { dump("Load Failure: postRequest.js\n"); }

