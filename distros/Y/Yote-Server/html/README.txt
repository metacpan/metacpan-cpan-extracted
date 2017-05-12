This document describes the web worker flow of Yote.
That means, the interactions between the javascript on 
the viewed html page and the web worker, and the web
worker and the yote server.

* HTML/javascript *

The javascript on the html page loads yote.js
and then, when javascript is loaded, calls
  yote.initMain();
Then, to call worker functions,
  yote.call( 'filewithworkerfunction', [ arguments ], 
             functiontocalluponcompletion );
  The funcitontocalluponcompletion is passed a string,
  yote object or list of strings and/or yote objects.
  
  The hinky convention here is that a list of one thing
  is passed not as a list, but as that one thing, so
  (rare) functions that are expecting a list should pass
  true as the fourth argument to 'yote.call'.

* WORKER *

The worker is a javscript file that runs when called, the 
running doing the initialization.

The worker first imports the yote.js file, then calls
   yote.initWorker();
   var root = yote.fetch_root();

Once this is called, The root interacts as any yote object
and can provide app objects via
   var app = root.fetch_app( 'appclassname' );

the workers window.onmessage function is set up and that
receives the call from the HTML javascript. This function
takes a single argument, 'e', and the parameters passed
in to yote.call are accessed via e.data.

Once the processing is done, a response is returned to the
HTML/javascript with postMessage. A JSON object should be
returned, usually the rawResponse from some call. 
TODO : write a method that converts yote objects to raw
responses for sending.
