if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_SOUND_LOADED = true;
  const JS_SOUND_FILE   = "sound.js";

  function 
  Sound (aURL) { this.init(aURL); }

  Sound.prototype = 
  {
    mFile      : null,
    mURL       : null,
    mSND       : null,
    mLocalURL  : false,

    init  : function (aURL) 
    {
      if (!this.mSND) {
        try {
          const SND_I_SOUND = "nsISound";
          const SND_CID     = "@mozilla.org/sound;1";
          var Sound         = new jslibConstructor(SND_CID, SND_I_SOUND);
          this.mSND         = new Sound;
          this.mSND.init();
          jslibDebug("initializing nsISound component . . . \n");
        } catch (e) { jslibError(e); }
      }

      if (aURL) {
        try {
          jslibDebug("URL in: ["+aURL+"]\n");
          
          if (!/^file:/.test(aURL)) {
            this.mURL = jslibCreateInstance("@mozilla.org/network/standard-url;1",
                                            "nsIURL");
          } else {
            var ios = jslibGetService("@mozilla.org/network/io-service;1", 
                                      "nsIIOService");
            this.mURL = ios.newURI(aURL, null, null);
            this.mURL = jslibQI(this.mURL, "nsIFileURL");
          }
          jslibPrintMsg("mURL", this.mURL);
          this.mURL.spec = aURL;
          jslibPrintMsg("mURL.spec", this.mURL.spec);
        } catch (e) { jslibError(e); }
      }
    },

    play  : function () 
    {
      if (!this.mURL)
        jslibDebug("Please initialize with a file or url\n");

      try {
        jslibDebug("Playing ["+this.mURL.scheme+"] Sound File: ["+this.mURL.spec+"]\n");
        this.mSND.play(this.mURL);
      } catch (e) { jslibError(e); }
    },

    beep  : function () 
    {
      try { this.mSND.beep(); } 
      catch (e) { jslibError(e); }
    }
  }

  jslibLoadMsg(JS_SOUND_FILE);

} else { dump("Load Failure: sound.js\n"); }

