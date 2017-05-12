const JSLIB_CONTAINER_PROGID = '@mozilla.org/rdf/container;1';
const JSLIB_CONTAINER_UTILS_PROGID = '@mozilla.org/rdf/container-utils;1';
const JSLIB_LOCATOR_PROGID = '@mozilla.org/filelocator;1';
const JSLIB_RDF_PROGID = '@mozilla.org/rdf/rdf-service;1';
const JSLIB_RDF_DS_PROGID = '@mozilla.org/rdf/datasource;1?name=xml-datasource';

const JSLIB_RDF_FLAG_SYNC = 1;        // load RDF source synchronously
const JSLIB_RDF_FLAG_DONT_CREATE = 2; // don't create RDF file (RDFFile only)

function RDF(src, root, nc, flags) {
  this.RDF = Components.classes[JSLIB_RDF_PROGID].getService();
  this.RDF = this.RDF.QueryInterface(Components.interfaces.nsIRDFService);
  this.RDFC = Components.classes[JSLIB_CONTAINER_PROGID].getService();
  this.RDFC = this.RDFC.QueryInterface(Components.interfaces.nsIRDFContainer);
  this.RDFCUtils = Components.classes[JSLIB_CONTAINER_UTILS_PROGID].getService();
  this.RDFCUtils = this.RDFCUtils.QueryInterface(Components.interfaces.nsIRDFContainerUtils);

  if(src) {
    this._init(src, root, nc, flags);
  }
}

