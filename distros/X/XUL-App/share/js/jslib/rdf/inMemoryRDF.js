if (typeof(JS_LIB_LOADED)=='boolean') 
{
  const JS_INMEMORYRDF_LOADED = true;
  const JS_INMEMORYRDF_FILE   = "inMemoryRDF.js";
  const JSLIB_INMEM_CONTAINER_PROGID = '@mozilla.org/rdf/container;1';
  const JSLIB_INMEM_CONTAINER_UTILS_PROGID = '@mozilla.org/rdf/container-utils;1';
  const JSLIB_INMEM_RDF_PROGID = '@mozilla.org/rdf/rdf-service;1';
  const JSLIB_INMEM_RDF_MEM_PROGID = '@mozilla.org/rdf/datasource;1?name=in-memory-datasource';
  
  const JSLIB_INMEM_TYPE_BAG = 1;
  const JSLIB_INMEM_TYPE_ALT = 2;
  const JSLIB_INMEM_TYPE_SEQ = 3;
  const JSLIB_INMEM_TYPE_NODE = 4;
  
  function inMemRDF(root, xmlns) {
    this.RDF = jslibGetService(JSLIB_INMEM_RDF_PROGID, "nsIRDFService");
    this.RDFC = jslibGetService(JSLIB_INMEM_CONTAINER_PROGID, "nsIRDFContainer");
    this.RDFCUtils = jslibGetService(JSLIB_INMEM_CONTAINER_UTILS_PROGID, "nsIRDFContainerUtils");
    this.init(root,xmlns);
  }
  
  inMemRDF.prototype = {
   root       : null, // (public)
   xmlns      : null, // (public) 'list' is appended to this value to make the top container
   RDF        : null, // (private)
   RDFC       : null, // (private)
   RDFCUtils  : null, // (private)
   dsource    : null, // (private)
   debug      : 0,    // (private) see setDebug
  
    // -----------------------------------------------------------------------------------------
    init : function (root,xmlns) {
      this.root = root;
      this.xmlns = xmlns;
  
      // Create an the in-memory XPconnect object.
      // when this statement is 'createInstance', the 'Delete' method fails.
      //this.dsource = jslibCreateInstance(JSLIB_INMEM_RDF_MEM_PROGID, "nsIRDFDataSource");
      this.dsource = jslibGetService(JSLIB_INMEM_RDF_MEM_PROGID, "nsIRDFDataSource");
  
      this.dsource.Assert(
         this.RDF.GetResource(this.root),
         this.RDF.GetResource(this.xmlns+'list'),
         this.RDF.GetResource(this.root+":seq"),
         true);
  
      this.RDFCUtils.MakeSeq(this.dsource, this.RDF.GetResource(this.root+":seq"));
  
      this.RDFC.Init(this.dsource,this.RDF.GetResource(this.root+":seq"));
  
    },
  
    // -----------------------------------------------------------------------------------------
    addSeq : function (aSeq) {
      this._debug('addSeq: START. aSeq='+aSeq);
      var realnode = this._getRealNode(aSeq);
      var err = null;
      if (!realnode) err = "inmemoryrdf.js: addSeq: must supply a value for 'aSeq'";
      if (realnode == this.root || realnode == this.root+':seq') err="inmemoryrdf.js: addSeq: cannot create a sequence the same name as the root sequence.";
      if (realnode.lastIndexOf(":") == (realnode.length-1) ) err="inmemoryrdf.js: addSeq: sequence names cannot end in ':'";
  
      if (!err) {
       var res = this.RDF.GetResource(realnode);
  
       var pos = realnode.lastIndexOf(":");
       var parent = realnode.slice(0, pos);
       
       var parentres = this.RDF.GetResource(parent);
       this._debug("addSeq: aSeq='"+aSeq+"' realnode='"+realnode+"' parent='"+parent+"'");
       if (parentres) {
         this.RDFCUtils.MakeSeq(this.dsource, res);
         if ( parent != this.root ) this.RDFC.Init(this.dsource, parentres);
         this.RDFC.AppendElement(res);
       }
      }
      this._debug('addSeq: DONE. ---------------------------------------------');
      if (err)throw(err);
      return(realnode);
  
    },
  
    // -----------------------------------------------------------------------------------------
    removeSeq : function (aSeq, deep) {
      if (aSeq == this.root) throw("Cannot remove root Seq");
      this._debug('removeSeq: START. aSeq='+aSeq+' deep='+deep);
      var realnode = this._getRealNode(aSeq);
      var res = this.RDF.GetResource(realnode);
      var err = null;
  
      if (this.RDFCUtils.IsSeq(this.dsource, res)) {
        if (deep) {
          this._deleteRecursive(res);
        }
        this.removeNode(aSeq);
      } else {
        this._debug('removeSeq: cannot remove aSeq='+aSeq+', it is a node!');
        err = "inmemoryrdf.js: removeSeq: Trying to remove a Seq: '"+aSeq+"', when it's a node is an error.";
      }
      this._debug('removeSeq: DONE. ---------------------------------------------');
      if (err)throw(err);
    },
  
    // -----------------------------------------------------------------------------------------
    isSeq : function (aSeq) {
      this._debug('isSeq: START. aSeq='+aSeq);
      var realnode = this._getRealNode(aSeq);
      var res = this.RDF.GetResource(realnode);
      var result=false;
      if (res && this.RDFCUtils.IsSeq(this.dsource, res)) result=true;
      this._debug('isSeq: result is: '+result);
      this._debug('isSeq: DONE. ---------------------------------------------');
    },
  
    // -----------------------------------------------------------------------------------------
    getSeqSubNodes : function (aSeq) {
      this._debug('getSeqSubNodes: START. aSeq='+aSeq);
      var realnode = this._getRealNode(aSeq);
      var list = new Array;
  
      var res = this.RDF.GetResource(realnode);
  
      if ( aSeq != this.root ) this.RDFC.Init(this.dsource, res);
  
      this._debug('getSeqSubNodes: realnode='+realnode);
  
      var elems = this.RDFC.GetElements();
      while (elems.hasMoreElements()) {
        var elem = elems.getNext();
        elem = jslibQI(elem, "nsIRDFResource");
        if (!this.RDFCUtils.IsSeq(this.dsource, elem)) {
          list.push(elem.Value);
        }
      }
      this._debug('getSeqSubNodes: list contains ' + list.length + ' elements');
      if ( this.debug > 1 ) {
        for (var i=0;i<list.length;i++) {
          this._debug('getSeqSubNodes:  list item: '+ list[i],this.debug);
        }
      }
      this._debug('getSeqSubNodes: DONE. ---------------------------------------------');
      return(list);
    },
  
    // -----------------------------------------------------------------------------------------
    getContainers : function (container) {
      this._debug('getContainers: START. container='+container);
      var realnode = this._getRealNode(container);
      var list = new Array;
  
      if ( realnode == this.root ) realnode = realnode + ':seq';
  
      var res = this.RDF.GetResource(realnode);
  
      this.RDFC.Init(this.dsource, res);
  
      this._debug('getContainers: realnode='+realnode);
  
      var elems = this.RDFC.GetElements();
      while (elems.hasMoreElements()) {
        var elem = elems.getNext();
        elem = jslibQI(elem, "nsIRDFResource");
        if (this.RDFCUtils.IsContainer(this.dsource, elem)) {
          list.push(elem.Value);
        }
      }
  
      this._debug('getContainers: list contains ' + list.length + ' elements');
      if ( this.debug > 1 ) {
        for (var i=0;i<list.length;i++) {
          this._debug('getContainers:  list item: '+ list[i],this.debug);
        }
      }
      this._debug('getContainers: DONE. ---------------------------------------------');
  
      if ( ! container ) list.unshift(this.root+':seq');
  
      return(list);
  
    },
  
    // -----------------------------------------------------------------------------------------
    addBag : function (aBag) {
      this._debug('addBag: START. aBag='+aBag);
      var realnode = this._getRealNode(aBag);
      var err = null;
      if (!realnode) err = "inmemoryrdf.js: addBag: must supply a value for 'aBag'";
      if (realnode == this.root || realnode == this.root+':seq') err="inmemoryrdf.js: addBag: cannot create a sequence the same name as the root sequence.";
      if (realnode.lastIndexOf(":") == (realnode.length-1) ) err="inmemoryrdf.js: addBag: sequence names cannot end in ':'";
  
      if (!err) {
       realnode = this._getRealNode(aBag);
       var res = this.RDF.GetResource(realnode);
  
       var pos = realnode.lastIndexOf(":");
       var parent = realnode.slice(0, pos);
       
       var parentres = this.RDF.GetResource(parent);
       this._debug("addBag: aBag='"+aBag+"' realnode='"+realnode+"' parent='"+parent+"'");
       if (parentres) {
         this.RDFCUtils.MakeBag(this.dsource, res);
         if ( parent != this.root ) this.RDFC.Init(this.dsource, parentres);
         this.RDFC.AppendElement(res);
       }
      }
      this._debug('addBag: DONE. ---------------------------------------------');
      if (err)throw(err);
      return(realnode);
  
    },
  
    // -----------------------------------------------------------------------------------------
    removeBag : function (aBag, deep) {
      if (aBag == this.root) throw("Cannot remove root Bag");
      this._debug('removeBag: START. aBag='+aBag+' deep='+deep);
      var realnode = this._getRealNode(aBag);
      var res = this.RDF.GetResource(realnode);
      var err = null;
  
      if (this.RDFCUtils.IsBag(this.dsource, res)) {
        if (deep) {
          this._deleteBagRecursively(res);
        }
        this.removeNode(aBag);
      } else {
        this._debug('removeBag: cannot remove aBag='+aBag+', it is a node!');
        err = "inmemoryrdf.js: removeBag: Trying to remove a Bag: '"+aBag+"', when it's a node is an error.";
      }
      this._debug('removeBag: DONE. ---------------------------------------------');
      if (err)throw(err);
    },
  
    // -----------------------------------------------------------------------------------------
    isBag : function (aBag) {
      this._debug('isBag: START. aBag='+aBag);
      var realnode = this._getRealNode(aBag);
      var res = this.RDF.GetResource(realnode);
      var result=false;
      if (res && this.RDFCUtils.IsBag(this.dsource, res)) result=true;
      this._debug('isBag: result is: '+result);
      this._debug('isBag: DONE. ---------------------------------------------');
    },
  
    // -----------------------------------------------------------------------------------------
    getBagSubNodes : function (aBag) {
      this._debug('getBagSubNodes: START. aBag='+aBag);
      var realnode = this._getRealNode(aBag);
      var list = new Array;
  
      var res = this.RDF.GetResource(realnode);
  
      this._debug('getBagSubNodes: realnode='+realnode);
  
      var elems = this.RDFC.GetElements();
      while (elems.hasMoreElements()) {
        var elem = elems.getNext();
        elem = nsIRDFResource(elem, "nsIRDFResource");
        if (!this.RDFCUtils.IsBag(this.dsource, elem)) {
          list.push(elem.Value);
        }
      }
      this._debug('getBagSubNodes: list contains ' + list.length + ' elements');
      if ( this.debug > 1 ) {
        for (var i=0;i<list.length;i++) {
          this._debug('getBagSubNodes:  list item: '+ list[i],this.debug);
        }
      }
      this._debug('getBagSubNodes: DONE. ---------------------------------------------');
      return(list);
    },
  
    // -----------------------------------------------------------------------------------------
    addAlt : function (aAlt) {
      this._debug('addAlt: START. aAlt='+aAlt);
      var realnode = this._getRealNode(aAlt);
      var err = null;
      if (!realnode) err = "inmemoryrdf.js: addAlt: must supply a value for 'aAlt'";
      if (realnode == this.root || realnode == this.root+':seq') err="inmemoryrdf.js: addAlt: cannot create a sequence the same name as the root sequence.";
      if (realnode.lastIndexOf(":") == (realnode.length-1) ) err="inmemoryrdf.js: addAlt: sequence names cannot end in ':'";
  
      if (!err) {
       realnode = this._getRealNode(aAlt);
       var res = this.RDF.GetResource(realnode);
  
       var pos = realnode.lastIndexOf(":");
       var parent = realnode.slice(0, pos);
       
       var parentres = this.RDF.GetResource(parent);
       this._debug("addAlt: aAlt='"+aAlt+"' realnode='"+realnode+"' parent='"+parent+"'");
       if (parentres) {
         this.RDFCUtils.MakeAlt(this.dsource, res);
         if ( parent != this.root ) this.RDFC.Init(this.dsource, parentres);
         this.RDFC.AppendElement(res);
       }
      }
      this._debug('addAlt: DONE. ---------------------------------------------');
      if (err)throw(err);
      return(realnode);
    },
  
    // -----------------------------------------------------------------------------------------
    removeAlt : function (aAlt, deep) {
      if (aAlt == this.root) throw("Cannot remove root Alt");
      this._debug('removeAlt: START. aAlt='+aAlt+' deep='+deep);
      var realnode = this._getRealNode(aAlt);
      var res = this.RDF.GetResource(realnode);
      var err = null;
  
      if (this.RDFCUtils.IsAlt(this.dsource, res)) {
        if (deep) {
          this._deleteAltRecursively(res);
        }
        this.removeNode(aAlt);
      } else {
        this._debug('removeAlt: cannot remove aAlt='+aAlt+', it is a node!');
        err = "inmemoryrdf.js: removeAlt: Trying to remove a Alt: '"+aAlt+"', when it's a node is an error.";
      }
      this._debug('removeAlt: DONE. ---------------------------------------------');
      if (err)throw(err);
    },
  
    // -----------------------------------------------------------------------------------------
    isAlt : function (aAlt) {
      this._debug('isAlt: START. aAlt='+aAlt);
      var realnode = this._getRealNode(aAlt);
      var res = this.RDF.GetResource(realnode);
      var result=false;
      if (res && this.RDFCUtils.IsAlt(this.dsource, res)) result=true;
      this._debug('isAlt: result is: '+result);
      this._debug('isAlt: DONE. ---------------------------------------------');
    },
  
    // -----------------------------------------------------------------------------------------
    getAltSubNodes : function (aAlt) {
      this._debug('getAltSubNodes: START. aAlt='+aAlt);
      var realnode = this._getRealNode(aAlt);
      var list = new Array;
  
      var res = this.RDF.GetResource(realnode);
  
      this._debug('getAltSubNodes: realnode='+realnode);
  
      var elems = this.RDFC.GetElements();
      while (elems.hasMoreElements()) {
        var elem = elems.getNext();
        elem = jslibQI(elem, "nsIRDFResource");
        if (!this.RDFCUtils.IsAlt(this.dsource, elem)) {
          list.push(elem.Value);
        }
      }
      this._debug('getAltSubNodes: list contains ' + list.length + ' elements');
      if ( this.debug > 1 ) {
        for (var i=0;i<list.length;i++) {
          this._debug('getAltSubNodes:  list item: '+ list[i],this.debug);
        }
      }
      this._debug('getAltSubNodes: DONE. ---------------------------------------------');
      return(list);
    },
  
    // -----------------------------------------------------------------------------------------
    addNode : function (aNode) {
      this._debug('addNode: START. aNode='+aNode);
      var realnode = this._getRealNode(aNode);
      var err = null;
  
      if (realnode == this.root) err="inmemoryrdf.js: addNode: Cannot add root Seq: '"+realnode+"', it is the root node!";
  
      if (!err) {
       var pos = realnode.lastIndexOf(":");
       var parent = realnode.slice(0, pos);
   
       this._debug("addNode: aNode='"+aNode+"' realnode='"+realnode+"' parent='"+parent+"'");
  
       if ( parent == this.root ) parent = parent + ':seq';
  
       var res = this.RDF.GetResource(realnode);
       var parentres = this.RDF.GetResource(parent);
       if (parentres) {
         this.RDFC.Init(this.dsource, parentres);
         this.RDFC.AppendElement(res);
       }
      }
  
      this._debug('addNode: DONE. ---------------------------------------------');
      if (err)throw(err);
      return(realnode);
  
    },
  
    // -----------------------------------------------------------------------------------------
    removeNode : function (aNode) {
      this._debug('removeNode: START. aNode='+aNode);
      var realnode = this._getRealNode(aNode);
      var res = this.RDF.GetResource(realnode);
      var root = this.RDF.GetResource(this.root);
  
      var pos = realnode.lastIndexOf(":");
      var parent = realnode.slice(0, pos);
      var parentres = this.RDF.GetResource(parent);
  
      this.RDFC.Init(this.dsource, parentres);
  
      var arcs = this.dsource.ArcLabelsOut(res);
      while (arcs.hasMoreElements()) {
        var arc = arcs.getNext();
        var targets = this.dsource.GetTargets(res, arc, true);
        while (targets.hasMoreElements()) {
          var target = targets.getNext();
          this.dsource.Unassert(res, arc, target, true);
        }
      }
      this.RDFC.RemoveElement(res, false);
      this._debug('removeNode: DONE. ---------------------------------------------');
    },
  
    // -----------------------------------------------------------------------------------------
    isNode : function (aNode) {
      this._debug('isNode: START. aNode='+aNode);
      var realnode = this._getRealNode(aNode);
      var res = this.RDF.GetResource(realnode);
      var result=false;
      this._debug('isNode: this.RDFC.IndexOf is '+ this.RDFC.IndexOf(res) +' , realnode='+realnode);
      if (res && this.RDFC.IndexOf(res) >= 1 ) result=true;
      this._debug('isNode: result is: '+result);
      this._debug('isNode: DONE. ---------------------------------------------');
      return(result);
    },
  
    // -----------------------------------------------------------------------------------------
    setAttrLit : function (aNode, name, value) {
      this._debug('setAttrLit: START. aNode='+aNode+' name='+name+' value='+value);
      var err = null;
  
      if ( !err) {
       var realnode = this._getRealNode(aNode);
       var newnode = this.RDF.GetResource(realnode);
       var oldvalue = this.getAttribute(realnode, name);
       
       this._debug('setAttrLit: realnode='+realnode+' oldvalue='+oldvalue);
       if (newnode) {
         // Add an assertion to the RDF datasource for each property of the resource
         if (oldvalue) { 
           this.dsource.Change(newnode,
               this.RDF.GetResource(this.xmlns + name),
               this.RDF.GetLiteral(oldvalue),
               this.RDF.GetLiteral(value) );
         } else {
           this.dsource.Assert(newnode,
               this.RDF.GetResource(this.xmlns + name),
               this.RDF.GetLiteral(value),
               true );
         }
       }
      }
      this._debug('setAttrLit: DONE. ---------------------------------------------');
      if (err)throw(err);
    },
  
    // -----------------------------------------------------------------------------------------
    setAttrRes : function (aNode, name, value) {
      this._debug('setAttrRes: START. aNode='+aNode+' name='+name+' value='+value);
      var err = null;
  
      if ( !err) {
       var realnode = this._getRealNode(aNode);
       var realvalue = this._getRealNode(value);
       var newnode = this.RDF.GetResource(realnode);
       var oldvalue = this.getAttribute(realnode, name);
       
       this._debug('setAttrRes: realnode='+realnode+' realvalue='+realvalue+' oldvalue='+oldvalue);
       if (newnode) {
         // Add an assertion to the RDF datasource for each property of the resource
         if (oldvalue) { 
           this.dsource.Change(newnode,
               this.RDF.GetResource(this.xmlns + name),
               this.RDF.GetLiteral(oldvalue),
               this.RDF.GetResource(realvalue) );
         } else {
           this.dsource.Assert(newnode,
               this.RDF.GetResource(this.xmlns + name),
               this.RDF.GetResource(realvalue),
               true );
         }
       }
      }
      this._debug('setAttrRes: DONE. ---------------------------------------------');
      if (err)throw(err);
    },
  
    // -----------------------------------------------------------------------------------------
    getAttribute : function (aNode, name) {
      this._debug('getAttribute: START. aNode='+aNode+' name='+name);
      var realnode = this._getRealNode(aNode);
      var result = null;
  
      var itemRes = this.RDF.GetResource(this.xmlns + name);
      if (itemRes) {
       var IDRes = this.RDF.GetResource(realnode);
       if (IDRes) {
        var thisNode = this.dsource.GetTarget(IDRes, itemRes, true);
        if (thisNode) thisNode = jslibQI(thisNode, "nsIRDFLiteral");
        if (thisNode) result=thisNode.Value;
       }
      }
      this._debug('getAttribute: returning result is '+result);
      this._debug('getAttribute: DONE. ---------------------------------------------');
      return(result);
    },
  
    // -----------------------------------------------------------------------------------------
    removeAttribute : function (aNode, name) {
      this._debug('removeAttribute: START. aNode='+aNode+' name='+name);
      var realnode = this._getRealNode(aNode);
  
      var src = this.RDF.GetResource(realnode);
      if (src) {
        var prop = this.RDF.GetResource(this.xmlns + name, true);
        var target = this.dsource.GetTarget(src, prop, true);
        this.dsource.Unassert(src, prop, target);
      }
      this._debug('removeAttribute: DONE. ---------------------------------------------');
    },
  
    // -----------------------------------------------------------------------------------------
    isAttribute : function (aNode, name) {
      this._debug('isAttribute: START. aNode='+aNode+' name='+name);
      var value = this.getAttribute(aNode, name);
      var result=false;
      if (value) result=true;
      this._debug('isAttribute: returning result is '+result);
      this._debug('isAttribute: DONE. ---------------------------------------------');
      return(result);
    },
  
    // -----------------------------------------------------------------------------------------
    getDatasource : function () {
      this._debug('getDatasource: START');
      this._debug('getDatasource: returning result is '+this.dsource);
      this._debug('getDatasource: DONE. ---------------------------------------------');
      return(this.dsource);
    },
  
    // -----------------------------------------------------------------------------------------
    showRDF : function () {
      this._debug('showRDF: START');
      var allcontainers = new Array;
      var topcontainers = this.getContainers();
      for (var i=0;i<topcontainers.length;i++) {
        allcontainers.push(topcontainers[i]);
        var containers = this.getContainers(topcontainers[i]);
        var objs = new Array;
        for (var j=0;j<allcontainers.length;j++) {
          this._debug("showRDF: j="+j+" "+allcontainers[j]);
          objs[j] = new Object();
          objs[j].container = allcontainers[j];
          objs[j].nodes = this.getSeqSubNodes(allcontainers[j]);
        }
        
        jslibDebug('number of containers: '+objs.length);
        for (j=0;j<objs.length;j++) {
         with (objs[j]) {
          jslibDebug(j+' container: '+container);
          jslibDebug(j+'     nodes: (count:'+nodes.length+') '+nodes);
         }
        }
      }
      this._debug('showRDF: DONE. ---------------------------------------------');
    },
  
    // -----------------------------------------------------------------------------------------
    tieToElement : function (elemid) {
      this._debug('tieToElement: START. elemid='+elemid);
      var xul = document.getElementById(elemid);
      xul.database.AddDataSource(this.dsource);
      xul.builder.rebuild();
      this._debug('tieToElement: DONE. ---------------------------------------------');
    },
  
    // -----------------------------------------------------------------------------------------
    isEmpty : function (container) {
      this._debug('isEmpty: START. container='+container);
      var realnode = this._getRealNode(container);
      var res = this.RDF.GetResource(realnode);
      var result=false;
  
      if (res && this.RDFCUtils.IsEmpty(this.dsource, res)) result=true;
      this._debug('isEmpty: result is: '+result);
      this._debug('isEmpty: DONE. ---------------------------------------------');
    },
  
    // -----------------------------------------------------------------------------------------
    Type : function (resourcestr) {
      this._debug('Type: START. resourcestr='+resourcestr);
      var realnode = this._getRealNode(resourcestr);
      var res = this.RDF.GetResource(realnode);
      var result=false;
  
      if (res && this.RDFCUtils.IsSeq(this.dsource, res)) result=JSLIB_INMEM_TYPE_SEQ;
      else if (res && this.RDFCUtils.IsAlt(this.dsource, res)) result=JSLIB_INMEM_TYPE_ALT;
      else if (res && this.RDFCUtils.IsBag(this.dsource, res)) result=JSLIB_INMEM_TYPE_BAG;
      else if (this.isNode(realnode)) result=JSLIB_INMEM_TYPE_NODE;
      this._debug('Type: result is: '+result+' SEQ='+JSLIB_INMEM_TYPE_SEQ+', ALT='+JSLIB_INMEM_TYPE_ALT+', BAG='+JSLIB_INMEM_TYPE_BAG+' NODE='+JSLIB_INMEM_TYPE_NODE);
      this._debug('Type: DONE. ---------------------------------------------');
    },
  
    // -----------------------------------------------------------------------------------------
    Delete : function (elemid) {
      this._debug('Delete: START. elemid='+elemid);
      var ds = jslibGetService(JSLIB_INMEM_RDF_MEM_PROGID, "nsIRDFPurgeableDataSource");
  
      ds.Mark( this.RDF.GetResource( this.root ) , this.RDF.GetResource(this.xmlns +'list') , this.RDF.GetResource( this.root + ':seq' ) , true);
  
      ds.Sweep();
  
      if ( elemid ) {
       this._debug("Delete: informing element '"+elemid+"', to reset");
       var xul = document.getElementById(elemid);
       xul.builder.rebuild();
      }
      this._debug('Delete: DONE. ---------------------------------------------');
    },
  
    // -----------------------------------------------------------------------------------------
    _getRealNode : function (aNode) {
      var node;
      if (!aNode) {
        node = this.root;
      } else if ( aNode == this.root ) {
        node = this.root;
      } else if (aNode.indexOf(this.root+":") == -1) {
        node = this.root+":"+aNode;
      } else {
        node = aNode;
      }
      this._debug("  _getRealNode: returning node='"+node+"' for given input of '"+aNode+"'",2);
      return(node);
    },
  
    // -----------------------------------------------------------------------------------------
    _deleteRecursive : function (res) {
      this.RDFC.Init(this.dsource, res);
  
      var elems = this.RDFC.GetElements();
      while (elems.hasMoreElements()) {
        var elem = elems.getNext();
        if (this.RDFCUtils.IsContainer(this.dsource, elem)) {
          this._deleteRecursive(elem);
          this.RDFC.Init(this.dsource, res);
        }
        var arcs = this.dsource.ArcLabelsOut(elem);
        while (arcs.hasMoreElements()) {
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
  
    // -----------------------------------------------------------------------------------------
    setDebug : function (l) {
      var c=this.debug;
      if ( l == 1 ) this.debug = 1;
      else if ( l == 2 ) this.debug = 2;
  
      if ( ! c ) {
       this._debug("\n\
        The contents of this file are subject to the Mozilla Public\n\
        License Version 1.1 (the \"License\"); you may not use this file\n\
        except in compliance with the License. You may obtain a copy of\n\
        the License at http://www.mozilla.org/MPL/\n\
        \n\
        Software distributed under the License is distributed on an \"AS\n\
        IS\" basis, WITHOUT WARRANTY OF ANY KIND, either express or\n\
        implied. See the License for the specific language governing\n\
        rights and limitations under the License.\n\
        \n\
        The Original Code is Urban Rage Software code.\n\
        The Initial Developer of the Original Code is Eric Plaster.\n\
        \n\
        Portions created by Urban Rage Software are\n\
        Copyright (C) 2000 Urban Rage Software.  All\n\
        Rights Reserved.\n\
        \n\
        Portions created by Frank Koenen (fkoenen@virtualmonet.com) of\n\
        Monet Technologies are Copyright (C) 2004 Monet Technologies. All\n\
        Rights Reserved.");
      }
  
      this._debug('inMemRDF: debug enabled. root='+this.root+' xmlns='+this.xmlns);
  
    },
  
    // -----------------------------------------------------------------------------------------
    _debug : function (str,level) { if ( ! level ) level=1; if ( level > this.debug ) return; jslibDebug('inmemoryrdf.js: '+level+': '+str); }
  
  }; // END inMemRDF Class
  
  jslibDebug('*** load: '+JS_INMEMORYRDF_FILE+' OK');
  
  // If jslib base library is not loaded, dump this error.
} else {
      dump("JS_FILE library not loaded:\n"                                +
           " \tTo load use: chrome://jslib/content/jslib.js\n"            +
           " \tThen: include(jslib_rdfmemory);\n\n");
}
  
