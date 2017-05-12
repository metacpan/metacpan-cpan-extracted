if(typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_DIRUTILS_FILE         = "dirUtils.js";
  const JS_DIRUTILS_LOADED       = true;
  
  const JS_DIRUTILS_FILE_DIR_CID = "@mozilla.org/file/directory_service;1";
  
  const JS_DIRUTILS_I_PROPS      = "nsIProperties";
  const JS_DIRUTILS_NSIFILE      = jslibI.nsIFile;
  
  /** 
   * /root/.mozilla/Default User/k1m30xaf.slt
   */
  const NS_APP_PREFS_50_DIR                  = "PrefD"; 
  
  /**
   * /usr/src/mozilla/dist/bin/chrome
   */
  const NS_APP_CHROME_DIR                    = "AChrom"; 
  
  /**
   * /root/.mozilla
   */
  const NS_APP_USER_PROFILES_ROOT_DIR        = "DefProfRt";  
  
  /**
   * /root/.mozilla/Default User/k1m30xaf.slt
   */
  const NS_APP_USER_PROFILE_50_DIR           = "ProfD";      
  
  /**
   * /root/.mozilla
   */
  const NS_APP_APPLICATION_REGISTRY_DIR      = "AppRegD"; 
  
  /** 
   * /root/.mozilla/appreg
   */
  const NS_APP_APPLICATION_REGISTRY_FILE     = "AppRegF"; 
  
  /** 
   * /usr/src/mozilla/dist/bin/defaults 
   */
  const NS_APP_DEFAULTS_50_DIR               = "DefRt";   
  
  /**
   * /usr/src/mozilla/dist/bin/defaults/pref
   */
  const NS_APP_PREF_DEFAULTS_50_DIR          = "PrfDef";  
  
  /**
   * /usr/src/mozilla/dist/bin/defaults/profile/US
   */
  const NS_APP_PROFILE_DEFAULTS_50_DIR       = "profDef"; 
  
  /** 
   * /usr/src/mozilla/dist/bin/defaults/profile 
   */
  const NS_APP_PROFILE_DEFAULTS_NLOC_50_DIR  = "ProfDefNoLoc"; 
  
  /** 
   * /usr/src/mozilla/dist/bin/res
   */
  const NS_APP_RES_DIR                       = "ARes"; 
  
  /** 
   * /usr/src/mozilla/dist/bin/plugins
   */
  const NS_APP_PLUGINS_DIR                   = "APlugns"; 
  
  /** 
   * /usr/src/mozilla/dist/bin/searchplugins
   */
  const NS_APP_SEARCH_DIR                    = "SrchPlugns"; 
  
  /**
   * /root/.mozilla/Default User/k1m30xaf.slt/prefs.js
   */
  const NS_APP_PREFS_50_FILE                 = "PrefF"; 
  
  /** 
   * /root/.mozilla/Default User/k1m30xaf.slt/chrome
   */
  const NS_APP_USER_CHROME_DIR               = "UChrm"; 
  
  /** 
   * /root/.mozilla/Default User/k1m30xaf.slt/localstore.rdf
   */
  const NS_APP_LOCALSTORE_50_FILE            = "LclSt"; 
  
  /** 
   * /root/.mozilla/Default User/k1m30xaf.slt/history.dat
   */
  const NS_APP_HISTORY_50_FILE               = "UHist"; 
  
  /** 
   * /root/.mozilla/Default User/k1m30xaf.slt/panels.rdf
   */
  const NS_APP_USER_PANELS_50_FILE           = "UPnls"; 
  
  /** 
   * /root/.mozilla/Default User/k1m30xaf.slt/mimeTypes.rdf
   */
  const NS_APP_USER_MIMETYPES_50_FILE        = "UMimTyp"; 
  
  /** 
   * /root/.mozilla/Default User/k1m30xaf.slt/bookmarks.html 
   */
  const NS_APP_BOOKMARKS_50_FILE             = "BMarks"; 
  
  /** 
   * /root/.mozilla/Default User/k1m30xaf.slt/search.rdf
   */
  const NS_APP_SEARCH_50_FILE                = "SrchF"; 
  
  /**
   * /root/.mozilla/Default User/k1m30xaf.slt/Mail
   */
  const NS_APP_MAIL_50_DIR                   = "MailD"; 
  
  /**
   * /root/.mozilla/Default User/k1m30xaf.slt/ImapMail
   */
  const NS_APP_IMAP_MAIL_50_DIR              = "IMapMD"; 
  
  /**
   * /root/.mozilla/Default User/k1m30xaf.slt/News
   */
  const NS_APP_NEWS_50_DIR                   = "NewsD"; 
  
  /** 
   * /root/.mozilla/Default User/k1m30xaf.slt/panacea.dat
   */
  const NS_APP_MESSENGER_FOLDER_CACHE_50_DIR = "MFCaD"; 
  
  // Useful OS System Dirs
  
  /** 
   * /usr/src/mozilla/dist/bin
   */
  const NS_OS_CURRENT_PROCESS_DIR = "CurProcD"; 
  
  const NS_OS_DESKTOP_DIR = "Desk";
  
  /** 
   * /root
   */
  const NS_OS_HOME_DIR = "Home"; 
  
  /** 
   * /tmp
   */
  const NS_OS_TEMP_DIR = "TmpD"; 
  
  /**
   * /usr/src/mozilla/dist/bin/components
   */
  const NS_XPCOM_COMPONENT_DIR = "ComsD"; 
  
  // constructor
  function DirUtils () {}
  
  DirUtils.prototype = 
  {
    useObj : false, 

    getPath : function (aAppID) 
    {
      if(!aAppID)
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
      var rv;
      try { 
        rv = jslibGetService(JS_DIRUTILS_FILE_DIR_CID, JS_DIRUTILS_I_PROPS)
               .get(aAppID, JS_DIRUTILS_NSIFILE); 
        if (this.useObj) {
          if (rv.isFile())  {
            include(jslib_file);
            rv = new File(rv.path);
          } else if (rv.isDirectory()) {
            include(jslib_dir);
            rv = new Dir(rv.path);
          }
        } else {
          rv = rv.path;
        }
      } catch (e) { rv = jslibError(e); }
    
      return rv;
    },
    
    getPrefsDir :
      function () { return this.getPath(NS_APP_PREFS_50_DIR); },

    getChromeDir :
      function () { return this.getPath(NS_APP_CHROME_DIR); },

    getMozHomeDir : 
      function () { return this.getPath(NS_APP_USER_PROFILES_ROOT_DIR); },

    getMozUserHomeDir :
      function () { return this.getPath(NS_APP_USER_PROFILE_50_DIR); },

    getAppRegDir : 
      function () { return this.getPath(NS_APP_APPLICATION_REGISTRY_FILE); },

    getAppDefaultDir : 
      function () { return this.getPath(NS_APP_DEFAULTS_50_DIR); },

    getAppDefaultPrefDir :
      function () { return this.getPath(NS_APP_PREF_DEFAULTS_50_DIR); },

    getProfileDefaultsLocDir : 
      function () { return this.getPath(NS_APP_PROFILE_DEFAULTS_50_DIR); },

    getProfileDefaultsDir :
      function () { return this.getPath(NS_APP_PROFILE_DEFAULTS_NLOC_50_DIR); },

    getAppResDir :
      function () { return this.getPath(NS_APP_RES_DIR); },

    getAppPluginsDir : 
      function () { return this.getPath(NS_APP_PLUGINS_DIR); },

    getSearchPluginsDir : 
      function () { return this.getPath(NS_APP_SEARCH_DIR); },

    getPrefsFile :  
      function () { return this.getPath(NS_APP_PREFS_50_FILE); },

    getUserChromeDir :   
      function () { return this.getPath(NS_APP_USER_CHROME_DIR); },

    getLocalStore :
      function () { return this.getPath(NS_APP_LOCALSTORE_50_FILE); },

    getHistoryFile : 
      function () { return this.getPath(NS_APP_HISTORY_50_FILE); },

    getPanelsFile :
      function () { return this.getPath(NS_APP_USER_PANELS_50_FILE); },

    getMimeTypes :
      function () { return this.getPath(NS_APP_USER_MIMETYPES_50_FILE); },

    getBookmarks : 
      function () { return this.getPath(NS_APP_BOOKMARKS_50_FILE); },

    getSearchFile : 
      function () { return this.getPath(NS_APP_SEARCH_50_FILE); },

    getUserMailDir : 
      function () { return this.getPath(NS_APP_MAIL_50_DIR); },

    getUserImapDir : 
      function () { return this.getPath(NS_APP_IMAP_MAIL_50_DIR); },

    getUserNewsDir :
      function () { return this.getPath(NS_APP_NEWS_50_DIR); },

    getMessengerFolderCache :
      function () { return this.getPath(NS_APP_MESSENGER_FOLDER_CACHE_50_DIR); },

    getCurProcDir : 
      function () { return this.getPath(NS_OS_CURRENT_PROCESS_DIR); },

    getHomeDir : 
      function () { return this.getPath(NS_OS_HOME_DIR); },

    getDesktopDir : 
      function () 
      { 
        include(jslib_system);
        var sys = new System;
        var os = sys.os;
        var key = "";
        var rv;

        if (os == "win32")
          key = "DeskP";
        else if (os == "macosx")
          key = "UsrDsk";
        else
          key = NS_OS_DESKTOP_DIR;

        rv = this.getPath(key);

        if (rv < 0)
          rv = null;

        return rv;
      },

    getTmpDir :
      function () { return this.getPath(NS_OS_TEMP_DIR); },

    getComponentsDir : 
      function () { return this.getPath(NS_XPCOM_COMPONENT_DIR); },

    get help () 
    {
      const help =
        "\n\nFunction and Attribute List:\n"    +
        "\n"                                    +
        "    getPrefsDir()\n"                   +
        "    getChromeDir()\n"                  +
        "    getMozHomeDir()\n"                 +
        "    getMozUserHomeDir()\n"             +
        "    getAppRegDir()\n"                  +
        "    getAppDefaultDir()\n"              +
        "    getAppDefaultPrefDir()\n"          +
        "    getProfileDefaultsLocDir()\n"      +
        "    getProfileDefaultsDir()\n"         +
        "    getAppResDir()\n"                  +
        "    getAppPluginsDir()\n"              +
        "    getSearchPluginsDir()\n"           +
        "    getPrefsFile()\n"                  +
        "    getUserChromeDir()\n"              +
        "    getLocalStore()\n"                 +
        "    getHistoryFile()\n"                +
        "    getPanelsFile()\n"                 +
        "    getMimeTypes()\n"                  +
        "    getBookmarks()\n"                  +
        "    getSearchFile()\n"                 +
        "    getUserMailDir()\n"                +
        "    getUserImapDir()\n"                +
        "    getUserNewsDir()\n"                +
        "    getMessengerFolderCache()\n"       +
        "    getCurProcDir()\n"                 +
        "    getHomeDir()\n"                    +
        "    getTmpDir()\n"                     +    
        "    getComponentsDir()\n\n";
    
      return help;
    }
  }; 

  jslibLoadMsg(JS_DIRUTILS_FILE);

} else { dump("Load Failure: dirUtils.js\n"); }
    
