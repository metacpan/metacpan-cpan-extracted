WebSource version 2
===================

WebSource is a framework taking the form of a perl module and allowing
computer access to the Web. It allows to describe a complex task by
decomposing it into simpler small tasks. The complex task is descriped
in an XML file. Each such task is composed of extraction, fetching, 
filtering, querying, formatting subtasks.

For example the task allowing to query google and get the resulting urls is
done with four subtasks : 
  - "query" : building the initial query,
  - "fetch" : fetching the result pages, 
  - "links" : extraction the urls from the results pages, and 
  - "next"  : extracting the next page link to allow the fetching
              of more results.

The result of the "query" task is sent to the "fetch" tasks which downloads
a page it is given and then sends it to both "links" and "next" tasks. The
"next" task extracts the next page url and sends it to "fetch". The "links"
task extraction the resulting url which are returned.

When a task recieves a item it processes the item and stores the result in
an output queue. When required, items are fetched from the task's queue and
sent to all the tasks which can be reached through an outgoing link.



INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

DEPENDENCIES

This module depends on :
 - URI               : URI handling in perl
 - LWP::UserAgent    : the World Wide Web perl library
 - XML::LibXML       : the perl interface to the libxml2 library
 - HTML::TreeBuilder : an HTML parser which is robust and alows
                       to generate XML
 - Getopt::Mixed     : option processing used in ws-query
 - SOAP::Lite        : access to web services (ws:soap)
 - String::Approx    : approximate string matching
USAGE 

The most common usage of WebSource is done by using the ws-query
command. A typical call is :

ws-query [options] -s <desc file> <parameters>

where options are ws-query options and parameters are specific to the 
used source description file (<ws:options> element)

More info on the ws-query command can be obtained by calling it with
the -h option ...

$ ws-query -h



COPYRIGHT AND LICENCE

Copyright (C) 2004 Benjamin Habegger

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
