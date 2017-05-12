if (typeof(JS_LIB_LOADED)=='boolean')
{
  /**
   * Globals 
   */
  
  const JS_FILEUTILS_FILE              = "fileUtils.js";
  const JS_FILEUTILS_LOADED            = true;
  
  const JS_FILEUTILS_LOCAL_CID         = "@mozilla.org/file/local;1";
  const JS_FILEUTILS_IO_SERVICE_CID    = '@mozilla.org/network/io-service;1';
  const JS_FILEUTILS_CHROME_REG_PROGID = '@mozilla.org/chrome/chrome-registry;1';
  const JS_FILEUTILS_PROCESS_CID       = "@mozilla.org/process/util;1";
  
  const JS_FILEUTILS_nsIFile           = new Components.Constructor
                                               (JS_FILEUTILS_LOCAL_CID,
                                                "nsILocalFile",
                                                "initWithPath");

  /**
   * DEPRECATED!
   * These have not been removed
   * so as to not break any clients 
   * who on the off chance may be using them
   * DEPRECATED!
   */

  const JS_FILEUTILS_FilePath          = JS_FILEUTILS_nsIFile;

  const JS_FILEUTILS_FILESPEC_PROGID   = '@mozilla.org/filespec;1';
  const JS_FILEUTILS_NETWORK_STD_CID   = '@mozilla.org/network/standard-url;1';
  const JS_FILEUTILS_DR_PROGID         = "@mozilla.org/file/directory_service;1";
  const JS_FILEUTILS_I_LOCAL_FILE      = "nsILocalFile";
  const JS_FILEUTILS_INIT_W_PATH       = "initWithPath";
  const JS_FILEUTILS_I_PROPS           = "nsIProperties";
  const JS_FILEUTILS_CHROME_DIR        = "AChrom";
  const JS_FILEUTILS_OK                = true;
  
  /* END DEPRECATED! */

  /**
   * FileUtils Library 
   */
  function FileUtils () 
  {
    include(jslib_dirutils);
    this.mDirUtils = new DirUtils;

    // deprecated undocumented functions
    // for backwards compatibility
    this.chrome_to_path = this.chromeToPath;
    this.URL_to_path    = this.urlToPath;
    this.extension      = this.ext;
    this.dirPath        = this.parent;
    this.spawn          = this.run;
    this.rm             = this.remove;

    // make compatible w/ nsIFile API
    this.leafName       = this.leaf;
    this.fileSize       = this.size;
    this.copyTo         = this.copy;
  } 
  
  FileUtils.prototype = 
  {

    mDirUtils: null,

    /**
     * CHROMETOURL 
     */
    chromeToURL : function (aPath) 
    {
      if (!aPath)
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
  
      var rv;
      try {
        var ios = jslibGetService(JS_FILEUTILS_IO_SERVICE_CID, "nsIIOService");
        var uri = ios.newURI(aPath, "UTF-8", null);
  
        var cr = jslibGetService(JS_FILEUTILS_CHROME_REG_PROGID, 
                                 "nsIChromeRegistry");

        rv = cr.convertChromeURL(uri);

        if (!jslibTypeIsString(rv))
          rv = cr.convertChromeURL(uri).spec;
      } catch (e) { rv = jslibError(e); }

      return rv;
    },
  
    /**
     * CHROMETOPATH 
     */
    chromeToPath : function (aPath) 
    {
      if (!aPath || !/^chrome:/.test(aPath))
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
  
      var rv;
      try {
        var ios = jslibGetService(JS_FILEUTILS_IO_SERVICE_CID, "nsIIOService");
        var uri = ios.newURI(aPath, "UTF-8", null);
  
        var cr = jslibGetService(JS_FILEUTILS_CHROME_REG_PROGID, 
                                 "nsIChromeRegistry");

        rv = cr.convertChromeURL(uri);

        if (!jslibTypeIsString(rv))
          rv = cr.convertChromeURL(uri).spec;

        // preserve the zip entry path "!/browser/content/browser.xul"
        // because urlToPath will flip the "/" on Windows to "\"
        var jarPath = "";
        if (/jar:/.test(rv)) {
          rv = rv.replace(/jar:/, "");
          var split = rv.split("!");
          rv = split[0];
          jarPath = "!" + split[1];
        }

        if (/resource:/.test(rv))
          rv = rv.replace(/.*resource:/, this.mDirUtils.getCurProcDir());

        if (/^file:/.test(rv))
          rv = this.urlToPath(rv);
        else
          rv = this.urlToPath("file://"+rv);

        rv += jarPath;

      } catch (e) { rv = jslibError(e); }

      return rv;
    },

    /**
     * URLTOPATH 
     */
    urlToPath : function (aPath)
    {
      if (!aPath || !/^file:/.test(aPath))
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      var rv;
      try {
        var ph = jslibCreateInstance("@mozilla.org/network/protocol;1?name=file",
                                     "nsIFileProtocolHandler");

        rv = ph.getFileFromURLSpec(aPath).path;

      } catch (e) { rv = jslibError(e); }

      return rv;
    },
    
    /**
     * PATHTOURL
     */
    pathToURL : function (aPath)
    {
      if (!aPath)
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      var rv;
      try {
        var ph = jslibCreateInstance("@mozilla.org/network/protocol;1?name=file",
                                     "nsIFileProtocolHandler");

        rv = ph.getURLSpecFromFile(this.nsIFile(aPath));

      } catch (e) { rv = jslibError(e); }

      return rv;
    },
    
    /**
     * EXISTS 
     */
    exists : function (aPath) 
    {
      if (!aPath)
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      var rv;
      try { 
        rv = (new JS_FILEUTILS_nsIFile(aPath)).exists(); 
      } catch (e) { rv = false; jslibError(e); }
    
      return rv;
    },
    
    /**
     * REMOVE 
     */
    remove : function (aPath) 
    {
      if (!aPath) 
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      if (!this.exists(aPath))
        return jslibErrorMsg("NS_ERROR_FILE_TARGET_DOES_NOT_EXIST");
    
      var rv;
      try { 
        var fileInst = new JS_FILEUTILS_nsIFile(aPath);

        if (fileInst.isDirectory())
          return jslibErrorMsg("NS_ERROR_FILE_IS_DIRECTORY");
    
        fileInst.remove(false);
        rv = JS_LIB_OK;
      } catch (e) { rv = jslibError(e); }
    
      return rv;
    },
    
    /**
     * COPY 
     */
    copy : function (aSource, aDest) 
    {
      if (!aSource || !aDest) 
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      if (!this.exists(aSource)) 
        return jslibErrorMsg("NS_ERROR_UNEXPECTED");
    
      var rv;
      try { 
        var fileInst = new JS_FILEUTILS_nsIFile(aSource);
        var dir      = new JS_FILEUTILS_nsIFile(aDest);
        var copyName = fileInst.leafName;
    
        if (fileInst.isDirectory())
          return jslibErrorMsg("NS_ERROR_FILE_IS_DIRECTORY");
    
        if (!this.exists(aDest) || !dir.isDirectory()) {
          copyName = dir.leafName;
          dir = new JS_FILEUTILS_nsIFile(dir.path.replace(copyName,''));
    
          if (!this.exists(dir.path))
            return jslibErrorMsg("NS_ERROR_FILE_ALREADY_EXISTS");
    
          if (!dir.isDirectory())
            return jslibErrorMsg("NS_ERROR_FILE_INVALID_PATH");
        }
    
        if (this.exists(this.append(dir.path, copyName))) 
          return jslibError("NS_ERROR_FILE_ALREADY_EXISTS");
    
        fileInst.copyTo(dir, copyName);
        rv = jslibRes.NS_OK;
      } catch (e) { return jslibError(e); }
    
      return rv;
    },
    
    /**
     * LEAF 
     */
    leaf : function (aPath) 
    {
      if (!aPath)
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      var rv;
      try {
        var fileInst = new JS_FILEUTILS_nsIFile(aPath);
        rv = fileInst.leafName;
      } catch (e) { return jslibError(e); }
    
      return rv;
    },
    
    /**
     * APPEND 
     */
    append : function (aDirPath, aFileName) 
    {
      if (!aDirPath || !aFileName)
        jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      if (!this.exists(aDirPath)) 
        return jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
    
      var rv;
      try { 
        var fileInst = new JS_FILEUTILS_nsIFile(aDirPath);
        if (fileInst.exists() && !fileInst.isDirectory()) 
          return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
        fileInst.append(aFileName);
        rv = fileInst.path;
        delete fileInst;
      } catch (e) { return jslibError(e); }
    
      return rv;
    },
    
    /**
     * VALIDATE PERMISSIONS 
     */
    validatePermissions : function(aNum) 
    {
      if ( parseInt(aNum.toString(10).length) < 3 ) 
        return false;
    
      return true;
    },
    
    /**
     * PERMISSIONS 
     */
    permissions : function (aPath) 
    {
      if (!aPath)
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      if (!this.exists(aPath)) 
        return jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
    
      var rv;
      try { 
        rv = (new JS_FILEUTILS_nsIFile(aPath)).permissions.toString(8);
      } catch (e) { rv = jslibError(e); }
    
      return rv;
    },
    
    /**
     * DATEMODIFIED 
     */
    dateModified : function (aPath) 
    {
      if (!aPath)
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      if (!this.exists(aPath)) 
        jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
    
      var rv;
      try { 
        rv = new Date((new JS_FILEUTILS_nsIFile(aPath)).
                   lastModifiedTime).toLocaleString();
      } catch (e) { rv = jslibError(e); }
    
      return rv;
    },
    
    /**
     * SIZE 
     */
    size : function (aPath) 
    {
      if (!aPath)
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      if (!this.exists(aPath)) 
        return jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
    
      var rv = 0;
      try { 
        rv = (new JS_FILEUTILS_nsIFile(aPath)).fileSize;
      } catch (e) { jslibError(e); }
    
      return rv;
    },
    
    /**
     * EXTENSION 
     */
    ext : function (aPath)
    {
      if (!aPath) 
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      if (!this.exists(aPath)) 
        return jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
    
      var rv;
      try { 
        var leafName  = (new JS_FILEUTILS_nsIFile(aPath)).leafName;
        var dotIndex  = leafName.lastIndexOf('.'); 
        rv = (dotIndex >= 0) ? leafName.substring(dotIndex+1) : ""; 
      } catch (e) { return jslibError(e); }
    
      return rv;
    },
    
    /**
     * PARENT
     */
    parent : function (aPath) 
    {
      if (!aPath)
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      var rv;
      try { 
        var fileInst = new JS_FILEUTILS_nsIFile(aPath);
    
        if (!fileInst.exists()) 
          return jslibErrorMsg("NS_ERROR_FILE_NOT_FOUND");
    
        if (fileInst.isFile())
          rv = fileInst.parent.path;
    
        else if (fileInst.isDirectory())
          rv = fileInst.path;
    
        else
          rv = null;
      } catch (e) { rv = jslibError(e); }
    
      return rv;
    },
    
    /**
     * RUN 
     * Trys to execute the requested file as a separate 
     * *non-blocking* process.
     * Passes the supplied *array* of arguments on the command line if
     * the OS supports it.
     *
     */
    run : function (aPath, aArgs) 
    {
      if (!aPath) 
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      if (!this.exists(aPath)) 
        return jslibErrorMsg("NS_ERROR_FILE_TARGET_DOES_NOT_EXIST");
    
      var len = 0;
      if (aArgs)
        len = aArgs.length;
      else
        aArgs = null;
    
      var rv;
      try { 
        var fileInst = new JS_FILEUTILS_nsIFile(aPath);
    
        // XXX commenting out this check as it fails on OSX 
        // if (!fileInst.isExecutable()) 
          // return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
        if (fileInst.isDirectory())
          return jslibErrorMsg("NS_ERROR_FILE_IS_DIRECTORY");

          /** 
           * Create and execute the process ...
           *
           * NOTE: The first argument of the process instance's 'run' method
           *       below specifies the blocking state (false = non-blocking).
           *       The last argument, in theory, contains the process ID (PID)
           *       on return if a variable is supplied--not sure how to implement
           *       this with JavaScript though.
           */
          try {
            var theProcess = jslibCreateInstance(JS_FILEUTILS_PROCESS_CID, 
                                                 "nsIProcess");
            
            theProcess.init(fileInst);
    
            rv = theProcess.run(false, aArgs, len);
          } catch (e) { rv = jslibError(e); }

      } catch (e) { rv = jslibError(e); }
    
      return rv;
    },
    
    /**
     * CREATE 
     */
    create : function (aPath) 
    {
      if (!aPath) 
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      var rv;
      try {
        var f = new JS_FILEUTILS_nsIFile(aPath);
        f.create(f.NORMAL_FILE_TYPE, 0644);
        rv = JS_LIB_OK;
      } catch (e) { rv = jslibError(e); }
    
      return rv;
    },
    
    /**
     * VALIDATEPATH 
     */
    isValidPath : function (aPath) 
    {
      if (!aPath) 
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      var rv = true;
      try {
        var f = new JS_FILEUTILS_nsIFile(aPath);
      } catch (e) { rv = false; jslibError(e); }
    
      return rv;
    },
    
    /**
     * NSIFILE 
     */
    nsIFile : function (aPath) 
    {
      if (!aPath) 
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      var rv;
      try {
        rv = new JS_FILEUTILS_nsIFile(aPath);
      } catch (e) { rv = jslibError(e); }
    
      return rv;
    },
    
    /**
     * HELP
     */
    get help() 
    {
      var help =
        "\n\nFunction List:\n"                +
        "\n"                                  +
        "   exists(aPath);\n"                 +
        "   chromeToPath(aPath);\n"           +
        "   chromeToURL(aPath);\n"            +
        "   urlToPath(aPath);\n"              +
        "   pathToURL(aPath);\n"              +
        "   append(aDirPath, aFileName);\n"   +
        "   create(aPath);\n"                 +
        "   remove(aPath);\n"                 +
        "   copy(aSource, aDest);\n"          +
        "   leaf(aPath);\n"                   +
        "   permissions(aPath);\n"            +
        "   dateModified(aPath);\n"           +
        "   size(aPath);\n"                   +
        "   ext(aPath);\n"                    +
        "   parent(aPath);\n"                 + 
        "   run(aPath, aArgs);\n"             + 
        "   isValidPath(aPath);\n"           + 
        "   nsIFile(aPath);\n"                + 
        "   help;\n";
    
      return help;
    }
    
  };
    
  jslibLoadMsg(JS_FILEUTILS_FILE);

} else { dump("Load Failure: fileUtils.js\n"); }

