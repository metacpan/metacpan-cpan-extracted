# ************************************************************************* 
# Copyright (c) 2014-2015-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

package Web::MREST::WebServicesIntro;

use 5.012;
use strict;
use warnings;


=head1 NAME

Web::MREST::WebServicesIntro - General discussion of REST and Web Services




=head1 GENERAL DISCUSSION OF REST AND WEB SERVICES

Before you try to implement a REST server using L<Web::MREST>, you might want
to take a look at our "prerequisites". The heading of each subsection below 
describes the prerequisite. However, the text under each subsection heading 
should B<not> be taken as an authoritative discourse on the subject. 


=head2 Know what Web Services are

A "Web Service" is a client-server application that uses the HTTP protocol for 
communications between client and server. More specifically, the client
attempts to open a TCP connection to a pre-defined host and port where the
server is listening. Once a connection is open, the client and server
communicate in HTTP.

Web Services can run on any TCP/IP network - the public Internet is one
example, but many Web Services run on corporate intranets, for example. A
developer will typically have an isolated testing network on his own machine,
etc.


=head2 Know what a RESTful Web Service is

Before you write a REST server, you should probably learn what a REST server
is. Here is a crash course. 

Even if you _think_ you know what a REST server is, it might be useful to
either skim this crash course or, even better, just read L<Leonard Richardson's
paper|http://www.crummy.com/writing/speaking/2008-QCon/act3.html> which this
"crash course" attempts to paraphrase. 


=head3 Introduction

REST is an approach to implementing client-server software architecture, in
which communications between client and server use the HTTP protocol. It turns
out that HTTP is "good enough" for many applications, and using it can save a
lot of work.

I urge all prospective REST server developers to study and "grok" the
L<Richardson REST Maturity Model|http://www.crummy.com/writing/speaking/2008-QCon/act3.html>, 
since it is the conceptual basis for this discourse.


=head3 More than a web server

Providing a Web Service implies having a web server. L<Web::MREST> does this
for you, with help from L<Web::Machine> and L<Plack>.

But the mere presence of a web server does not make a Web Service "RESTful". 


=head3 Level 0: tunnelling mechanism

Some notorious Web Services - such as those based on the XML-RPC and SOAP
technologies - use HTTP as a tunnelling mechanism. In this paradigm, each
client message is serialized and sent to the server in the body of a C<POST>
request. The server always responds with a 200 status code, which in this case
signifies no more than that the message was received and processed, and the
server's serialized response is placed in the response body.

Richardson calls this "One URI, one HTTP method".

Example HTTP request:

    Method:       POST 
    URI:          http://myapp.example.com/
    Header:       Accept: application/json
    Body:         { 
                      "command" : "employee.insert",
                      "arguments" : { ... }
                  }

Example HTTP response:

    Status code:  200 OK
    Content-Type: application/json
    Body:         {
                      "status" : {
                          "level" : "ERROR",
                          "code" : "MYAPP_INSUFFICIENT_PRIVS",
                          "text" : "Insufficient privileges"
                      }
                  }

To quote Richardson:

    If you look at an XML-RPC service, or a typical SOAP service . . ., you'll
    see something that looks a lot like a C library. There are a bunch of functions,
    sometimes namespaced with periods. All of these functions are accessed by
    sending a POST request to one single URI.


=head3 Level 1: resources

The next step, which Richardson calls "Many URIs, one HTTP method", involves
moving some part of the XML/JSON body into the URI. Though this step might seem
insignificant, calling it "revolutionary" would be closer to the truth.

Let's apply this to our example. If employees can be uniquely identified by
their nick, a request for employee "simona" might look like this:

    Method:        POST
    URI:           http://myapp.example.com/employee/nick/simona
    Header:        Accept: application/json
    Body:          {
                        "command" : "GET"
                   }

By moving the object specification to the URI, I<the object becomes a web
resource>, and this is what makes it "revolutionary".

The very purpose of the HTTP standard is to facilitate the publishing and
manipulation of web resources, and the URI is the "Uniform Resource
Identifier". Moving from level 0 to level 1 involves the same paradigm shift as
embracing OO principles in your code. 

But even if you already were using OO principles in the underlying code, what
benefit is there in bundling the object identifier in the HTTP request body?
The Uniform Resource Identifier (URI) is the right tool for that.


=head3 Level 2: HTTP verbs

If you know about HTTP methods, the previous example should cry out to you (or,
rather, you might cry out to it): "why are they using C<POST> for a GET
request?!" And, while it may seem astonishing, that is exactly what many Web
Services do (or used to do before Richardson published his influential paper).

