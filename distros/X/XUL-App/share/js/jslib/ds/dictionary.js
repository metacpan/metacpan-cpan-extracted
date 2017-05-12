if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_DICTIONARY_FILE     = "dictionary.js";
  const JS_DICTIONARY_LOADED   = true;
  
  function Parameter (k, v) {
    this.key = k;
    this.value = v;
  }
  
  Parameter.prototype = {
    key:null,
    value:null
  }
  
  // stores a set of keys and associated values
  function Dictionary () { this._array = new Array; }
  
  Dictionary.prototype =
  {
    _array: null,
    _iterind: 0,
  
    // if key exists, will replace current value with value arg
    put: function (key,value)
    {
      if ( key ==null || value == null ) return this;
  
      var ind = -1;
      for (var i = 0; i < this._array.length; i++ )
        if ( this._array[i].key == key ) {
          ind = i;
          break;
        }
  
      if (ind == -1) {
        var p = new Parameter(key,value);
        this._array.push(p);
      } else {
        this._array[ind].value = value;
      }

      return this;
    },
  
    get: function (key)
    {
      for (var i = 0; i < this._array.length; i++ )
        if (this._array[i].key == key) 
          return this._array[i].value;

      return null;
    },
  
    remove: function (key)
    {
      for (var i = 0; i < this._array.length; i++)
        if ( this._array[i].key == key )
          this._array.splice(i,1);
    },
  
    keys: function ()
    {
      var list = new Array();
      for (var i = 0; i < this._array.length; i++)
        list.push(this._array[i].key);

      return list;
    },
  
    // checks if dict has a key, and if it does, sets value to
    // the value in dict
    hasKey: function (key, value)
    {
      value = null;
      for (var i = 0; i < this._array.length; i++)
        if ( this._array[i].key == key ) {
          value = this._array[i].value;
          return true;
        }

      return false;
    },
  
    get size ()
    {
      return _array.length;
    },
  
    //object related
    toString: function ()
    {
      return "Array :" + _array.length;
    },
  
  
    // iterator related
    // iterates over each Parameter
    resetIterator: function ()
    {
      this._iterind = 0;
    },
  
    hasMoreElements: function ()
    {
      if (this._iterind < this._array.length) return true;
      else return false;
    },
  
    next: function (key, value)
    {
      return this._array[this._iterind++];
    }
  }
  
  jslibLoadMsg(JS_DICTIONARY_FILE);
  
} else { dump("Load Failure: dictionary.js\n"); }
  
