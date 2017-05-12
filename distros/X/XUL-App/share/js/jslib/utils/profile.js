if (typeof(JS_LIB_LOADED) == 'boolean') 
{
  const JS_PROFILE_LOADED = true;
  const JS_PROFILE_FILE   = 'profile.js';

  function Profile () 
  { 
    this.mProfile = jslibGetService("@mozilla.org/profile/manager;1",
                                      "nsIProfile");
    if (!this.mProfile) 
      jslibDebug("failed to get profile manager ...");
  }

  Profile.prototype = 
  {
    mProfile : null,

    get currentProfile () 
    {
      if (!this.mProfile) {
        include(jslib_dirutils);
        var du = new DirUtils;
        var mh = du.getMozUserHomeDir();
        return mh.substring(mh.lastIndexOf(".")+1, mh.length);
      }

      return this.mProfile.currentProfile;
    },
    
    get profileCount ()
    {
      if (!this.mProfile)
        return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");

      return this.mProfile.profileCount;
    },

    getProfileList : function (aName)
    {
      if (!this.mProfile)
        return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");

      var rv = "";
      try {
        rv = this.mProfile.getProfileList({}, {});
      } catch (e) { jslibError(e); }

      return rv;
    },
    
    profileExists : function (aName)
    {
      if (!this.mProfile)
        return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");

      if (!aName)
        return jslibErrorMsg("NS_ERROR_XPC_NOT_ENOUGH_ARGS");

      return this.mProfile.profileExists(aName);
    },
    
    deleteProfile : function (aName, aCanDeleteFiles)
    {
      if (!this.mProfile)
        return jslibErrorMsg("NS_ERROR_NOT_INITIALIZED");

      if (!aName)
        return jslibErrorMsg("NS_ERROR_XPC_NOT_ENOUGH_ARGS");

      if (!this.profileExists(aName))
        return jslibErrorMsg("NS_ERROR_NOT_AVAILABLE");

      var rv = JS_LIB_OK;
      try { this.mProfile.deleteProfile(aName, aCanDeleteFiles); } 
      catch (e) { rv = jslibError(e); }

      return rv;
    }

  }; // END CLASS
  
  jslibLoadMsg(JS_PROFILE_FILE);

} else { dump("load FAILURE: profile.js\n"); }
 
