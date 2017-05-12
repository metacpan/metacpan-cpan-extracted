if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_HTTP_FILE     = "http.js";
  const JS_HTTP_LOADED   = true;
  
  function HTTP () { }
  
  HTTP.prototype = 
  {
    response:null,
    status:null,
  
    doOperation: function (req) 
    {
      p = new XMLHttpRequest;
      p.onload = null;
  
      p.open(req.getRequestMethod(),
              req.getRequestUri(),
              false);
  
      var s = req.getBody(p);
      req.setRequestHeaders(p);
      p.send(s);
  
      // since this is sync request, we get results after send()
      this.status = p.status;
      if ( this.status != "200" ) {
        return false;
      } else {
        this.response = p.responseText;
        return true;
      }
    }
  }
  
  jslibLoadMsg(JS_HTTP_FILE);

} else { dump("Load Failure: http.js\n"); }


