:include style.hb

:out main
<hb-doc tit="Perl HBM">

<p>The Perl HB Module consists of two parts. The first part was
designed to use the functionality provided by the HB library from your
Perl scripts.  It provides primitives that allow you to extract content
from HB files from the scripts. The second part, which depends upon the
first, allows you to embbed Perl code inside of your HB files and use
it to attend the requests.</p>

<hb-doc.page-link link="perlhb"><a href="perlhb">The HB extension to
Perl</a> tells you how to extract the content of HB files from your Perl
scripts. That way, you can use HB files like templates and replace tags
from them with whatever content you want to.</hb-doc.page-link>

<hb-doc.page-link link="hbperl"><a href="hbperl">The Perl HB Module</a>
explains how to embed Perl code straight into your HB files using the
<hb-doc.hbcode>&lt;perl.code></hb-doc.hbcode> tag. The code can do any
of the things that functions in HB modules can do.</hb-doc.page-link>

<p>Through this document we will use
<hb-doc.perlcode>brown</hb-doc.perlcode> color when writing Perl code
and <hb-doc.hbcode>blue</hb-doc.hbcode> color for HB strings:</p>

<p>The Perl HBM was implemented by <a
href="http://bachue.com/alejo">Alejandro Forero Cuervo</a> &lt;<a
href="mailto:bachue@bachue.com">bachue@bachue.com</a>>. The author
welcomes your comments and criticism on both the code and the
documentation.</p>

</hb-doc>
:

:out perlhb
<hb-doc tit="The HB extension to Perl">

<p>The HB extension to Perl allows you to call the application programming
interface used to embed HB in your existing applications from your Perl
scripts.</p>

<p>This document is divided in the following sections:</p>

<hb-doc.page-link link="perlhb.life"><a href="perlhb.life">HB's life
cycle</a> talks about the life cycles of your HB interpreter. It explains
how to initalize the interpreter, how to clean its internal caches and
how to shut it down.</hb-doc.page-link>

<hb-doc.page-link link="perlhb.req"><a href="perlhb.req">HB requests</a>
shows you how to pass a request to the HB interpreter. In this section
you'll learn how to create an instance of the HBReq class, how to setup
information about the request, how to have HB execute the request and
how to read the results.</hb-doc.page-link>

</hb-doc trail="yes" back="" up="main" next="hbperl">
:

:out perlhb.life
<hb-doc tit="HB's life cycle">

<p>In this section we will talk about HB's initialization and termination,
as well as provide information on how to clean the interpreter's
interal caches.</p>

<p><cute>Initializing HB</cute></p>

<p>The first thing you'll need to do before you can actually use the HB
interpreter is initialize it. This will have the interpreter setup internal
variables for its proper operation. The following Perl code suffices:</p>

<p><pre><hb-doc.perlcode>HB::init();</hb-doc.perlcode></pre></p>

<p>At that point the HB interpreter will begin to load modules and keep
information in caches.</p>

<p>If you are a curious developer, it will cause the
function hb_init() in HB's libhb/hb.c to be executed.</p>

<p><cute>Shuting the interpreter down</cute></p>

<p>Once you are done using HB and you don't need to keep it around any
longer, you will want to shut it down. This will cause it to free memory
and, more important, to unload whatever modules it has loaded.</p>

<p>It is very important that you actually shut it down, otherwise
information may get lost (because HB will not get a chance to shut down
whatever modules it may have loaded).</p>

<p>To do it, use:</p>

<p><pre><hb-doc.perlcode>HB::shutdown();</hb-doc.perlcode></pre></p>

<p>Again, for the curious, this will cause the function hb_shutdown in
HB's libhb/hb.c to be called.</p>

<p><cute>Cleaning up HB's internal caches</cute></p>

<p>If you plan to have your HB's interpreter around during long periods
of time, you will want it to clean its internal caches sometimes.</p>

<p>HB has been optimized using internal caches for many of its
objects. For example, whenever you load an HB file, HB will keep its
contents in memory so it doesn't have to read it and parse it the next
time it is requested (unless, of course, the file changes).</p>

<p>To avoid using all the system's memory in caches with objects that
are not needed any longer, HB will destroy objects in its caches when they
are not used during long periods of time.</p>

<p>However, to have HB check to see which objects it can free, you will
need to explicitly call HB's cleanup function, using the following
code:</p>

<p><pre><hb-doc.perlcode>HB::clean();</hb-doc.perlcode></pre></p>

<p>As of HB's version 1.9.8, it destroys caches of files and unloads HB
modules that have been unused for fixed amounts of time. It causes
the function hb_clean in HB's libhb/hb.c to be called.</p>

</hb-doc trail="yes" back="" up="perlhb" next="perlhb.req">
:

:out perlhb.req
<hb-doc tit="HB requests">

<p><cute>Creating an Instance of the HBReq class</cute></p>

<p>After you have succesfully initialized the HB interpreter (as we explained
in the <a href="perlhb.life">previous section</a>), you can begin to attend
requests. To do so, you will need an instance of the HBReq class, which you
can create calling HB's req function:</p>

<p><pre><hb-doc.perlcode>my $request = HB::req();</hb-doc.perlcode></pre></p>

<p>The <hb-doc.perlcode>HB::req</hb-doc.perlcode>
function will create a new instance of the class or return
<hb-doc.perlcode>undef</hb-doc.perlcode> if it fails to allocate memory
for it. You can then call any of the methods of the HBReq class, which
we will explain below.</p>

<p><cute>Setting Information about the Request</cute></p>

<p>Probably the first thing you'll want to set for an HBReq object is
the HB file we will use to attend the request:</p>

<p><pre><hb-doc.perlcode>$request->file("html/info.hb") || die("...");</hb-doc.perlcode></pre></p>

<p>As you can see, the file method takes one argument, the path to the HB
file, and returns 1 on success and 0 on failure.</p>

<p>For the curious, it calls HB's hb_req_file function, defined in the
libhb/hb.c file distributed with HB.</p>

<p>After that, you will want to set the name of the object that you
want to extract from the HB file (you can skip this step to extract the
`main' object):</p>

<p><pre><hb-doc.perlcode>$request->name("main");</hb-doc.perlcode></pre></p>

<p><hb-doc.todo>Document all the other methods.</hb-doc.todo></p>

</hb-doc trail="yes" back="perlhb.life" up="perlhb" next="">
:

:out hbperl
<hb-doc.incomplete>
:

