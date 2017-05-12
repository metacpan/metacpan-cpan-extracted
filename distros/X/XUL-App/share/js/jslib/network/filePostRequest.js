if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_FILEPOSTREQUEST_FILE     = "filePostRequest.js";
  const JS_FILEPOSTREQUEST_LOADED   = true;
  
  function 
  FilePostRequest (baseuri){ this.baseu = baseuri; }
  
  FilePostRequest.prototype = 
  {
    baseu   : null,
    method  : "POST",
    cnttype : null,
    cntenc  : null,
    filen   : null,
    instrm  : null,
  
    setFile: function (filename, stream, contenttype) 
    {
      this.filen = filename;
      this.instrm = stream;
      this.cnttype = contenttype;
    },
  
    setFile: function (filename, jslibFile, contenttype) 
    {
      this.filen = filename;
  
      var finstrm =
          jslibCreateInstance("@mozilla.org/network/file-input-stream;1",
                              "nsIFileInputStream");
      finstrm.init(jslibFile.nsIFile, 1, 1, finstrm.CLOSE_ON_EOF);
  
      this.instrm =
          jslibCreateInstance("@mozilla.org/network/buffered-input-stream;1",
                              "nsIBufferedInputStream");
      this.instrm.init(finstrm, 4096);
      this.cnttype = contenttype;
    },
  
    getRequestUri: function () {
      var uri = "";
      uri += this.baseu;

      return uri;
    },
  
    getRequestMethod: function () { return this.method; },
  
    setRequestHeaders: function (p) { return null; },
  
    getBody: function (p) {
      var boundary = "--i-N-5-4-N-3-k-4-n-3-------------314159265358979323846";
      var delimiter = "\r\n--"+boundary+"\r\n" ;
      var close_delim = "\r\n--"+boundary+"--" ;
      var cont_dispos_tag = "Content-disposition";
      var cont_dispos_val1 = "form-data; name=\"";
      var cont_dispos_val2 = "\"; filename=\"";
      var cont_dispos_val3 = "\"";
      var cont_type_tag = "Content-type";
      var cont_type_val = this.cnttype;
  
      // set up the multipart stream
      var delimstrm =
          jslibCreateInstance("@mozilla.org/io/string-input-stream;1",
                              "nsIStringInputStream");
      delimstrm.setData(delimiter,-1);
  
      // the part in a multipart stream
      var mimestrm =
          jslibCreateInstance("@mozilla.org/network/mime-input-stream;1",
                              "nsIMIMEInputStream");
      mimestrm.addContentLength = false;
      mimestrm.addHeader(cont_dispos_tag,cont_dispos_val1+this.filen+cont_dispos_val2+this.filen+cont_dispos_val3);
      mimestrm.addHeader(cont_type_tag,cont_type_val);
      mimestrm.setData(this.instrm);
  
      var cdelimstrm =
          jslibCreateInstance("@mozilla.org/io/string-input-stream;1",
                              "nsIStringInputStream");
      cdelimstrm.setData(close_delim,-1);
  
      var multiplexstrm =
          jslibCreateInstance("@mozilla.org/io/multiplex-input-stream;1",
                              "nsIMultiplexInputStream");
      multiplexstrm.appendStream(delimstrm);
      multiplexstrm.appendStream(mimestrm);
      multiplexstrm.appendStream(cdelimstrm);
  
      p.setRequestHeader("Content-length",multiplexstrm.available());
      p.setRequestHeader("Content-type","multipart/form-data; boundary="+boundary);
  
      return multiplexstrm;
    }
  }
  
  jslibLoadMsg(JS_FILEPOSTREQUEST_FILE);

} else { dump("Load Failure: filePostRequest.js\n"); }