RDF.prototype = {
  RDF        : null,
  RDFC       : null,
  RDFCUtils  : null,
  src        : null,
  root       : null,
  nc         : null,
  dsource    : null,
  loaded     : false,
  
  _init : function(src, node, nc, flags) {
    flags = flags || 0;
    this.src = src;
    this.root = node;
    this.nc = nc;

    load = true; // load source

    // Create an RDF/XML datasource using the XPCOM Component Manager
    var ds = Components
             .classes[JSLIB_RDF_DS_PROGID]
             .createInstance(Components.interfaces.nsIRDFDataSource);

    // The nsIRDFRemoteDataSource interface has the interfaces
    // that we need to setup the datasource.
    var remote = ds.QueryInterface(Components.interfaces.nsIRDFRemoteDataSource);

    try {
      remote.Init(src); // throws an exception if URL already in use
    }
    catch(err) {
      // loading already
      load = false;
    }

    if (load) {
      try {
        remote.Refresh((flags & JSLIB_RDF_FLAG_SYNC) ? true: false);
      }
      catch(err) {
        dump(err);
        return;
      }
    }
    else {
      ds = this.RDF.GetDataSource(src);
      remote = ds.QueryInterface(Components.interfaces.nsIRDFRemoteDataSource);
    }

    try {
      if (remote.loaded) {
        this.loaded = true;
      }
      else {
        var obs = {
          rdf: this, // backreference to ourselves

          onBeginLoad: function(aSink)
          {},

          onInterrupt: function(aSink)
          {},

          onResume: function(aSink)
          {},

          onEndLoad: function(aSink)
          {
             this.rdf.loaded = true;
          },

          onError: function(aSink, aStatus, aErrorMsg)
          {
            dump(aErrorMsg);
          }
        };

        // RDF/XML Datasources are all nsIRDFXMLSinks
        var sink = ds.QueryInterface(Components.interfaces.nsIRDFXMLSink);
  
        // Attach the observer to the datasource-as-sink
        sink.addXMLSinkObserver(obs);
      }
    }
    catch(err) {
      dump(err);
      return;
    }

    this.dsource = ds;
  },

  _getRealNode : function(aNode) {
    var node;
    if(!aNode) {
      node = this.root+":data";
    } else {
      if(aNode.indexOf(this.root+":") == -1) {
        node = this.root+":"+aNode;
      } else {
        return aNode;
      }
    }
    return node;
  },

  addSeq : function(aSeq)
  {
    if(!aSeq) throw("addSeq must supply an argument");
    if(aSeq == this.root+":data") throw("Cannot create root Seq");

    var realnode = this._getRealNode(aSeq);
    var res = this.RDF.GetResource(realnode);

    var pos = realnode.lastIndexOf(":");
    var parent = realnode.slice(0, pos);
    if(parent == this.root) {
      parent = parent+":data";
    }

    var parentres = this.RDF.GetResource(parent);
    if( parentres) {
      this.RDFC.Init(this.dsource, parentres);

      this.RDFCUtils.MakeSeq(this.dsource, res);
      this.RDFC.AppendElement(res);
    }
  },

  removeSeq : function(aSeq, deep)
  {
    if(aSeq == this.root+":data") throw("Cannot remove root Seq");
    var realnode = this._getRealNode(aSeq);
    var res = this.RDF.GetResource(realnode);

    if(this.RDFCUtils.IsSeq(this.dsource, res)) {
      if(deep) {
        this._deleteSeqRecursively(res);
      }
      this.removeNode(aSeq);
    } else {
      throw("Trying to remove a Seq when it's a node");
    }
  },

  _deleteSeqRecursively : function(res) 
  {
    this.RDFC.Init(this.dsource, res);

    var elems = this.RDFC.GetElements();
    while(elems.hasMoreElements()) {
      var elem = elems.getNext();
      if(this.RDFCUtils.IsSeq(this.dsource, elem)) {
        this._deleteSeqRecursively(elem);
        this.RDFC.Init(this.dsource, res);
      }
      var arcs = this.dsource.ArcLabelsOut(elem);
      while(arcs.hasMoreElements()) {
        var arc = arcs.getNext();
        var targets = this.dsource.GetTargets(elem, arc, true);
        while (targets.hasMoreElements()) {
          var target = targets.getNext();
          this.dsource.Unassert(elem, arc, target, true);
        }
      }
      this.RDFC.RemoveElement(elem, false);
    }
  },

  isSeq : function(aSeq)
  {
    var realnode = this._getRealNode(aSeq);
    var res = this.RDF.GetResource(realnode);
    if(res && this.RDFCUtils.IsSeq(this.dsource, res)) {
      return true;
    } else {
      return false;
    }
  },

  doesSeqExist : function(aSeq)
  {
    return this.doesNodeExist(aSeq);
  },

  getSeqSubNodes : function(aSeq)
  {
    var realnode = this._getRealNode(aSeq);
    var list = new Array;

    var res = this.RDF.GetResource(realnode);
    this.RDFC.Init(this.dsource, res);

    var elems = this.RDFC.GetElements();
    while(elems.hasMoreElements()) {
      var elem = elems.getNext();
      elem = elem.QueryInterface(Components.interfaces.nsIRDFResource);
      if(!this.RDFCUtils.IsSeq(this.dsource, elem)) {
        list.push(elem.Value);
      }
    }
    return list;
  },

  getSeqSubSeqs : function(aSeq)
  {
    var realnode = this._getRealNode(aSeq);
    var list = new Array;

    var res = this.RDF.GetResource(realnode);
    this.RDFC.Init(this.dsource, res);

    var elems = this.RDFC.GetElements();
    while(elems.hasMoreElements()) {
      var elem = elems.getNext();
      elem = elem.QueryInterface(Components.interfaces.nsIRDFResource);
      if(this.RDFCUtils.IsSeq(this.dsource, elem)) {
        list.push(elem.Value);
      }
    }
    return list;
  },

  addNode : function(aNode)
  {
    var realnode = this._getRealNode(aNode);
    if(realnode == this.root+":data") throw("Cannot add root Seq");

    var pos = realnode.lastIndexOf(":");
    var parent = realnode.slice(0, pos);
    if(parent == this.root) {
      parent = parent+":data";
    }

    var res = this.RDF.GetResource(realnode);
    var parentres = this.RDF.GetResource(parent);
    if(parentres) {
      this.RDFC.Init(this.dsource, parentres);
      this.RDFC.AppendElement(res);
    }
  },

  removeNode : function(aNode)
  {
    var realnode = this._getRealNode(aNode);
    var res = this.RDF.GetResource(realnode);
    var root = this.RDF.GetResource(this.root+":data");

    var pos = realnode.lastIndexOf(":");
    var parent = realnode.slice(0, pos);
    if(parent == this.root) {
      parent = parent+":data";
    }
    var parentres = this.RDF.GetResource(parent);

    this.RDFC.Init(this.dsource, parentres);

    var arcs = this.dsource.ArcLabelsOut(res);
    while(arcs.hasMoreElements()) {
      var arc = arcs.getNext();
      var targets = this.dsource.GetTargets(res, arc, true);
      while (targets.hasMoreElements()) {
        var target = targets.getNext();
        this.dsource.Unassert(res, arc, target, true);
      }
    }
    this.RDFC.RemoveElement(res, false);
  },

  isNode : function(aNode)
  {
    var realnode = this._getRealNode(aNode);
    var res = this.RDF.GetResource(realnode);
    if(res && !(this.RDFCUtils.IsSeq(this.dsource, res)) ) {
      return true;
    } else {
      return false;
    }
  },

  doesNodeExist : function(aNode)
  {
    var realnode = this._getRealNode(aNode);
    var rv = false;

    var res = this.RDF.GetResource(realnode);
    var pos = realnode.lastIndexOf(":");
    var parent = realnode.slice(0, pos);
    if(parent == this.root) {
      parent = parent+":data";
    }

    if(parent) {
      var parentres = this.RDF.GetResource(parent);
      this.RDFC.Init(this.dsource, parentres);

      var index = this.RDFC.IndexOf(res.QueryInterface(Components.interfaces.nsIRDFNode));
      if(index != -1) {
        rv = true;
      }
    }
    return rv;
  },

  setAttribute : function(aNode, name, value)
  {
    var realnode = this._getRealNode(aNode);
    var newnode = this.RDF.GetResource(realnode);
    var oldvalue = this.getAttribute(realnode, name);

    if(newnode) {
      // Add an assertion to the RDF datasource for each property of the resource
      if(oldvalue) { 
        this.dsource.Change(newnode,
            this.RDF.GetResource(this.nc + name),
            this.RDF.GetLiteral(oldvalue),
            this.RDF.GetLiteral(value) );
      } else {
        this.dsource.Assert(newnode,
            this.RDF.GetResource(this.nc + name),
            this.RDF.GetLiteral(value),
            true );
      }
    }
  },

  getAttribute : function(aNode, name)
  {
    var realnode = this._getRealNode(aNode);

    var itemRes = this.RDF.GetResource(this.nc + name);
    if (!itemRes) return null;

    var IDRes = this.RDF.GetResource(realnode);
    if (!IDRes) return null;
        
    var thisNode = this.dsource.GetTarget(IDRes, itemRes, true);
    if (thisNode) thisNode = thisNode.QueryInterface(Components.interfaces.nsIRDFLiteral);
    if (thisNode)
    {
      return thisNode.Value;
    }
    return null;
  },

  removeAttribute : function(aNode, name)
  {
    var realnode = this._getRealNode(aNode);

    var src = this.RDF.GetResource(realnode);
    if(src) {
      var prop = this.RDF.GetResource(this.nc + name, true);
      var target = this.dsource.GetTarget(src, prop, true);
      this.dsource.Unassert(src, prop, target);
    }
  },

  doesAttributeExist : function(aNode, name)
  {
    var value = this.getAttribute(aNode, name);
    if(value) {
      return true;
    }
    return false;
  },

  getDatasource : function() 
  {
    return this.dsource;
  },

  flush : function()
  {
    this.dsource.QueryInterface(Components.interfaces.nsIRDFRemoteDataSource).Flush();
  }

};

