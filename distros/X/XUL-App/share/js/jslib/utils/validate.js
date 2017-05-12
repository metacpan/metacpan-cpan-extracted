// I think this shouldgo into xpcom.js
if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_VALIDATE_LOADED   = true;
  const JS_VALIDATE_FILE     = 'validate.js';
  
  function printClassMatch (aToken) 
  {
    if (!aToken)
      return;
    var pat = new RegExp (aToken, "i");
    for (var list in C.classes)
      if (list.match(pat))
        jslibPrint(list);
  
    return;
  }
  
  function printInterfaceMatch (aToken) {
    if (!aToken)
      return;
    var pat = new RegExp (aToken, "i");
    for (var list in C.interfaces)
      if (list.match(pat))
        jslibPrint(list);
  
    return;
  }
  
  jslibLoadMsg(JS_VALIDATE_FILE);
  
} else { dump("load FAILURE: validate.js\n"); }

