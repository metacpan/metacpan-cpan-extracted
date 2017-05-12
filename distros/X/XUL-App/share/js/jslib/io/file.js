if (typeof(JS_LIB_LOADED) == 'boolean') 
{
  // test to make sure filesystem base class is loaded
  if (typeof(JS_FILESYSTEM_LOADED) != 'boolean')
    include(jslib_filesystem);
  
  /**
   * Globals 
   */
  const JS_FILE_LOADED           = true;
  const JS_FILE_FILE             = "file.js";
  
  const JS_FILE_IOSERVICE_CID    = "@mozilla.org/network/io-service;1";
  const JS_FILE_I_STREAM_CID     = "@mozilla.org/scriptableinputstream;1";
  const JS_FILE_OUTSTREAM_CID    = "@mozilla.org/network/file-output-stream;1";
  const JS_FILE_BINOUTSTREAM_CID = "@mozilla.org/binaryoutputstream;1";
  const JS_FILE_BININSTREAM_CID  = "@mozilla.org/binaryinputstream;1";
  
  const JS_FILE_F_TRANSPORT_SERVICE_CID  = 
    "@mozilla.org/network/file-transport-service;1";
  
  const JS_FILE_I_IOSERVICE              = jslibI.nsIIOService;
  const JS_FILE_I_SCRIPTABLE_IN_STREAM   = "nsIScriptableInputStream";
  const JS_FILE_I_FILE_OUT_STREAM        = jslibI.nsIFileOutputStream;
  const JS_FILE_I_BINARY_OUT_STREAM      = "nsIBinaryOutputStream";
  const JS_FILE_I_BINARY_IN_STREAM       = "nsIBinaryInputStream";
  
  const JS_FILE_READ          = 0x01;  // 1
  const JS_FILE_WRITE         = 0x08;  // 8
  const JS_FILE_APPEND        = 0x10;  // 16
  
  const JS_FILE_READ_MODE     = "r";
  const JS_FILE_WRITE_MODE    = "w";
  const JS_FILE_APPEND_MODE   = "a";
  const JS_FILE_BINARY_MODE   = "b";
  
  const JS_FILE_FILE_TYPE     = 0x00;  // 0
  const JS_FILE_CHUNK         = 1024;  // buffer for readline => set to 1k
  const JS_FILE_DEFAULT_PERMS = 0644;
  
  try {
    const JS_FILE_InputStream  = new Components.Constructor
      (JS_FILE_I_STREAM_CID, JS_FILE_I_SCRIPTABLE_IN_STREAM);
  
    const JS_FILE_IOSERVICE    = jslibGetService(JS_FILE_IOSERVICE_CID,
                                                 JS_FILE_I_IOSERVICE);
  } catch (e) { jslibError(e); }

  
  /***
   * Possible values for the ioFlags parameter 
   * From: 
   * http://lxr.mozilla.org/seamonkey/source/nsprpub/pr/include/prio.h#601
   */
  
  // #define PR_RDONLY       0x01
  // #define PR_WRONLY       0x02
  // #define PR_RDWR         0x04
  // #define PR_CREATE_FILE  0x08
  // #define PR_APPEND       0x10
  // #define PR_TRUNCATE     0x20
  // #define PR_SYNC         0x40
  // #define PR_EXCL         0x80
  
  const JS_FILE_NS_RDONLY               = 0x01;
  const JS_FILE_NS_WRONLY               = 0x02;
  const JS_FILE_NS_RDWR                 = 0x04;
  const JS_FILE_NS_CREATE_FILE          = 0x08;
  const JS_FILE_NS_APPEND               = 0x10;
  const JS_FILE_NS_TRUNCATE             = 0x20;
  const JS_FILE_NS_SYNC                 = 0x40;
  const JS_FILE_NS_EXCL                 = 0x80;
  
  
  /****************************************************************
  * void File(aPath)                                              *
  *                                                               *
  * class constructor                                             *
  * aPath is an argument of string local file path                *
  * returns NS_OK on success, exception upon failure              *
  *   Ex:                                                         *
  *     var p = '/tmp/foo.dat';                                   *
  *     var f = new File(p);                                      *
  *                                                               *
  *   outputs: void(null)                                         *
  ****************************************************************/

  // constructor 
  function File (aPath) 
  {
    var rv;
    if (!aPath)
      return jslibErrorMsg("NS_ERROR_INVALID_ARG");
  
    // if the argument is a File or nsIFile object
    if (jslibTypeIsObj(aPath))
      rv = aPath.path;
    else
      rv = arguments;
  
    return this.initPath(rv);
  } 
  
  File.prototype = new FileSystem;
  
  // member vars
  File.prototype.mMode        = null;
  File.prototype.mIsBinary    = false;
  File.prototype.mFileChannel = null;
  File.prototype.mTransport   = null;
  File.prototype.mURI         = null;
  File.prototype.mOutStream   = null;
  File.prototype.mInputStream = null;
  File.prototype.mLineBuffer  = null;
  File.prototype.mPosition    = 0;
  
  /********************* OPEN *************************************
  * bool open(aMode, aPerms)                                      *
  *                                                               *
  * opens a file handle to read, write or append                  *
  * aMode is an argument of string 'w', 'a', 'r', 'b'             *
  * returns true on success, null on failure                      *
  *   Ex:                                                         *
  *     var p='/tmp/foo.dat';                                     *
  *     var f=new File(p);                                        *
  *                                                               *
  *   outputs: void(null)                                         *
  ****************************************************************/
  
  File.prototype.open = function (aMode, aPerms) 
  {
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if (this.exists() && this.mFileInst.isDirectory()) 
        return jslibErrorMsg("NS_ERROR_FILE_IS_DIRECTORY");
  
    // close any existing file handles
    this.close();
  
    if (this.mMode) 
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if (!this.mURI) {
      if (!this.exists())
        this.create();
      this.mURI = JS_FILE_IOSERVICE.newFileURI(this.mFileInst);
    }
  
    if (!aMode)
      aMode=JS_FILE_READ_MODE;
  
    this.resetCache();
    var rv;
    
    this.mIsBinary = false;
    var access;
    while (aMode.length > 0) 
    {
      switch (aMode[0]) 
      {
        case JS_FILE_WRITE_MODE:
        case JS_FILE_APPEND_MODE:
        case JS_FILE_READ_MODE: 
        {
          access = aMode[0];
          break;
        }
        case JS_FILE_BINARY_MODE: 
        {
          this.mIsBinary = true;
          break;
        }
        default:
          return jslibErrorMsg("NS_ERROR_INVALID_ARG");
      }
      aMode = aMode.substring(1);
    }
    aMode = access;
  
    switch (aMode) 
    {
      case JS_FILE_WRITE_MODE: 
      case JS_FILE_APPEND_MODE: 
      {
        try {
          if (!this.mFileChannel)
            this.mFileChannel = JS_FILE_IOSERVICE.newChannelFromURI(this.mURI);
        } catch (e) { return jslibError(e); }    
  
        if (aPerms && this.validatePermissions(aPerms))
          this.mFileInst.permissions = aPerms;
  
        if (!aPerms)
          aPerms = JS_FILE_DEFAULT_PERMS;
  
        try {
          var offSet=0;
          this.mMode = aMode;
          // create a filestream
          var fs = jslibCreateInstance(JS_FILE_OUTSTREAM_CID, 
                                         JS_FILE_I_FILE_OUT_STREAM);
          if (aMode == JS_FILE_WRITE_MODE)
            fs.init(this.mFileInst, JS_FILE_NS_TRUNCATE | 
                                    JS_FILE_NS_WRONLY, aPerms, null); 
          else
            fs.init(this.mFileInst, JS_FILE_NS_RDWR | 
                                    JS_FILE_NS_APPEND, aPerms, null); 

          this.mOutStream = fs;
          if (this.mIsBinary) {
            // wrap a nsIBinaryOutputStream around the actual file
            var binstream = jslibCreateInstance(JS_FILE_BINOUTSTREAM_CID, 
                                                JS_FILE_I_BINARY_OUT_STREAM);
            binstream.setOutputStream(this.mOutStream);
            this.mOutStream = binstream;
          }
        } catch (e) { return jslibError(e); }
        rv = JS_LIB_OK;
        break;
      }
  
      case JS_FILE_READ_MODE: {
        if (!this.exists()) 
          jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
  
        this.mMode=JS_FILE_READ_MODE;
  
        try {
          this.mFileChannel = JS_FILE_IOSERVICE.newChannelFromURI(this.mURI);
          this.mLineBuffer  = new Array();
          if (this.mIsBinary) {
            // wrap a nsIBinaryInputStream around the nsIInputStream
            this.mInputStream = jslibCreateInstance(JS_FILE_BININSTREAM_CID, 
                                                    JS_FILE_I_BINARY_IN_STREAM);
            this.mInputStream.setInputStream(this.mFileChannel.open());
          } else {
            // wrap a nsIScriptableInputStream around the nsIInputStream
            this.mInputStream = new JS_FILE_InputStream();    
            this.mInputStream.init(this.mFileChannel.open());
          }
          rv = JS_LIB_OK;
        } catch (e) { rv = jslibError(e); }

        break;
      }
  
      default:
        rv = jslibErrorMsg("NS_ERROR_INVALID_ARG");
    }
  
    return rv;
  }
  
  /********************* READ *************************************
  * string read()                                                 *
  *                                                               *
  * reads a file if the file is binary it will                    *
  * return type ex: ELF                                           *
  * takes no arguments needs an open read mode filehandle         *
  * returns string on success, null on failure                    *
  *   Ex:                                                         *
  *     var p='/tmp/foo.dat';                                     *
  *     var f=new File(p);                                        *
  *     f.open();                                                 *
  *     f.read();                                                 *
  *                                                               *
  *   outputs: <string contents of foo.dat>                       *
  ****************************************************************/
  
  File.prototype.read = function (aSize) 
  {
    if (!this.checkInst() || !this.mInputStream)
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if (this.mMode != JS_FILE_READ_MODE) {
      this.close();
      return jslibErrorMsg("NS_ERROR_NOT_AVAILABLE");
    }
  
    var rv;
    try {
      if (!aSize)
        aSize = this.mFileInst.fileSize;

      if (this.mIsBinary)
        rv = this.mInputStream.readByteArray(aSize);
      else
        rv = this.mInputStream.read(aSize);
      
      this.mInputStream.close();
    } catch (e) { rv = jslibError(e); }

    return rv;
  }
  
  /********************* READLINE**********************************
  * string readline()                                             *
  *                                                               *
  * reads a file if the file is binary it will                    *
  * return type string                                            *
  * takes no arguments needs an open read mode filehandle         *
  * returns string on success, null on failure                    *
  *   Ex:                                                         *
  *     var p='/tmp/foo.dat';                                     *
  *     var f=new File(p);                                        *
  *     f.open();                                                 *
  *     while(!f.EOF)                                             *
  *       dump("line: "+f.readline()+"\n");                       *
  *                                                               *
  *   outputs: <string line of foo.dat>                           *
  ****************************************************************/
  
  File.prototype.readline = function ()
  {
    if (!this.checkInst() || !this.mInputStream)
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    var rv      = null;
    var buf     = null;
    var tmp     = null;
    try {
      if (this.mLineBuffer.length < 2) {
        buf = this.mInputStream.read(JS_FILE_CHUNK);
        this.mPosition = this.mPosition + JS_FILE_CHUNK;
        if (this.mPosition > this.mFileInst.fileSize) 
          this.mPosition  = this.mFileInst.fileSize;
        if (buf) {
          if (this.mLineBuffer.length == 1) {
            tmp = this.mLineBuffer.shift();
            buf = tmp+buf;
          }
          this.mLineBuffer = buf.split(/[\n\r]/);
        }
      }
      rv = this.mLineBuffer.shift();
    } catch (e) { rv = jslibError(e); }

    return rv;
  }
  
  /********************* READALLINES ******************************
  * string array readAllLines()                                   *
  *                                                               *
  * returns array string on success, null on failure              *
  *   Ex:                                                         *
  *     var p='/tmp/foo.dat';                                     *
  *     var f=new File(p);                                        *
  *     var lines = f.readAllLines();                             *
  *                                                               *
  *   outputs: <string array of foo.dat>                          *
  ****************************************************************/
  
  File.prototype.readAllLines = function ()
  {
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");

    var rv = null;
    try {
      var fis = jslibCreateInstance("@mozilla.org/network/file-input-stream;1",
                                    "nsIFileInputStream");
      fis.init(this.mFileInst,-1,-1,false);

      var lis = jslibQI(fis, "nsILineInputStream");
      var line = { value: "" };
      var more = false;
      var lines = [];

      do {
        more = lis.readLine(line);
        lines.push(line.value);
      } while (more);

      fis.close();
      rv = lines;

    } catch (e) { jslibError(e); } 

    return rv;
  }
  
  /********************* EOF **************************************
  * bool getter EOF()                                             *
  *                                                               *
  * boolean check 'end of file' status                            *
  * return type boolean                                           *
  * takes no arguments needs an open read mode filehandle         *
  * returns true on eof, false when not at eof                    *
  *   Ex:                                                         *
  *     var p='/tmp/foo.dat';                                     *
  *     var f=new File(p);                                        *
  *     f.open();                                                 *
  *     while(!f.EOF)                                             *
  *       dump("line: "+f.readline()+"\n");                       *
  *                                                               *
  *   outputs: true or false                                      *
  ****************************************************************/
  
  File.prototype.__defineGetter__('EOF', 
  function ()
  {
    if (!this.checkInst() || !this.mInputStream)
      jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if ((this.mLineBuffer.length > 0) || 
        (this.mInputStream.available() > 0)) 
      return false;
    
    return true;
  })
  
  /********************* WRITE ************************************
  * write()                                                       *
  *                                                               *
  *  Write data to a file                                         *
  *                                                               *
  *   Ex:                                                         *
  *     var p='/tmp/foo.dat';                                     *
  *     var f=new File(p);                                        *
  *     f.open("w");                                              *
  *     f.write();                                                *
  *                                                               *
  *   outputs: JS_LIB_OK upon success                             *
  ****************************************************************/
  
  File.prototype.write = function (aBuffer)
  {
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if (this.mMode == JS_FILE_READ_MODE) {
      this.close();
      return jslibErrorMsg("NS_ERROR_FILE_READ_ONLY");
    }
  
    if (!aBuffer) aBuffer = "";
  
    var rv  = JS_LIB_OK;
    try {
      if (this.mIsBinary && aBuffer.constructor == Array) 
        this.mOutStream.writeByteArray(aBuffer, aBuffer.length);
      else 
        this.mOutStream.write(aBuffer, aBuffer.length);
      
      this.mOutStream.flush();
    } catch (e) { rv = jslibError(e); }
  
    return rv;
  }
  
  /********************* COPY *************************************
  * void copy(aDest)                                              *
  *                                                               *
  * void file close                                               *
  * return type void(null)                                        *
  * takes no arguments closes an open file stream and             *
  * deletes member var instances of objects                       *
  *   Ex:                                                         *
  *     var p='/tmp/foo.dat';                                     *
  *     var f=new File(p);                                        *
  *     fopen();                                                  *
  *     f.close();                                                *
  *                                                               *
  *   outputs: JS_LIB_OK upon success                             *
  ****************************************************************/
  
  File.prototype.copy = function (aDest, aForce)
  {
    if (!aDest)
      return jslibErrorMsg("NS_ERROR_INVALID_ARG");
  
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if (!this.exists()) 
      return jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
  
    var rv = JS_LIB_OK;
    try {
      var dest = new JS_FS_File_Path(aDest);
      var copyName, dir = null;
  
      if (dest.equals(this.mFileInst)) 
        return jslibErrorMsg("NS_ERROR_FILE_COPY_OR_MOVE_FAILED");
  
      if (!aForce && dest.exists()) 
        return jslibErrorMsg("NS_ERROR_FILE_ALREADY_EXISTS");
  
      if (this.mFileInst.isDirectory()) 
        return jslibErrorMsg("NS_ERROR_FILE_IS_DIRECTORY");
  
      if (!dest.exists()) {
        copyName = dest.leafName;
        dir = dest.parent;
  
        if (!dir.exists()) 
          return jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
  
        if (!dir.isDirectory()) 
          return jslibErrorMsg("NS_ERROR_FILE_DESTINATION_NOT_DIR");
      }
  
      if (!dir) {
        dir = dest;
        if (dest.equals(this.mFileInst)) 
          return jslibErrorMsg("NS_ERROR_FILE_COPY_OR_MOVE_FAILED");
      }
      this.mFileInst.copyTo(dir, copyName);
    } catch (e) { rv = jslibError(e); }

    return rv;
  }
  
  /********************* CLOSE ************************************
  * void close()                                                  *
  *                                                               *
  * void file close                                               *
  * return type void(null)                                        *
  * takes no arguments closes an open file stream and             *
  * deletes member var instances of objects                       *
  *   Ex:                                                         *
  *     var p='/tmp/foo.dat';                                     *
  *     var f=new File(p);                                        *
  *     fopen();                                                  *
  *     f.close();                                                *
  *                                                               *
  *   outputs: void(null)                                         *
  ****************************************************************/
  
  File.prototype.close = function () 
  {
    if (this.mFileChannel)   delete this.mFileChannel;
    if (this.mInputStream)   delete this.mInputStream;
    if (this.mTransport)     delete this.mTransport;
    if (this.mMode)          this.mMode = null;
  
    if (this.mOutStream) {
      this.mOutStream.close();
      delete this.mOutStream;
    }
  
    if (this.mInputStream) {
      this.mInputStream.close();
      delete this.mInputStream;
    }
  
    if (this.mLineBuffer) this.mLineBuffer = null;
    this.mPosition = 0;
  
    if( this.mURI ) {
      delete this.mURI;
      this.mURI = null;
    }
  
    return JS_LIB_OK;
  }
  
  /**
   * CREATE 
   */
  File.prototype.create = function ()
  {
    // We can probably implement this so that it can create a 
    // file or dir if a long non-existent mPath is present
  
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if (this.exists()) 
      return jslibErrorMsg("NS_ERROR_FILE_ALREADY_EXISTS");
  
    var rv = JS_LIB_OK;
    try { 
      this.mFileInst.create(JS_FILE_FILE_TYPE, JS_FILE_DEFAULT_PERMS); 
    } catch (e) { rv = jslibError(e); }
  
    return rv;
  }
  
  /**
   * CREATEUNIQUE 
   */
  File.prototype.createUnique = function ()
  {
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    var rv = JS_LIB_OK;
    try { 
      this.mFileInst.createUnique(JS_FILE_FILE_TYPE, JS_FILE_DEFAULT_PERMS); 
    } catch (e) { rv = jslibError(e); }
  
    return rv;
  }
  
  /**
   * CLONE 
   */
  File.prototype.clone = function ()
  {
    if (!this.checkInst())
        return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");

    return new File(this.mPath);
  },

  /**
   * REMOVE 
   */
  File.prototype.remove = function ()
  {
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if (!this.mPath) 
      return jslibErrorMsg("NS_ERROR_FILE_INVALID_PATH");
  
    if (!this.exists()) 
      return jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
  
    this.close();

    var rv = JS_LIB_OK;
    try {
      this.mFileInst.remove(false); 
    } catch (e) { rv = jslibError(e); }
  
    return rv;
  }
  
  /********************* POS **************************************
  * int getter POS()                                              *
  *                                                               *
  * int file position                                             *
  * return type int                                               *
  * takes no arguments needs an open read mode filehandle         *
  * returns current position, default is 0 set when               *
  * close is called                                               *
  *   Ex:                                                         *
  *     var p='/tmp/foo.dat';                                     *
  *     var f=new File(p);                                        *
  *     f.open();                                                 *
  *     while(!f.EOF){                                            *
  *       dump("pos: "+f.pos+"\n");                               *
  *       dump("line: "+f.readline()+"\n");                       *
  *     }                                                         *
  *                                                               *
  *   outputs: int pos                                            *
  ****************************************************************/
  
  File.prototype.__defineGetter__('pos', function (){ return this.mPosition; })
  
  /********************* SIZE *************************************
  * int getter size()                                             *
  *                                                               *
  * int file size                                                 *
  * return type int                                               *
  * takes no arguments a getter only                              *
  *   Ex:                                                         *
  *     var p='/tmp/foo.dat';                                     *
  *     var f=new File(p);                                        *
  *     f.size;                                                   *
  *                                                               *
  *   outputs: int 16                                             *
  ****************************************************************/
  
  File.prototype.__defineGetter__('size',
  function ()
  {
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if (!this.mPath) 
      return jslibErrorMsg("NS_ERROR_FILE_INVALID_PATH");
  
    if (!this.exists()) 
      return jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
  
    this.resetCache();

    var rv;
    try { 
      rv = this.mFileInst.fileSize; 
    } catch(e) { rv = jslibError(e); }
  
    return rv;
  }) // END size Getter
  
  /********************* EXTENSION ********************************
  * string getter ext()                                           *
  *                                                               *
  * string file extension                                         *
  * return type string                                            *
  * takes no arguments a getter only                              *
  *   Ex:                                                         *
  *     var p='/tmp/foo.dat';                                     *
  *     var f=new File(p);                                        *
  *     f.ext;                                                    *
  *                                                               *
  *   outputs: dat                                                *
  ****************************************************************/
  
  File.prototype.__defineGetter__('ext', 
  function ()
  {
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if (!this.mPath) 
      return jslibErrorMsg("NS_ERROR_FILE_INVALID_PATH");
    
    if (!this.exists()) 
      return jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
  
    var rv;
    try {
      var leafName  = this.mFileInst.leafName;
      var dotIndex  = leafName.lastIndexOf('.');
      rv = (dotIndex >= 0) ? leafName.substring(dotIndex+1) : "";
    } catch(e) { rv = jslibError(e); }
  
    return rv;
  }) // END ext Getter
  
  File.prototype.super_help = FileSystem.prototype.help;
  
  /**
   * HELP 
   */
  File.prototype.__defineGetter__('help', 
  function ()
  {
    const help = this.super_help()            +
      "   open(aMode);\n"                     +
      "   read();\n"                          +
      "   readline();\n"                      +
      "   EOF;\n"                             +
      "   write(aContents, aPermissions);\n"  +
      "   copy(aDest);\n"                     +
      "   close();\n"                         +
      "   create();\n"                        +
      "   remove();\n"                        +
      "   size;\n"                            +
      "   ext;\n"                             +
      "   help;\n";
  
    return help;
  })
  
  jslibLoadMsg(JS_FILE_FILE);

} else { dump("Load Failure: file.js\n"); }

