/**
 search.js searchs an XML index to HTML files.

 A part of the jsfind project (http://projects.elucidsoft.net/jsfind)
 Copyright (C) 2003 Shawn Garbett

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 Contact Info:
 Shawn Garbett <Shawn@eLucidSoft.net>
 http://www.elucidsoft.net
 4037 General Bate Drive
 Nashville, TN 37204
*/

// Constants
var conversion = new String
      ("0123456789abcdefghijklmnopqrstuvwxyz");

// State variables
var query_left = "";
var search_err = "";
var results    = null;
var index_path = "";

var watchdog_id = 0;
var watchdog_callback = null;

// Object to hold search results
function Result(title, link, freq)
{
  this.title=title;
  this.link=link;
  this.frequency=Number(freq);
}

// Function to merge (intersect) two result sets
function intersect_results(data)
{
  // If there are no stored results, then these are the results
  if(!results)
  {
    results = data;
    return;
  }

  var output=new Array();

  // There are existing results, to do an intersect...
  for(var i=0; i<results.length; i++)
  {
    for(var j=0; j<data.length; j++)
    {
      if(data[j].title == results[i].title)
      {
        results[i].frequency += data[j].frequency;
        output.push(results[i]);  
        break;
      }
    }
  }

  results = output;
}

/*
 From David Flanagan's, _Javascript:_The Definitive_Guide_, pg. 294-5,
  published by O'Reilly, 4th edition, 2002
*/

var debug_div = null;

function debug(msg)
{
//  return; // Disable debugging

  if (! debug_div) debug_div = document.getElementById('debug');

  // this will create debug div if it doesn't exist.
  if (! debug_div) {
  	debug_div = document.createElement('div');
	document.body.appendChild(debug_div);
  }
  if (debug_div) {
  	debug_div.appendChild(document.createTextNode(msg));
	debug_div.appendChild(document.createElement("br"));
  }
}

// Convert a number into a base 62 alphanumeric number string
function convert(num)
{
  var base = conversion.length;
  var pow = 1;
  var pos = 0;
  var out = "";  

  if(num == 0)
  {
    return "0";
  }

  while (num > 0)
  {
    pos = num % base;
    out = conversion.charAt(pos) + out;
    num = Math.floor(num/base);
    pow *= base;
  }

  return out;
}

function watchdog()
{
  debug ("TIMEOUT!");
  watchdog_callback(new Array());
}

var xmldoc;

// This function loads the XML document from the specified URL, and when
// it is fully loaded, passes that document and the url to the specified
// handler function.  This function works with any XML document
function loadXML(url, handler, data, result_handler)
{
  debug("loadXML("+url+","+data+")");

  // Timeout operation in 10 seconds
  watchdog_callback = result_handler;
  watchdog_id=setTimeout("watchdog()", 20000);

  debug("setTimeout = "+watchdog_id);

  try 
  {
    // Use the standard DOM Level 2 technique, if it is supported
    if (document.implementation && document.implementation.createDocument)
    {
     // Create a new Document object
      xmldoc = document.implementation.createDocument("", "", null);

      // Specify what should happen when it finishes loading
      xmldoc.onload = function() { handler(xmldoc, url, data, result_handler); }

      //xmldoc.onerror = docError;
      //xmldoc.addEventListener("load",docError,false);

      // And tell it what URL to load
      xmldoc.load(url);
      return true;
    }
    // Otherwise use Microsoft's proprietary API for Internet Explorer
    // Something about not following standards once again
    else if (window.ActiveXObject)
    {  
      xmldoc = new ActiveXObject("Microsoft.XMLDOM");	// Create doc.
      if (! xmldoc) xmldoc = new ActiveXObject("MSXML2.DOMDocument");	// Create doc.
      // Specify onload
      xmldoc.onreadystatechange = function()
      {              
        if (xmldoc.readyState == 4) handler(xmldoc, url, data, result_handler);
      }
      xmldoc.load(url);                                     // Start loading!
      return true;
    }
    // else fallback on usage of iframes to load xml (Opera 7.53 without Java and maybe old Mac browsers)
    else {
      debug("using iframe xml loader - experimental and slow");
      if (! window.xml_iframe) {
        debug("creating iframe");
        window.xml_iframe = document.createElement('div');
        window.xml_iframe.innerHTML = '<iframe src="'+url+'" name="xml_iframe" height="0" width="0" style="display: none;"></iframe>';
        document.body.appendChild(window.xml_iframe);
      } else {
        debug("loading xml in existing iframe");
        window.frames.xml_iframe.window.document.location.href = url;
      }

      // set timeout to re-check if iframe is loaded
      window.iframe_timeout = window.setInterval('iframe_xml_loaded();',100);

      // save some data for iframe_xml_loaded()
      window.xml_handler = handler;
      window.xml_url = url;
      window.xml_data = data;
      window.xml_result_handler = result_handler;
      return true;
    }
    clearTimeout(watchdog_id);
    debug("Browser incompatilibity: can't request XML document by one of supported methods");
    return false;
  }
  catch(ex)
  {
    clearTimeout(watchdog_id);
    debug("clearTimeout = "+watchdog_id);
    debug ("CAUGHT EXCEPTION!");
    result_handler(new Array());
    return false;
  }

  return true;
}

