if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_SYSTEM_LOADED   = true;
  const JS_SYSTEM_FILE     = "system.js";

  function System () 
  {
    if (typeof(navigator) == undefined) 
      jslibDebug("System library must be used from window a context ...");
  }

  System.prototype = 
  {
    get os ()
    {
      var np = navigator.platform;
      var ua = navigator.userAgent;
      var rv;
      if (np.indexOf("Win") == 0)
        rv = "win32";
      else if (np.indexOf("Linux") == 0)
        rv = "linux";
      else if (ua.indexOf("Mac OS X") != -1)
        rv = "macosx";
      else if (np.indexOf("Mac") != -1)
        rv = "macos";
      else
        rv = null;

      return rv;
    },

    get separator () 
    {
      var rv;
      switch (this.os)
      {
        case "win32":
          rv = "\\";
          break;

        case "linux":
        case "macosx":
          rv = "/";
          break;

        case "macos":
          rv = ":";
          break;

        default:
          rv = null;
      }

      return rv;
    },

    get platform ()
    {
      return navigator.platform;
    },

    get language ()
    {
      return navigator.language;
    },

    get cpu ()
    {
      return navigator.oscpu;
    }
  };

  jslibLoadMsg(JS_SYSTEM_FILE);

} else { dump("Load Failure: system.js\n"); }