The next "level" in Richardson's structure involves leveraging HTTP methods to 
distinguish read requests, which should be idempotent, from write requests,
which modify the underlying data. When this distinction is hidden in the API, 
there is no way for client code to optimize read-only requests.

Illustrating with our example:

    Method:        GET
    URI:           http://myapp.example.com/employee/nick/simona

The barest glace is enough to make it obvious that this request is far simpler
than its level 1 equivalent. At level 2, the server guarantees that GET
requests will never change the data, and that means your client code can
dispense with whatever special precautions it needs to take to prevent unwanted
modifications.

Richardson's designation for this level is: "Many URIs, each supporting
multiple HTTP methods".  Quoting Richardson again to drive the point home:

    The web is powerful because it gives you tools for splitting the inherent
    complexity of a task into small chunks. The URI lets you give a name to
    every object in the system. With URIs, every object can be a little bit 
    complex. That's the URI level. On the HTTP level, the major advance of the
    web is that although it can handle any kind of operation, it splits out
    read operations, operations that want to fetch data, and treats them specially.

Taking our example a little bit further, let's say we want to create a new
employee at this level. Here's what the request might look like:

    Method:        PUT
    URI:           http://myapp.example.com/employee/nick/george
    Header:        Accept: application/json
    Body:          {
                       "name" : "George III",
                       "occupation" : "King of England"
                       ...
                   }

The important point here is that the request body now contains content only -
no command or function name. The role of the function name is taken over by the
combination of HTTP method and URI.

Now we are really using HTTP to its fullest potential. Or are we?


=head3 Level 3: hypermedia controls

Until this point, the discourse has been easy to follow. Yet, Richardson
describes a third level, "hypermedia", which he defines as:

    Resources describe their own capabilities and interconnections

This is also sometimes referred to as "Hypermedia As The Engine Of Application
State", or HATEOAS. As Richardson himself acknowledges, this is where the
enthusiasm starts to fade.

According to Richardson, whereas level 1 is "the lesson of URIs" and level 2 is
"the lesson of HTTP", the lesson we learn at this level is "the lesson of
HTML". That is because HTML is an example of hypermedia controls that we are
all familiar with. Generalizing this, we can say that a HATEOAS client
"navigates" its server very much like a human surfs the web, that is: by
parsing and following links. Just like on the WWW, in a HATEOAS application,
resources link to other resources and, crucially, I<those links are expressed
as URIs>.

Returning to our example, let us say that our employee objects link to
occupation objects. Inside the database, each occupation is identified by its
"occupation_id", an integer value, and linked tables use this as a foreign key.
Without hypermedia controls, our request for employee "george" and the server's
response (the part following the '*') might look like this:

    Method:        GET
    URI:           http://myapp.example.com/employee/nick/george
    *
    Status code:   200 OK
    Content-Type:  application/json
    Body:          {
                       "name" : "George III",
                       "occupation_id" : 553,
                       ...
                   } 

In HATEOAS, the same request/response might look like this:

    Method:        GET
    URI:           http://myapp.example.com/employee/nick/george
    *
    Status code:   200 OK
    Content-Type:  application/json
    Body:          {
                       "name" : "George III",
                       "occupation" : {
                           "link" : {
                               "href" : "http://myapp.example.com/occupation/catalog/553,
                               "rel" : "http://myapp.example.com/occupation",
                               "name" : "King of England"
                            },
                       ...
                   } 

While at first glance it seems more complicated, this approach (which we will
call the HATEOAS approach) is superior to the non-HATEOAS approach illustrated
by the first example.

In the non-HATEOAS version, the client code needs to know that occupation objects
are identified by their 'occupation_id' property. Further, to gain access to
the object it needs to know how to transform the occupation ID into the
appropriate resource so it can issue a GET request for it.

By putting the full URI of the occupation resource into the response, the client
no longer needs to know any of that. To get the resource, it directly issues a
GET request to the URI provided in 'href'.

But the "link" property gives us more than this. From the additional properties
the client can, for example, derive that the resource can be modified by
issuing a C<POST> request to C<http://myapp.example.com/occupation> and
including the "name" property (with the value "King of England") in the request
body.  

The non-HATEOAS variant, by contrast, provides nothing more than a
number. The "knowledge" of what can be done with it must be embedded in the
client code. As Richardson notes, this makes client code more brittle. He cites
examples of RESTful Web Service projects where clients were abandoned
after being broken repeatedly by server-side changes to the REST API.


=head3 Conclusion

There is more that can be done with the HATEOAS approach, of course, than
provide URI links in the HTTP response. The idea is for clients to get
information on their state from the server via HTTP. This should make the
clients less prone to breakage when changes are made on the server side.

=cut

1;

