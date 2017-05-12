if (typeof(JS_LIB_LOADED) == 'boolean') 
{
  const JS_PREFS_LOADED   = true;
  const JS_PREFS_FILE     = 'prefs.js';
  const JS_PREFS_CID      = "@mozilla.org/preferences;1";
  const JS_PREFS_I_PREF   = "nsIPref";

  /*********** PREFS *******************/
  function Prefs () 
  {
    try {
      // create instance of prefs xpcom object
      this.prefInst = jslibCreateInstance(JS_PREFS_CID, JS_PREFS_I_PREF);
      this.prefInst = jslibQI(this.prefInst, "nsIPrefBranch");
    } catch (e) { jslibError(e); }

    // support nsIPref method names
    this.addMethods();
  }

  Prefs.prototype = 
  {
    prefInst       : null,
    getPrefType    : null,
    getBoolPref    : null,
    setBoolPref    : null,
    setCharPref    : null,
    getCharPref    : null,
    setIntPref     : null,
    getIntPref     : null,
    ResetPrefs     : null,
    ResetUserPrefs : null,
    savePrefFile   : null,
    ClearUserPref  : null,

    /*********** GET Type ****************/
    // pref type
    getType : function (aPrefString) 
    {
      var rv = undefined;
      try {
        rv = this.prefInst.GetPrefType(aPrefString)
      } catch (e) { jslibError(e); }

      return rv;
    },
  
    /*********** SET BOOL ****************/
    setBool : function (aPrefString, aInBool) 
    {
      if (!aPrefString)
        return false;
  
      var rv = JS_LIB_OK;
      try {
        this.prefInst.SetBoolPref(aPrefString, aInBool)
      } catch(e) { rv = jslibError(e); }
  
      return rv;
    },
  
    /*********** GET BOOL ****************/
    getBool : function (aPrefString) 
    {
      var rv = false;

      if (!aPrefString)
        return rv;
  
      try {
        rv = this.prefInst.GetBoolPref(aPrefString)
      } catch (e) { }
  
      return rv;
    }, 
  
    /*********** SET CHAR PREF ***********/
    setChar : function (aPrefName, aPrefString) 
    {
      if (!aPrefName && !aPrefString)
        return jslibErrorMsg("NS_ERROR_XPC_NOT_ENOUGH_ARGS");
  
      var rv = JS_LIB_OK;
      try {
        this.prefInst.SetCharPref(aPrefName, aPrefString)
      } catch (e) { rv = jslibError(e); }
  
      return rv;
    },
  
    /*********** GET CHAR PREF ***********/
    getChar : function (aPrefName) 
    {
      if (!aPrefName)
        return jslibErrorMsg("NS_ERROR_XPC_NOT_ENOUGH_ARGS");
  
      var rv = "";
      try {
        rv = this.prefInst.GetCharPref(aPrefName)
      } catch(e) { }
  
      return rv;
    },
  
    /*********** SET INT PREF ***********/
    setInt : function (aPrefName, aInt) 
    {
      if (!aPrefName && !aInt)
        return jslibErrorMsg("NS_ERROR_XPC_NOT_ENOUGH_ARGS");
  
      var rv = JS_LIB_OK;
      try {
        this.prefInst.SetIntPref(aPrefName, aInt)
      } catch(e) { rv = jslibError(e); }
  
      return rv;
    },
  
    /*********** GET INT PREF ***********/
    getInt : function (aPrefName) 
    {
      if (!aPrefName)
        return jslibErrorMsg("NS_ERROR_XPC_NOT_ENOUGH_ARGS");
  
      var rv;
      try {
        rv = this.prefInst.GetIntPref(aPrefName)
      } catch(e) { rv = -jslibRes.NS_ERROR_FAILURE; }
  
      return rv;
    },
  
    /*********** RESET PREF *************/
    reset : function () 
    {
      var rv = JS_LIB_OK;
      try {
        this.prefInst.ResetPrefs();
      } catch(e) { rv = jslibError(e); }
  
      return rv;
    },
  
    /*********** RESET USER PREF ********/
    resetUser : function () 
    {
      var rv = JS_LIB_OK;
      try {
        this.prefInst.ResetUserPrefs();
      } catch(e) { rv = jslibError(e); }
  
      return rv;
    },
  
    /*********** SAVE PREF **************/
    save : function (aFile) 
    {
      var file;
      switch (typeof(aFile)) 
      {
        case "object":
          // check object is an nsIFile object
          if (typeof(aFile.path) == "string")
          file = aFile;
          break;
  
        case "string":
          include (jslib_file);
          // path is a string, make it into an nsIFile
          file = (new File(aFile)).nsIFile;
          break;
      }
  
      var rv = JS_LIB_OK;
      try {
        this.prefInst.savePrefFile(file);
      } catch(e) { rv = jslibError(e); }
  
      return rv;
    },
  
    /*********** CLEAR USER PREF ********/
    clear : function (aPrefString) 
    {
      var rv = JS_LIB_OK;
      try {
        this.prefInst.ClearUserPref(aPrefString);
      } catch(e) { rv = jslibError(e); }
  
      return rv;
    },
  
    /*********** GET NSIPREF ********/
    get nsIPref () { return this.prefInst; },

    /*********** SUPPORT NSIPREF METHODS ********/
    addMethods : function ()
    {
      this.getPrefType    = this.getType;
      this.setBoolPref    = this.setBool;
      this.getBoolPref    = this.getBool;
      this.setCharPref    = this.setChar;
      this.getCharPref    = this.getChar;
      this.setIntPref     = this.setInt;
      this.getIntPref     = this.getInt;
      this.ResetPrefs     = this.reset;
      this.ResetUserPrefs = this.resetUser;
      this.savePrefFile   = this.save;
      this.ClearUserPref  = this.clear;
    }
  
  }; // END CLASS
  
  jslibLoadMsg(JS_PREFS_FILE);

} else { dump("Load Failure: prefs.js\n"); }
  
