if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_MULTIPARTREQUEST_FILE     = "multipartRequest.js";
  const JS_MULTIPARTREQUEST_LOADED   = true;
  
  const boundary = "--i-N-5-4-N-3-k-4-n-3-------------314159265358979323846";
  const delimiter = "\r\n--"+boundary+"\r\n" ;
  const close_delim = "\r\n--"+boundary+"--" ;
  
  // accepts several parameters, which are placed in the body
  // of the request
  
  function 
  Parts () { this._array = new Array; }
  
  Parts.prototype = 
  {
    _iterind: 0,
  
    put: function (part)
    {
      this._array.push(part);
    },
  
    find: function (type)
    {
      var list = new Parts;
      this.resetIterator();
      while(this.hasMoreElements())
      {
        var param = this.getNext();
        if (param.type == type) list.put(param);
      }

      return list;
    },
  
    // iterator
    resetIterator: function () { this._iterind = 0; },
  
    hasMoreElements: function ()
    {
      if (this._iterind < this._array.length - 1) return true;
      else return false;
    },
  
    next: function () { return this._array[_iterind++]; }
  }
  
  function MultipartRequest (baseuri)
  {
    this.baseu = baseuri;
    this.parts = new Parts;
  }
  
  MultipartRequest.prototype =
  {
    baseu: null,
    method: "POST",
    parts: null,
  
    put: function (part)
    {
      this.parts.put(part);
      return this;
    },
  
    getRequestUri: function () 
    {
      var uri = this.baseu;
      uri +="?";
      while (this.parts.hasMoreElements()) 
      {
        var part = this.parts.getNext();
        var params = part._getRequestUriParams();
        if (params == null) continue;
        params.resetIterator();
        while (params.hasMoreElements()) 
        {
          var head = params.getNext();
          uri += head.key +"="+head.value+"&";
        }
      }
      uri = uri.slice(0,-1); //remove the last & or last ?

      return uri;
    },
  
    getRequestMethod: function () { return this.method; },
  
    setRequestHeaders: function (xhr) 
    {
      while (this.parts.hasMoreElements()) 
      {
        var part = this.parts.getNext();
        if (typeof(part) == "URLParameterPart") {
          var phead = part._getRequestHeaders();

          if (params == null) continue;

          phead.resetIterator();
          while (phead.hasMoreElements()) 
          {
            var head = phead.getNext();
            xhr.setRequestHeader(head.key,head.value);
          }
        }
      }

      xhr.setRequestHeader("Content-type","multipart/form-data; boundary="+boundary);
    },
  
    getBody: function () 
    {
      var delimstrm = jslibCreateInstance("@mozilla.org/io/string-input-stream;1",
                                          "nsIStringInputStream");
      delimstrm.setData(delimiter,-1);
  
      var multiplexstrm = 
            jslibCreateInstance("@mozilla.org/io/multiplex-input-stream;1",
                                "nsIMultiplexInputStream");

      multiplexstrm.appendStream(delimstrm);
  
      this.parts.resetIterator();
      // for each part
  
      while (this.parts.hasMoreElements()) 
      {
        var part = this.parts.getNext();
  
        var mimestrm = 
              jslibCreateInstance("@mozilla.org/network/mime-input-stream;1",
                                  "nsIMIMEInputStream");

        mimestrm.addContentLength = true;
  
        var body = part._getBody();

        if ( body == null ) continue;

        var phead = part._getRequestHeaders();
        phead.resetIterator();
        while (phead.hasMoreElements()) 
        {
          var head = phead.getNext();
          mimestrm.addHeader(head.key,head.value);
        }
        mimestrm.setData(body);
        multiplexstrm.appendStream(mimestrm);

        // is it necessary to create a new stream ?
        // leave it in anyway
        delimstrm = jslibCreateInstance("@mozilla.org/io/string-input-stream;1",
                                        "nsIStringInputStream");
        delimstrm.setData(delimiter,-1);
        multiplexstrm.appendStream(delimstrm);
      }
  
      var cdelimstrm = jslibCreateInstance("@mozilla.org/io/string-input-stream;1",
                                           "nsIStringInputStream");
      cdelimstrm.setData(close_delim,-1);
  
      multiplexstrm.appendStream(cdelimstrm);
  
      return multiplexstrm;
    }
  }

  jslibLoadMsg(JS_MULTIPARTREQUEST_FILE);

} else { dump("Load Failure: multipartRequest.js\n"); }
