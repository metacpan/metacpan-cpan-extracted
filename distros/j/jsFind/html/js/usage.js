/**
 usage.js an example usage of the search engine

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

function go(f)
{
  var form = document.getElementById('search');
  if (! form && document.all) form = eval('document.all.search');
  var query = form.elements['query'].value;
  var index_name = form.elements['index_name'].options[form.elements['index_name'].selectedIndex].value;

  if(!query)
  {
    return false;
  }

  if(query == null || query == "")
  {
    alert("No search terms entered!");
    return false;
  }

  var parsed_string = query.replace(/\s/gi,"+");
  //var url=location.host+location.pathname+"?search="+parsed_string;
  var url=location.pathname+"?";
  if (index_name) url += "index_name="+index_name+"&";
  url += "query="+parsed_string;
  location = url;

  return false;
}

// Function to help find a "DIV" element 
function findDivHelper(n, id)
{
  for(var m=n.firstChild; m != null; m=m.nextSibling)
  {
    if((m.nodeType == 1) &&
       (m.tagName.toLowerCase() == "div") &&
       m.getAttribute("id") &&
       (m.getAttribute("id").toLowerCase() == id.toLowerCase() ))
    {
      return m;
    }
    else 
    {
      var r=findDivHelper(m, id);
      if(r) return r;
    } 
  } 
  return null;
}

// Function to find a specified "DIV" element by id
function findDiv(id)
{
  return findDivHelper(document.body,id); 
} 

// Print results to page
function printResults(result)
{
  //clearTimeout(watchdog_id);
  //debug("clearTimeout = "+watchdog_id);
  debug("printResults("+result.length+")");

  var d = findDiv("results");
  var header;

  // Null result output
  if(result.length < 1)
  {
    header = (d.getElementsByTagName("h2"))[0].firstChild;
    try {
      header.replaceData(0, 14, "Nothing Found ");
    } catch(e) {}

    if(search_err != "")
    {
      e = document.createElement("font");
      e.setAttribute("color","red");
      e.setAttribute("size","+1");
      e.appendChild(document.createTextNode(search_err));
      d.appendChild(e);
      d.appendChild(document.createElement("br"));
    }

    return;
  }

  // Add results to main document
  for(var i=result.length-1; i>=0; i--)
  {
    var e = document.createElement("font");

    e.setAttribute("color","blue");
    e.setAttribute("size","+1");
    e.appendChild(document.createTextNode(result[i].title));
    d.appendChild(e);
    d.appendChild(document.createTextNode(" "));
    d.appendChild(document.createElement("br"));

    e = document.createElement("a");
    e.setAttribute("href",result[i].link);
    e.setAttribute("target","_blank");
    e.appendChild(document.createTextNode(result[i].link));
    d.appendChild(e);
    d.appendChild(document.createTextNode(" "));

    e = document.createElement("font");
    e.setAttribute("color","green");
    e.appendChild(document.createTextNode("["+result[i].frequency+"]"));
    d.appendChild(e);
    d.appendChild(document.createElement("br"));
    d.appendChild(document.createElement("br"));
  }
 
  // Change header
  header = (d.getElementsByTagName("h2"))[0].firstChild;

  try {
    header.replaceData(0, 14, "Search Results");
  } catch(e) {}

}
