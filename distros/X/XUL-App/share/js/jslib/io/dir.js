if (typeof(JS_LIB_LOADED)=='boolean') 
{
  if (typeof(JS_FILESYSTEM_LOADED)!='boolean')
    include(jslib_filesystem);

  /**
   * Globals 
   */
  const JS_DIR_FILE                    = "dir.js";
  const JS_DIR_LOADED                  = true;
  
  const JS_DIR_DIRECTORY               = 0x01;  // 1
  
  const JS_DIR_DEFAULT_PERMS           = 0755;
  
  /**
   * DEPRECATED!
   * These are all deprecated
   * I would like to remove them
   * but wil not in case any clients 
   * may be using them
   * DEPRECATED!
   */

  const JS_DIR_LOCAL_CID               = "@mozilla.org/file/local;1";
  const JS_DIR_LOCATOR_PROGID          = '@mozilla.org/filelocator;1';
  const JS_DIR_CID                     = "@mozilla.org/file/directory_service;1";
  const JS_DIR_I_LOCAL_FILE            = "nsILocalFile";
  const JS_DIR_INIT_W_PATH             = "initWithPath";
  const JS_DIR_PREFS_DIR               = 65539;
  const JS_DIR_OK                      = true;

  const JS_DIR_FilePath                = new Components.Constructor
                                               (JS_DIR_LOCAL_CID,
                                                "nsILocalFile" ,
                                                "initWithPath");
   /* END DEPRECATED! */

  /**
   * Constructor
   */
  function Dir (aPath) 
  {
    if (!aPath) 
      return jslibErrorMsg("NS_ERROR_XPC_NOT_ENOUGH_ARGS");
  
    var rv;
    if (jslibTypeIsObj(aPath))
      rv = aPath.path;
    else
      rv = arguments;
  
    return this.initPath(rv);
  } 
  
  Dir.prototype = new FileSystem;
  Dir.prototype.fileInst = null;
  
  /**
   * CREATE 
   */
  Dir.prototype.create = function (aPermissions) 
  {
    if (!this.checkInst()) 
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if (this.exists()) 
      return jslibErrorMsg("NS_ERROR_FILE_ALREADY_EXISTS");
  
    var checkedPerms;
    if (jslibTypeIsNumber(aPermissions)) {
      checkedPerms = this.validatePermissions(aPermissions);
  
      if (!checkedPerms) 
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
  
      checkedPerms = aPermissions;
    } else {
      var p = this.mFileInst.parent;
      while (p && !p.exists())
        p = p.parent;
      
      checkedPerms = p.permissions;
    }
  
    if (!checkedPerms) checkedPerms = JS_DIR_DEFAULT_PERMS;
  
    var rv = JS_LIB_OK;
    try {
      this.mFileInst.create(JS_DIR_DIRECTORY, checkedPerms);
    } catch (e) { rv = jslibError(e); }
  
    return rv;
  };

  /**
   * CREATEUNIQUE
   */
  Dir.prototype.createUnique = function (aPermissions)
  {
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");

    var checkedPerms;
    if (jslibTypeIsNumber(aPermissions)) {
      checkedPerms = this.validatePermissions(aPermissions);
  
      if (!checkedPerms) 
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
  
      checkedPerms = aPermissions;
    } else {
      var p = this.mFileInst.parent;
      while (p && !p.exists())
        p = p.parent;
      
      checkedPerms = p.permissions;
    }

    if (!checkedPerms) checkedPerms = JS_DIR_DEFAULT_PERMS;
  
    var rv = JS_LIB_OK;
    try {
      this.mFileInst.createUnique(JS_DIR_DIRECTORY, checkedPerms);
    } catch (e) { rv = jslibError(e); }

    return rv;
  };

  /**
   * READDIR 
   */
  Dir.prototype.readDir = function ()
  {
    if (!this.exists()) 
      return jslibErrorMsg("NS_ERROR_FILE_TARGET_DOES_NOT_EXIST");
  
    var rv = JS_LIB_OK;
    try {
      if (!this.isDir()) 
        return jslibErrorMsg("NS_ERROR_FILE_NOT_DIRECTORY");
  
      var files     = this.mFileInst.directoryEntries;
      var listings  = new Array();
      var file;
  
      include(jslib_file);
      while (files.hasMoreElements()) 
      {
        file = files.getNext().QueryInterface(jslibI.nsILocalFile);
        if (file.isFile())
          listings.push(new File(file.path));
  
        if (file.isDirectory())
          listings.push(new Dir(file.path));
      }
  
      rv = listings;
    } catch(e) { rv = jslibError(e); }
  
    return rv;
  };
  
  /**
   * CLONE 
   */
  Dir.prototype.clone = function ()
  {
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    return new Dir(this.mPath);
  };
  
  /**
  * CONTAINS
  */
  Dir.prototype.contains = function (aFileObj)
   {
      if (!aFileObj)
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
  
      if (!this.checkInst())
        return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
      var rv;
      try {
        var fo;
        if (typeof(aFileObj.nsIFile) == "object")
          fo = aFileObj.nsIFile;
        else
          fo = aFileObj;
  
        rv = this.mFileInst.contains(fo, true);
      } catch (e) { rv = false; }
  
      return rv;
  };
  
  /**
   * REMOVE 
   */
  Dir.prototype.remove = function (aRecursive)
  {
    if (typeof(aRecursive)!='boolean')
      aRecursive=false;
  
    if (!this.checkInst())
      return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");
  
    if (!this.mPath)
      return jslibErrorMsg("NS_ERROR_INVALID_ARG");
  
    var rv = JS_LIB_OK;
    try { 
      if (!this.exists()) 
        return jslibErrorMsg("NS_ERROR_FILE_TARGET_DOES_NOT_EXIST");
  
      if (!this.isDir()) 
        return jslibErrorMsg("NS_ERROR_FILE_NOT_DIRECTORY");
  
      this.mFileInst.remove(aRecursive);
    } catch (e) { rv = jslibError(e); }
  
    return rv;
  };
  
  /**
   * HELP 
   */
  Dir.prototype.super_help = FileSystem.prototype.help;
  
  Dir.prototype.__defineGetter__('help', 
  function () 
  {
    var help = this.super_help()              +
      "   create(aPermissions);\n"            +
      "   remove(aRecursive);\n"              +
      "   readDir(aDirPath);\n";
  
    return help;
  });
  
  jslibLoadMsg(JS_DIR_FILE);
  
} else { dump("Load Failure: dir.js\n"); }
  
