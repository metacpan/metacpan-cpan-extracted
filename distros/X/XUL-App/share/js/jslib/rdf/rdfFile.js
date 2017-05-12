if(typeof(JS_LIB_LOADED)=='boolean')
{

// test to make sure rdf base class is loaded
if(typeof(JS_RDF_LOADED)!='boolean')
  include(JS_LIB_PATH+'rdf/rdf.js');

// test to make sure file class is loaded
if (typeof(JS_FILE_LOADED)!='boolean')
  include(JS_LIB_PATH+'io/file.js');


const JS_RDFFILE_FLAG_SYNC        = 1; // load RDF source synchronously
const JS_RDFFILE_FLAG_DONT_CREATE = 2; // don't create RDF file (RDFFile only)
const JS_RDFFILE_FILE             = "rdfFile.js";

function RDFFile(aPath, aFlags, aNameSpace, aID) 
{
  this.created = false;

  if(aPath)
    this._file_init(aPath, aFlags, aNameSpace, aID);
}
RDFFile.prototype = new RDF;

RDFFile.prototype._file_init = function (aPath, aFlags, aNameSpace, aID) {
  aFlags = aFlags || JS_RDFFILE_FLAG_SYNC; // default to synchronous loading

  if(aNameSpace == null) {
     aNameSpace = "http://jslib.mozdev.org/rdf#";
  }
  if(aID == null) {
     aID = "JSLIB";
  }
  // Ensure we have a base RDF file to work with
  var rdf_file = new File(aPath);

  if (!rdf_file.exists() && !(aFlags & JS_RDFFILE_FLAG_DONT_CREATE)) {

    if (rdf_file.open("w") != JS_LIB_OK) {
      return;
    }

    var filestr =
       '<?xml version="1.0" ?>\n' +
       '<RDF:RDF\n' +
       '     xmlns:'+ aID +'="'+ aNameSpace +'"\n' +
       '     xmlns:RDF="http://www.w3.org/1999/02/22-rdf-syntax-ns#">\n' +
       '</RDF:RDF>\n';
     jslibPrint("here4!\n");
    if (rdf_file.write(filestr) != JS_LIB_OK) {
       rdf_file.close();
       return;
    }

    this.created = true;
  }
  rdf_file.close();

  // Get a reference to the available datasources
  var serv = Components.classes["@mozilla.org/network/io-service;1"].
             getService(Components.interfaces.nsIIOService);
  if (!serv) {
      throw Components.results.ERR_FAILURE;
  }
  var uri = serv.newFileURI(rdf_file.nsIFile);
  this._rdf_init(uri.spec, aFlags);
};

jslibDebug('*** load: '+JS_RDFFILE_FILE+' OK');

} // END BLOCK JS_LIB_LOADED CHECK

// If jslib base library is not loaded, dump this error.
else
{
    dump("JS_RDFFILE library not loaded:\n"                       +
         " \tTo load use: chrome://jslib/content/jslib.js\n"            +
         " \tThen: include('chrome://jslib/content/rdf/rdfFile.js');\n\n");
}
