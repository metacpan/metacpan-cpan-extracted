if (typeof(JS_LIB_LOADED)=='boolean') 
{
  include(jslib_ds_dictionary);

  const JS_CHAINDICTIONARY_FILE     = "chainDictionary.js";
  const JS_CHAINDICTIONARY_LOADED   = true;
  
  
  function ChainDictionary ()
  {
    this._default = new Dictionary();
    this._chained = new Array();
    this.put(_default); //add the default to the chain as well
  }
  
  ChainDictionary.prototype =
  {
    _default: null,
    _chained: null,
  
    //iterator related
    _chainind: null,
  
    // if key exists, will replace current value with value arg
    put: function (key,value)
    {
      if (key == null || value == null) return this;
  
      for (var i = 0; i < this._chained.size(); i++)
      {
        if (this._chained.hasKey(key)) {
          this._chained[i].put(key, value);
          dictind = i;
          break;
        }
      }
      if (dictind == -1)
        this._default.put(key, value);
      
      return this;
    },
  
    put: function (dictionary)
    {
      if (dictionary == null) return this;
  
      this._chained.push(dictionary);

      return this;
    },
  
    get: function (key)
    {
      for (var i = 0; i < this._chained.size(); i++)
      {
        var value = this._chained[i].get(key);
        if (value) return value;
      }

      return null;
    },
  
    remove: function (key)
    {
      for (var i = 0; i < this._chained.size(); i++)
        remove(key);
    },
  
    keys: function ()
    {
      var list = new Array;
      for (var i = 0; i < this._chained.length; i++)
        list.concat(this._chained.keys());
  
      return list;
    },
  
    toString: function ()
    {
      var size;
      for (var i = 0; i < this._chained.length; i++)
        size += this._chained.size();
  
      return "Array :" + size;
    },
  
    get size ()
    {
      var size;
      for (var i = 0; i < this._chained.length; i++)
        size += this._chained.size();
  
      return size;
    },
  
    // iterator
    // iterates over each Parameter
    resetIterator: function ()
    {
      this._chainind = 0;
      for (var i = 0; i < this._chained.length; i++)
        this._chained[i].resetIterator();
    },
  
    hasMoreElements: function ()
    {
      // if there are more dicts after the current in the chain
      if (this._chainind < this._chained.length -1)
        return true;
      // if there are more elements in the current dict
      else return this._chained[_chainind].hasMoreElements();
    },
  
    next: function ()
    {
      if (!this._chained[_chainind].hasMoreElements())
        this._chainind++;

      return this._chained[_chainin].getNext();
    }
  }

  jslibLoadMsg(JS_CHAINDICTIONARY_FILE);

} else { dump("Load Failure: chainDictionary.js\n"); }

