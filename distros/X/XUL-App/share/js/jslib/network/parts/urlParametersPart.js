/*** -*- Mode: Javascript; tab-width: 2;
The contents of this file are subject to the Mozilla Public
License Version 1.1 (the "License"); you may not use this file
except in compliance with the License. You may obtain a copy of
the License at http://www.mozilla.org/MPL/
                                                                                                    
Software distributed under the License is distributed on an "AS
IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
implied. See the License for the specific language governing
rights and limitations under the License.
                                                                                                    
The Original Code is jslib code.
The Initial Developer of the Original Code is jslib team.
                                                                                                    
Portions created by jslib team are
Copyright (C) 2000 jslib team.  All
Rights Reserved.
                                                                                                    
Contributor(s): Rajeev J Sebastian <rajeev_jsv@yahoo.com)> (original author)
                                                                                                    
*************************************/


//this Part also accepts headers for the main multipart request

if (typeof(JS_LIB_LOADED)=='boolean') {

const JS_URLPARAMETERSPART_FILE     = "urlParametersPart.js";
const JS_URLPARAMETERSPART_LOADED   = true;

if (typeof(JS_DICTIONARY_LOADED)!='boolean')
  include(jslib_dictionary);

function URLParametersPart() {
  this._params = new Dictionary();
  this._headers = new Dictionary();
}

URLParametersPart.prototype = {
  _params: null,
  _headers: null,

  put: function( key, value, isHeader ) {
    if( isHeader == null ) isHeader = false;
    if( typeof(key) != "string" && typeof(value) !="string" )
      return this;
    if(isHeader) this._params.put(key,value);
    else this._headers.put(key,value);
  },

  _getRequestUriParams: function() {
    return this._params;
  },

  //not applicable
  _getRequestHeaders: function() {
    return this._headers;
  },

  //not applicable
  _getBody: function() {
    return null;
  }
}

jslibDebug('*** load: '+JS_URLPARAMETERSPART_FILE+' OK');

} // END BLOCK JS_LIB_LOADED CHECK

// If jslib base library is not loaded, dump this error.
else {
   dump("JS_BASE library not loaded:\n"
        + " \tTo load use: chrome://jslib/content/jslib.js\n"

        + " \tThen: include(jslib_urlparameterspart);\n\n");

};
