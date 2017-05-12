if (typeof(JS_LIB_LOADED) == 'boolean') 
{
  const JS_UUID_LOADED = true;
  const JS_UUID_FILE   = 'uuid.js';

  function UUID () { } 

  UUID.prototype = 
  {
    uuidgen : function ()
    {
      var seedA = Math.random().toString(16);
      var seedB = Math.random().toString(16);
      var seedC = Math.random().toString(16);
      var seedD = Math.random().toString(16);
      var seedE = Math.random().toString(16);
      var seedF = Math.random().toString(16);

      var out   = seedA + seedB + seedC + seedD + seedE + seedF;
      out       = out.replace(/0\./g, "");
      var uuid  = "";

      var j=0;
      for (var i=0; i<out.length; i++)
      {
          uuid += out[i];
          if (j == 7 || j == 11 || j == 15 || j == 19)
              uuid += "-";
          if (i == 31)
              break;
          j++;
      }

      return uuid;
    }
  }

  jslibLoadMsg(JS_UUID_FILE);

} else { dump("Load Failure: uuid.js\n"); }
 
