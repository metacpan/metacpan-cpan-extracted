if (typeof(JS_LIB_LOADED)=='boolean')
{
  const JS_XPCOM_LOADED   = true;
  const JS_XPCOM_FILE     = 'xpcom.js';

  function 
  getClassIDFromInterface (aInterface)
  {
    var C     = Components;
    var c     = C.classes;
    var list;
  
    try {
      for (list in c)
        if (typeof(C.Constructor(list, aInterface))=='function')
          return list;
    } catch (e){ jslibError(e); }
  
    return jslibErrorMsg("NS_ERROR_NOT_IMPLEMENTED");
  }
  
  function 
  getProgIDFromInterface (aInterface)
  {
    return jslibErrorMsg("NS_ERROR_NOT_IMPLEMENTED");
  }
  
  /****************************************************************
  * getClassIDFromProgID(aProgID)                                 *       
  *                                                               *
  * aProgID is an argument of string ProgID (human readable name) *
  * returns string CID on success, null on failure                *
  *   Ex:                                                         *
  *     var progID='@mozilla.org/file/local;1';                   *
  *   getClassIDFromProgID(progID);                               *
  *                                                               *
  *   outputs: {2e23e220-60be-11d3-8c4a-000064657374}             *
  ****************************************************************/
  
  function 
  getClassIDFromProgID (aProgID)
  {
    var rv = null;
  
    if (!aProgID)
      return jslibErrorMsg("NS_ERROR_XPC_NOT_ENOUGH_ARGS");
  
    if (jslibTypeIsUndef(Components.classes[aProgID]))
  		return jslibErrorMsg("NS_ERROR_INVALID_ARG");
    
    if (Components.classes[aProgID].valid)
      rv = Components.classes[aProgID].number;
  
    return rv;
  }
  
  /****************************************************************
  * getProgIDFromCID(aCID)                                        *       
  *                                                               *
  * aCID is an argument of string CID Class ID                    *
  * returns string ProgID on success, null on failure             *
  *   Ex:                                                         *
  *       var cid='{2e23e220-60be-11d3-8c4a-000064657374}';       *
  *       getClassIDFromProgID(cid);                              *
  *                                                               *
  *   outputs: @mozilla.org/file/local;1                          *
  ****************************************************************/
  
  function 
  getProgIDFromCID (aCID)
  {
    var rv  = null;
    var C   = Components;
    var c   = C.classes;
    var cid = C.classesByID;
    var res = {};
  
    if (!aCID)
      return jslibErrorMsg("NS_ERROR_INVALID_ARG");
  
    try {
      if (jslibTypeIsUndef(C.ID(aCID)))
        rv = null;
  
  		/*** CLSIDToContractID is no longer available 
      else
        if (C.ID(aCID).valid)
          rv = C.manager.CLSIDToContractID(Components.ID(aCID), res); 
  		****/
    } catch (e){ rv = null; }
  
    try {
      if (typeof(cid[aCID])=="undefined")
        return jslibErrorMsg("NS_ERROR_INVALID_ARG");
  
      if (!rv)
        for (list in c)
          if (typeof(c[list])!="undefined")
            if (cid[aCID].equals(c[list])) {
              rv=list;
              break;
            }
    } catch (e){ rv = null; }
  
    return rv;
  }
  
  /****************************************************************
  * getInterfaceFromProgID(aProgID)                               *
  *                                                               *
  * aProgID is an argument of string ProgID (human readable name) *
  * returns an array of interfaces on success, null on failure    *
  *   Ex:                                                         *
  *       var progID='@mozilla.org/file/local;1';                 *
  *       getInterfaceFromProgID(progID);                         *
  *                                                               *
  *   outputs: nsILocalFile,nsIFile                               *
  ****************************************************************/
  
  function 
  getInterfaceFromProgID (aProgID)
  {
  
    var C     = Components;
    var c     = jslibCls;
    var res   = new Array;
    var list;
    var inst;
  
    if (!aProgID)
      return jslibErrorMsg("NS_ERROR_XPC_NOT_ENOUGH_ARGS");
    
    if (jslibTypeIsUndef(c[aProgID]))
      return jslibErrorMsg("NS_ERROR_INVALID_ARG");
  
    inst = c[aProgID].getService();
  
    for (list in jslibI)
    {
      try
      {
        if (!jslibTypeIsUndef(jslibI[list]))
          if (jslibTypeIsObj(jslibI[list]) && list != "nsISupports")
            res.push(list);
      } catch (e) {}
    }
  
    return (res !="" ? res : null);
  }
  
  /****************************************************************
  * getInterfaceFromCID(aCID)                                     *
  *                                                               *
  * aCID is an argument of string CID Class ID                    *
  * returns array of interfaces on success, null on failure       *
  *   Ex:                                                         *
  *       var cid='{2e23e220-60be-11d3-8c4a-000064657374}';       *
  *       getInterfaceFromCID(cid);                               *
  *                                                               *
  *   outputs: nsILocalFile,nsIFile                               *
  ****************************************************************/
  
  function 
  getInterfaceFromCID (aCID)
  {
    var p;
  
    if (!aCID)
      return jslibErrorMsg("NS_ERROR_XPC_NOT_ENOUGH_ARGS");
  
    p = getProgIDFromCID(aCID);
  
    return (typeof(p)!='undefined' ? getInterfaceFromProgID(p) : null);
  }
  
  function xpcMap(){ return jslibErrorMsg("NS_ERROR_NOT_IMPLEMENTED"); }
  
  /****************************************************************
  * lookUpError(aErrorNum)                                        *
  *                                                               *
  * aErrorNum is an argument of Components.results int            *
  * returns string name of error on success, null on failure      *
  *   Ex:                                                         *
  *       var errNum=2147500033;                                  *
  *       lookUpError(errNum);                                    *
  *                                                               *
  *   outputs: NS_ERROR_NOT_IMPLEMENTED                           *
  ****************************************************************/
  
  function 
  lookUpError (aErrorNum) 
  {
    var r   = Components.results;
    var rv  = null;
  
    for (var list in r)
      if (aErrorNum==r[list])
        rv=list;
  
    return rv;
  }
  
  jslibLoadMsg(JS_XPCOM_FILE);
    
} else { dump("Load Failure: xpcom.js\n"); }


  function 
  getIDFromInterface (aInterface) 
  {
    var rv = null;
    for (var list in Components.interfacesByID)
    if (Components.interfacesByID[list] == aInterface)
      rv = list;

    return rv;
  }
  