function iframe_xml_loaded() {
  debug("iframe_xmldoc_loaded");
  if (! window.frames['xml_iframe']) return;
  var xml = eval('window.frames.xml_iframe.window.document');
  if (xml) {
	clearTimeout(window.iframe_timeout);
  	debug("calling handler with ("+window.xml_url+","+window.xml_data+",...)");
  	window.xml_handler(window.frames.xml_iframe.window.document, window.xml_url, window.xml_data, window.xml_result_handler);
  } else {
  	debug("can't eval iframe with xml");
  }
}

function loadData(xmldoc, url, pos, result_handler)
{
  clearTimeout(watchdog_id);
  debug("clearTimeout = "+watchdog_id);

  debug ("loadData("+url+","+pos+")");

  var data = new Array();

  // Get all entries
  var entries = xmldoc.getElementsByTagName("e");

  if(entries.length > pos)
  {
    // Get the links associated with this query
    var links = entries[pos].getElementsByTagName("l");

    // Dynamically append results to output
    for(var i=0; i<links.length; i++)
    {
      data.push(new Result(links[i].getAttribute("t"),
                           links[i].firstChild.data,
                           links[i].getAttribute("f")));
    }

    intersect_results(data); 

    if(query_left.length > 0)
    {
      doSearch(index_path, query_left, result_handler);  
    }
    else
    {
      results.sort(sortResults);
      result_handler(results);
    }
  }
  else
  {
    debug("INTERNAL ERROR, Inconsistent index");
    search_err="INTERNAL ERROR, Inconsistent index";
  }
}

function sortResults(a, b)
{
  return a.frequency - b.frequency;
}

function traverseTree(xmldoc, url, query, result_handler)
{
  clearTimeout(watchdog_id);
  debug("clearTimeout = "+watchdog_id);
 
  debug("traverseTree("+xmldoc+","+url+","+query+")");

  var keys = xmldoc.getElementsByTagName("k");
  var i;

  for(i = 0; i < keys.length; i++)
  {
    var key = keys[i].firstChild.data;
    debug("traverseTree: key="+key+" query="+query);
    if(key != '' && key != null)
    {
      // Case where current key is greater than query, descend
      if(key > query)
      {
        if(key != '' && key != null)
        {
          if(!loadXML(url.replace(".xml","/"+convert(i)+".xml"),
                      traverseTree,query,result_handler))
          {
            debug("Unable to locate key "+query);
            result_handler(new Array());
          }
          // make sure of garbage collection
          xmldoc=null;
          return;
        }
      }
      // Found it!
      else if(key==query)
      {
        if(!loadXML(url.replace(/(\w+\.xml)/, "_$1"),
                    loadData, i, result_handler))
        {
          debug("ERROR: Unable to locate data "+query);
          result_handler(new Array());
        }
        // make sure of garbage collection
        xmldoc=null;
        return;
      }
    }
  }
  // Look past the end...
  if(keys.length == 0 || !loadXML(url.replace(".xml","/"+convert(i)+".xml"),
              traverseTree,query,result_handler))
  {
    debug("Unable to locate key "+query);
    result_handler(new Array());
  }
  // make sure of garbage collection
  xmldoc=null;
  return;
}

function doSearch(index_name,query, result_func)
{
  //alert("doSearch("+index_name+","+query+")");
  var pos=query.search(/[\s\+]/);
  if (index_name) index_path = index_name+'/';

  if(pos < 0)
  {
    query_left = "";
  }
  else
  {
    query_left = query.slice(pos+1);
    query = query.slice(0,pos);
  } 

  if(!loadXML(index_path+"0.xml", traverseTree, query.toLowerCase(), result_func))
  {
    debug("ERROR: Couldn't find main index 0.xml");
    search_err = "INTERNAL ERROR: Unable to load main index 0.xml";
  }
}
