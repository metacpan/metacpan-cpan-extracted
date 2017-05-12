if (typeof(JS_LIB_LOADED) == 'boolean') 
{
  // test to make sure base classes are loaded
  include(jslib_zip);
  include(jslib_file);
  include(jslib_fileutils);
  
  /**
   * Globals 
   */
  const JS_CHROME_FILE_LOADED           = true;
  const JS_CHROME_FILE_FILE             = "chromeFile.js";

/*****************************************************************
 * void ChromeFile(aPath)                                        *
 *                                                               *
 * class constructor                                             *
 * aPath is an argument of string chrome file path               *
 *   Ex:                                                         *
 *     var p = '/tmp/foo.dat';                                   *
 *     var f = new File(p);                                      *
 *                                                               *
 *****************************************************************/

  // constructor 
  function ChromeFile (aPath) 
  {
    var jarResults;

    if (!aPath)
      throw Components.results.NS_ERROR_INVALID_ARG;
  
    this.mFU = new FileUtils;

    this.mChromePath = aPath;    
    this.mURLPath    = this.mFU.chromeToURL(aPath);
    this.mLocalPath  = this.mFU.chromeToPath(aPath);

    // if you pass a non existant chrome URL on FF
    // nsIChromeRegistry convertChromeURL fails
    // if we fail here, we know that aPath is bogus
    // as well --pete
    if (this.mURLPath < 0 || this.mLocalPath < 0)
      return;

    if (!this.mURLPath)
      throw Components.results.NS_ERROR_FAILURE;

    /* If this is a jar:
     * jarResults[0] is the full path.
     * jarResults[1] is the path to the jar file.
     * jarResults[2] is the path within the jar file to the chrome file.
     *
     * If this is a flat file:
     * jarResults == null.
     */

    // isJarResults = /^jar:(file:\/\/\/.*\.jar)!\/(.*)/.exec(urlPath);

    this.mIsJarFile = /^jar:/.test(this.mURLPath);

    if (this.isJarFile) {
      jarResults = this.mLocalPath.split("!");
      this.mLocalPath = jarResults[0];

      // strip off the leading "/"
      this.mJarPath = jarResults[1].replace(/^\//, "");

      this.mZip          = new Zip(this.mLocalPath);

    } else {
      this.mJarPath      = null;
      this._nsIZipReader = null;
      this.mZip          = null;
    }

    this.mFile = new File(this.mLocalPath);

    if (this.exists()) {
      if (this.isJarFile)
        this.mSize = this.Zip.getEntryRealSize(this.jarPath)
      else
        this.mSize = this.mFile.size;
    }
  }

  ChromeFile.prototype = 
  {
    mIsJarFile:    false,
    mFU:           null,
    mChromePath:   null,
    mSize:         0,
    mURLPath:      null,
    mLocalPath:    null,
    mJarPath:      null,
    mFile:         null,
    mZip:          null,
    _nsIZipReader: null,

    /**
     * Open the file for read-only access.
     *
     * @return nsresult Error code for failure (0 if success).
     */
    open: function open () 
    {
      if (!this.exists())
        return jslibError("NS_ERROR_FILE_NOT_FOUND");

      if (this.isJarFile)
        return this.Zip.open();

      return this.File.open("r");
    },

    /**
     * Read the contents of the file into a returned string.
     *
     * @return JSString reflecting the file's contents.
     */
    read: function read () 
    {
      if (!this.exists())
        return jslibError("NS_ERROR_FILE_NOT_FOUND");

      if (this.isJarFile)
        return this.Zip.readEntry(this.jarPath);

      return this.File.read();
    },

    /**
     * Copy the file to a new destination.
     *
     * @param aDest JSString local file path to new file.
     *
     * @return nsresult Error code for failure (0 if success).
     */
    copy: function copy (aDest) 
    {
      if (!this.exists())
        return jslibError("NS_ERROR_FILE_NOT_FOUND");

      if (this.isJarFile)
        return this.Zip.extractEntry(this.jarPath, aDest);

      return this.File.copy(aDest);
    },

    /**
     * Close the file.
     *
     * @return nsresult Error code for failure (0 if success).
     */
    close: function close () 
    {
      if (!this.exists())
        return jslibError("NS_ERROR_FILE_NOT_FOUND");

      if (this.isJarFile)
        return this.Zip.close();

      return this.File.close();
    },

    /**
     * Determine if the file referenced actually exists.
     *
     * @return bool True if the file exists.
     */
    exists: function exists () 
    {
      // If our path to the local file doesn't exist, nothing else matters.
      if (!this.File || !this.File.exists())
        return false;

      // If it's a .jar file, check to see if we can retrieve it.
      if (this.isJarFile)
        return this.Zip.findEntries(this.jarPath).hasMoreElements();

      return true;
    }, 

    /**
     * Determine if the file is a jarred file.
     *
     * @return bool True if the chrome file is jarred.
     */

    get isJarFile () { return this.mIsJarFile; },

    /**
     * Original chrome:// protocol path to the chrome file.
     *
     * @return JSString for the chrome path.
     */

    get chromePath () { return this.mChromePath; },

    /**
     * The size of the chrome file.
     *
     * @return JSNumber of bytes in the file.
     */

    get size () { return this.mSize; },

    /**
     * List the properties and methods this object supports.
     *
     * @return JSString of member properties and methods.
     */

    /**
     * URL path to the chrome file 
     * (jar://file:///path/to.jar!/path/within/jar/to/file.txt)
     *
     * @return JSString for the url path.
     */
    
    get urlPath() { return this.mURLPath; },

    /**
     * The path to the jar file or unjarred chrome file on the 
     * local file system.
     */
    get localPath () { return this.mFU.chromeToPath(this.mChromePath); },

    /**
     * The path to the jarred chrome file within a jar file.
     */
    
    get jarPath () { return this.mJarPath; },

    /**
     * The File constructor function.
     */
    
    get File() { return this.mFile; },

    /**
     * The nsIFile object for this interface.
     */
    
    get nsIFile() { return this.File.nsIFile; },

    /**
     * The Zip constructor function.
     */
    
    get Zip() { return this.mZip; },

    /**
     * The nsIZipReader object for this interface.
     */
    
    get nsIZipReader() { return this._nsIZipReader; },

    get help () 
    {
      const help = ""        +
        "   exists();\n"     +
        "   open();\n"       +
        "   read();\n"       +
        "   close();\n"      +
        "   copy(aDest);\n"  +
        "   size;\n"         +
        "   isJarFile;\n"    +
        "   chromePath;\n"   +
        "   urlPath;\n"      +
        "   localPath;\n"    +
        "   jarPath;\n"      +
        "   FIle;\n"         +
        "   nsIFile;\n"      +
        "   Zip;\n"          +
        "   nsIZipReader;\n" +
        "   help;\n";

      return help;
    }
  };
  
  jslibLoadMsg(JS_CHROME_FILE_FILE);

} else { dump("Load Failure: chromeFile.js\n"); }