/*
------------------
*/

function RDFFile(path, root, nc, flags) {
  this.created = false;

  if(path) {
    this._file_init(path, root, nc);
  }
}
RDFFile.prototype = new RDF;

RDFFile.prototype._file_init = function (path, root, nc, flags) {
  flags = flags || JSLIB_RDF_FLAG_SYNC; // default to synchronous loading

  var file = path;

  if(path.substr(0,7) != "file://")
    file = "file://" + path;
  else
    path = path.substr(7);

  // Ensure we have a base RDF file to work with
  var rdf_file = new File(path);

  if (!rdf_file.exists() && !(flags & JSLIB_RDF_FLAG_DONT_CREATE)) {
    if (rdf_file.open("w") != JS_LIB_OK) {
      return;
    }

    if (rdf_file.write(
               '<?xml version="1.0" ?>\n' +
               '<RDF:RDF\n' +
               '     xmlns:SIMPLE="' + nc + '"\n' +
               '     xmlns:RDF="http://www.w3.org/1999/02/22-rdf-syntax-ns#">\n' +
               '  <RDF:Seq about="' + root + ':data">\n' +
               '  </RDF:Seq>\n' +
               '</RDF:RDF>\n') != JS_LIB_OK) {
      rdf_file.close();
      return;
    }

    this.created = true;
  }
  rdf_file.close();

  // Get a reference to the available datasources
  this._init(file, root, nc, flags);
};
