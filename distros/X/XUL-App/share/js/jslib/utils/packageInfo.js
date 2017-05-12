if (typeof(JS_LIB_LOADED) == 'boolean') 
{
  const JS_PACKAGEINFO_LOADED = true;
  const JS_PACKAGEINFO_FILE   = 'packageInfo.js';

  function PackageInfo (aPkgName) 
  {
    if (!aPkgName)
      return jslibErrorMsg("NS_ERROR_XPC_NOT_ENOUGH_ARGS");

    this.pkgName = aPkgName;

    return this.init();
  }

  PackageInfo.prototype = 
  {
    pkgName    : null,
    rdfService : null,
    ds         : null,
    resSelf    : null,

    init : function ()
    {
      var rv = JS_LIB_OK;
      try {
        this.rdfService = jslibGetService("@mozilla.org/rdf/rdf-service;1",
                                          "nsIRDFService");
        var dsURL = "chrome://"+this.pkgName+"/content/contents.rdf";
        this.ds = this.rdfService.GetDataSourceBlocking(dsURL);
        var pID = "urn:mozilla:package:"+this.pkgName;
        this.resSelf = this.rdfService.GetResource(pID);

      } catch (e) { rv = jslibError(e); }

      return rv;
    },

    getPackageValue : function (aProperty)
    {
      var rv = "";
      try {
        var property = "http://www.mozilla.org/rdf/chrome#"+aProperty;
        var resProp = this.rdfService.GetResource(property);
        var resTarget = this.ds.GetTarget(this.resSelf, resProp, true);
        if (!resTarget) 
        {
          jslibDebug("No such registered package ["+this.pkgName+"]");
          return null;
        }
        var literal = jslibQI(resTarget, "nsIRDFLiteral");

        if (jslibInstanceOf(literal, "nsIRDFLiteral"))
          rv = literal.Value;
        
      } catch (e) { jslibError(e); }
   
    return rv;
  },

  get version ()     { return this.getPackageValue("packageVersion"); },
  get author ()      { return this.getPackageValue("author"); },
  get name ()        { return this.getPackageValue("name"); },
  get displayName () { return this.getPackageValue("displayName"); },
  get path () 
  { 
    include(jslib_fileutils);
    var fu = new FileUtils; 
    var cp = "chrome://"+this.pkgName+"/content/";
    var p = fu.chromeToPath(cp);
    return p;
  }
  
  }; // END CLASS
  
  jslibLoadMsg(JS_PACKAGEINFO_FILE);

} else { dump("Load Failure: packageInfo.js\n"); }
 
