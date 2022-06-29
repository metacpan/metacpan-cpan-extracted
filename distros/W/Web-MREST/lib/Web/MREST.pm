# *************************************************************************
# Copyright (c) 2014-2022, SUSE LLC
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

package Web::MREST;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $core $site );
use App::CELL::Test qw( _touch );
use Data::Dumper;
use File::ShareDir;
use Log::Any::Adapter;
use Params::Validate qw( :all );
#use Try::Tiny;
use Web::Machine;




=head1 NAME

Web::MREST - Minimalistic REST server




=head1 VERSION

Version 0.290

=cut

our $VERSION = '0.290';


=head2 Development status

L<Web::MREST> is currently in "Alpha - feature freeze". There are almost
certainly bugs lurking in the code, but all features have been implemented.




=head1 SYNOPSIS

To take this module for a spin, execute this command:

    $ mrest-standalone

Leave this running, and from another console start the command-line client:

    $ mrest-cli

In the CLI client, type e.g.

    Web::MREST::CLI::Parser> get /

A 'GET' request will be sent for the root resource and the CLI client
will display a representation of the response.

A similar result can be obtained using C<curl>:

     curl -v http://localhost:5000/ -X GET -H "Content-Type: application/json"

For more information on using the CLI client, see L<Web::MREST::CLI>.



=head1 DESCRIPTION

MREST stands for "minimalistic" or "mechanical" REST server. (Mechanical because
it relies on L<Web::Machine>.)

L<Web::MREST> provides a fully functional REST server that can be started
with a simple command. Without modification, the server provides a set of 
generalized resources that can be used to demonstrate how the REST server
works, or for testing.

Developers can use L<Web::MREST> as a platform for implementing their own 
REST servers, as described below. L<App::Dochazka::REST> is a "real-world"
example of such a server.

For an introduction to REST and Web Services, see
L<Web::MREST::WebServicesIntro>.



=head1 RFC2616 AS A STATE MACHINE

RFC2616 is, of course, the HTTP 1.1 standard - not a state machine. But
the authors of "Web Machine" (which was originally implemented in Erlang) had a
neat idea to represent it as a state machine and use this to implement a server
for providing web services.

L<Web::Machine> is, of course, the Perl port of Web Machine.

L<Web::MREST> relies on L<Web::Machine> to implement RFC2616. L<Web::MREST>
can be thought of as an additional abstraction layer over L<Web::Machine>.

By itself, L<Web::Machine> is not a server. It does not listen on a port, for
example. Instead, it is designed to work (via L<Plack>) with a
L<PSGI>-compliant web server.

The web server hands incoming requests over to L<Web::Machine>, which runs the
requests through its state machine. (The L<Web::Machine> authors refer to the
state machine as "the FSM.") The best way to grasp the state machine is to
envision it as a flow-chart. At each "decision node" of the flow-chart - where
flow can go in one of two directions - L<Web::Machine> calls the method
corresponding to that node. Each node is designated by a letter and a number:
e.g. F7, O18, etc.

The flow-chart implemented by the FSM can be found L<here|http://...> - you are
encouraged to have that open for reference while reading this documentation
and implementing your REST server.




=head1 SERVER STARTUP AND INHERITANCE SCHEME


=head2 Standalone mode

As stated above, L<Web::MREST> is capable of operating independently. To try
it out, start up the server like this:

    $ mrest-standalone

And then point your browser to

    http://localhost:5000

If you look inside the C<mrest-standlone> script, you will see that it is
just a wrapper for the C<mrest> script, which takes two mandatory options. The
first, C<--distro>, is the name of the distribution in whose sharedir it should
look for configuration files. The second, C<--module>, is the name of the
application's resource module, i.e. the ultimate module in the chain of
inheritance.

In standalone mode, the actual command that is run is:

    mrest --distro=Web::MREST --module=Web::MREST::Dispatch

which causes the chain of inheritance to be built up as follows:

=over

=item C<bin/mrest> 

calls C<< Web::Machine->new >>; the L<Web::Machine> object is blessed into L<Web::MREST::Dispatch> 

=item L<Web::MREST::Dispatch> 

inherits from L<Web::MREST::Entity>

=item L<Web::MREST::Entity> 

inherits from L<Web::MREST::Resource>

=item L<Web::MREST::Resource> 

inherits from L<Web::Machine::Resource>

=back

When you browse to C<http://0:5000> in standalone mode, you get a list of the
sample REST resources that are available. For more information on these, see
C<config/dispatch_Config.pm>.


=head2 With your application

Starting the server with your application is the same as described in
L<"Standalone mode">, above, except that you replace C<Web-MREST> with the name
of your distribution and C<Web::MREST::Dispatch> with the name of your ultimate
resource module.

    $ mrest YourApp-MREST YourApp::MREST::Dispatch

For example, here we are starting the server with the distribution
C<YourApp-MREST>, which is presumed to implement a chain of inheritance
similar to L<Web::MREST>'s, i.e.:

    Web::MREST -> YourApp::MREST::Resource -> YourApp::MREST::Dispatch

Thanks to this arrangement, the application developer can customize
L<Web::MREST> - i.e., not only providing her own resources and handlers,
but even altering how the state machine operates, if necessary - by providing
her own chain of inheritance and overriding various methods within it.


=head3 Recapitulation

Since the above is quite important, let's go over it again:

The L<Web::MREST> documentation will always refer to your application either
as the "application" or as C<YourApp>. The application should take the form
of a Perl distribution, which should have:

=over

=item * a distribution sharedir

=item * a resource module, C<YourApp::Resource>.

=item * a dispatch module, C<YourApp::Dispatch>

=back

For now, just think of these three components as "black boxes". We will
cover their contents later.

The server (i.e. your application), is started by executing the C<mrest> 
executable with the name of your application's distribution and the name of its
dispatch module, which should be the ultimate module in the chain of
inheritance.

    $ mrest --distro YourApp --module YourApp::Dispatch

Under the hood the startup script, which can be reviewed at C<bin/mrest>, 
does essentially this:

    use Web::Machine;

    Web::Machine->new(
        resource => 'YourApp::Dispatch',
    )->to_app;

There are two key points concerning the L<Web::Machine> object constructed by
call to C<< Web::Machine->new >>: 

=over

=item 1. the object is blessed into C<YourApp::Dispatch>

=item 2. the object is a L<Plack> application

=back



=head1 INHERITANCE SCHEME

As seen in the previous section, C<YourApp> inherits from
L<Web::MREST> via a chain of inheritance. Here is the chain implemented by L<Web::MREST>:

 
    -> Web::MREST::Dispatch
        -> Web::MREST::Entity
            -> Web::MREST::Resource 
                -> Web::Machine::Resource
                    -> Plack::Component

Assuming L<YourApp> has its authentication and authorization routines
in L<YourApp::Resource> and its resource definitions and handlers in
L<YourApp::Dispatch>, the chain for L<YourApp> would look like this:

    -> YourApp::Dispatch
        -> YourApp::Resource
            -> Web::MREST::Entity
                -> Web::MREST::Resource 
                    -> Web::Machine::Resource
                        -> Plack::Component

(In other words, L<YourApp::Dispatch> and L<YourApp::Resource> replace
L<Web::MREST::Dispatch>, which is just a demo.)

When L<Web::Machine> reaches a given node in the FSM, it calls the
corresponding method on that L<Web::Machine> object. Since the object is
blessed into C<YourApp::Dispatch>, that module is where Perl will
start to look for the method.

If the method is not found at the lowest level, Perl follows the chain of
inheritance "upward". The highest level, L<Plack::Component>, is shown only for
completeness - L<Web::MREST::Resource> and L<Web::MREST::Entity> implement
all the methods that your resource module might (or should) want to override.

Readers who are not well-versed in writing Perl applications that use
inheritance are referred to the fine Perl manuals such as C<perlootut>.



=head1 STATE MACHINE INTRODUCTION

At this point we have enough background information to begin to grasp the state
machine. (Instead of writing "state machine" we will follow the L<Web::Machine>
convention of referring to it as the "FSM".) This section presents selected
features and nodes of the FSM, how L<Web::MREST> implements them, and how to
use them. The discourse proceeds in the order in which the methods are called
when an HTTP request enters the FSM.  We can envision these method calls as
decision nodes of a flow-chart, or "cogs" of the FSM.

And we needn't just imagine the flow-chart - it actually exists and can be 
downloaded from L<...>. If you want to understand how L<Web::Machine> and
L<Web::MREST> work, this document is of fundamental importance. Hereinafter
it will be referred to as "the FSM diagram".

As you can see in the FSM diagram, each FSM cog has a code like C<B6>, for ease
of reference.



=head1 POLICIES AND FEATURES

L<Web::Machine> implements the FSM, and that's all it does. In particular, it
imposes no policies on distributions that use it. By taking this approach,
L<Web::Machine> maximizes its range of potential uses.

Powerful as it is, L<Web::Machine> can be confusing to use. When I started
writing my first application based on it, I found myself wanting an
intermediate module between my application and L<Web::Machine> - something that
would make L<Web::Machine> a little more friendly.

L<Web::MREST> is that module. It builds on L<Web::Machine> in an effort to
provide certain additional features. Inevitably, this means imposing some
policies (i.e., limitations) on users. To me that seems like an acceptable
trade-off.


=head2 Path dispatch

A key part of any web application is "path dispatch" (i.e. URI translation),
which answers the question: "how are URIs mapped to resources?" 

Although L<Web::Machine> provides a way to specify handlers for various media
types that may appear in request and response entities, it provides no
way of getting from the URI to the handler. L<Web::MREST> bridges this gap
by providing a system of resource definitions (see L<"Resource definitions">,
below). 

The definition of each resource specifies the URI-to-resource mapping and
provides the name of the resource's handler method. Internally, L<Web::MREST>
uses a single L<Path::Router> object to parse URIs.

Before any URIs can be parsed, this L<Path::Router> object must be initialized.
This is done in L<Web::MREST::Resource>, in the C<service_available> method.
That method checks the scalar variable that is supposed to contain the
L<Path::Router> object and, if needed, calls the C<init_router> method to
initialize it.

In the L<Web::MREST> demo application, C<init_router> is implemented in
L<Web::MREST::Dispatch>. 


=head2 Resource handlers

The L<Web::Machine> documentation mentions "handlers" but doesn't go into
any detail on how to write them. L<Web::MREST> not only provides some working
resource handlers, but also implements a paradigm for writing them.

In this paradigm, the handler is called as a method, just like any of the other
methods in the chain of inheritance. (To avoid namespace issues, it is
recommended that handler method names start with C<handler_>.) The name of the
method is specified in the resource definition.

The handler method is called twice - in other words, there are two passes. In
the first pass, the handler is called with the argument C<1> (scalar value) and
is expected to return a boolean value indicating whether the resource exists.

In the second pass, indicated by the argument C<2> (scalar value), the handler
is expected to return a C<App::CELL::Status> object. This object (rendered in
JSON) becomes the response entity unless overrided by a declared status (see
C<mrest_declare_status> in L<Web::MREST::Resource>.

B<N.B.:> The request entity is not available to the handler (via
C<$self->context->{request_entity}> until the second pass!


=head2 Status objects

As mentioned in the previous section, L<App::CELL::Status> objects are returned
by resource handlers. Not only that - L<Web::MREST> tries its best to I<always>
return an L<App::CELL::Status> object in the response entity. 

Actually, it is not the object itself that is returned, but a JSON
representation of its underlying data structure. From this, the object can
easily be reconstituted on the client side by doing

    my $status = $JSON->decode( $response_entity );
    bless $status, 'App::CELL::Status';

For more on what status objects can do, see L<App::CELL::Status>, L<App::CELL>,
and L<App::CELL::Guide>.


=head2 Error statuses

L<Web::Machine> always tries to return the proper HTTP status code in the
response. The application developer will likely need to "force" a code in
certain cases. For example, the request may be "malformed" in a way that is
not discoverable until the handler runs. Or, caught exceptions may need to be
exposed to the client with C<500 - Internal Error>. 

Also, the RFC says

    . . . the server SHOULD include an entity containing an explanation of the
    error situation, and whether it is a temporary or permanent condition.

Clearly, then, a mechanism is needed for providing such explanations and
indicating whether the error is temporary or permanent. And that mechanism
should enable an arbitrary status code to be declared.

By itself, L<Web::Machine> does not really provide such a mechanism.  What it
does provide is a mechanism for "forcing" an arbitrary status code (e.g. C<404
- Not Found>) by returning a scalar reference. This mechanism has two
disadvantages:

=over

=item it is only available at certain junctions of the FSM 

I wanted a way to "declare" a status code at any point and be certain that
L<Web::Machine> won't change it later on.

=item there is no obvious way to provide an explanation of the error

L<Web::Machine> considers this an implementation detail.

=back

Hence, L<Web::MREST> provides the C<mrest_declare_status> method. To learn
how to call it and how it works, see L<Web::MREST::Resource>.



=head1 THE FINE STATE MACHINE

In this section we take a detailed look at the FSM by considering some common
scenarios. For our purposes these are C<GET>, C<POST>, C<PUT>, and C<DELETE>
requests. Handling can differ according to whether or not a C<POST> creates a
new resource and whether or not the resource is determined to exist.

=head2 Part One (sanity checks and information gathering)

The first few cogs are executed, in the same order, on all requests regardless
of method. They can be thought of both as a set of sanity checks and as an
information-gathering process.


=head3 C<service_available> (B13)

The first method call is C<service_available>, which is implemented by
L<Web::MREST::Resource> and should I<not> be implemented by your application,
because it calls C<init_router> to ensure that all the resource definitions are
loaded and the L<Path::Router> singleton is properly initialized.

This is not really a limitation, however. Whatever code you need to run here
can be placed in a method called C<mrest_service_available>, which should 
return a boolean value (i.e. 1 or 0), which determines the return value from
the method.

If the service really isn't available, you can return false, which will trigger
a C<503 Service Not Available> response. Before returning you should do:

    $self->mrest_declare_status( explanation => '...', permanent => 0 );

to provide an explanation of what is going on.

For details, see the C<t/503-Service-Unavailable.t> unit test.


=head3 C<known_methods> (B12)

Returns the list of supported ("known") methods in 
C<< $site->MREST_SUPPORTED_HTTP_METHODS >>. If the request method is not
in that list, a C<501 Not Implemented> response is returned along with
an explanation that the method requested is not supported.

If this behavior is not appropriate, the method can be implemented by the
application.


=head3 C<uri_too_long> (B11)

If the request URI is longer than the value set in the C<MREST_MAX_LENGTH_URI> site parameter,
the client will receive a C<414 Request URI Too Long> response.

To override this behavior, provide your own C<uri_too_long> routine in your
resource module.

This functionality is demonstrated by the C<t/414-Request-URI-Too-Long.t> unit.


=head3 C<allowed_methods> (B10)

"Is the method allowed on this resource?"

This next routine is where things start to get complicated. According to the
L<Web::Machine::Resource
documentation|https://metacpan.org/pod/Web::Machine::Resource#allowed_methods>,
we are expected to respond with a list of methods allowed on the resource. To
assemble such a list, we must first answer two questions: 

=over

=item 1. Have the resource definitions been loaded?

=item 2. Does the URI match a known resource?

=back

After the server starts, the first time this method is called triggers a 
call to the C<init_router> method, which populates the C<$resources> package
variable in C<Web::MREST::InitRouter> with all the resource definitions.
This is explained in detail in L<"Resource definitions">. This takes care of
the first question.

The second question is answered by C<Path::Router>. Once the request has
been associated with a known resource, completing our task becomes a matter of
getting and returning the set of methods for which the resource is defined.


=head3 C<malformed_request> (B9)

A true return value from this method triggers a "400 Bad Request" response
status. RFC2616 does not stipulate exactly what constitutes a bad request.
We already (in allowed_methods) took care of the case when the URI 
fails to match a known resource, and that includes applying any C<validations> 
properties from the resource definition. 

So, in this method (or your overlay) we take the "next step" (whatever that is)
in vetting the request. Keep in mind that this method is called before 
the resource handler. If you have any sanity checks you wish to apply _after_
the URI is matched to a resource but _before_ the resource handler fires, this
is the place to put them.

If you would like to keep L<Web::MREST>'s implementation of this method
(which, for example, pushes the Content-Length and Content-Type information
onto the context) and add your own logic, you can put it in
C<mrest_malformed_request> instead of overriding C<malformed_request> itself.

If you intend to return false from this method you should first do this:

    $self->mrest_declare_status( explanation => '...' );

to ensure that an explanation is included with the 400 response.


=head3 C<is_authorized> (B8)

In my mind, "authentication" is the process of determining who the user 
is, and "authorization" determines if the user is allowed to do what she
is asking to do. However, RFC2616 does not make such a clear distinction.

For that reason, it is left to the application to implement this method
if needed.


=head3 C<forbidden> (B7)

The same thoughts as expressed under C<is_authorized>, above, apply to 
this method as well.


=head3 C<valid_content_headers> (B6)

This is where you vet the C<Content-*> headers in the request. If the 
request contains any invalid C<Content-*> headers (i.e., if the '*' part
does not appear in << $site->MREST_VALID_CONTENT_HEADERS >>), 
a 501 will be generated.

The content headers are passed to the method in a L<Hash::MultiValue>
object.


=head3 C<known_content_type> (B5)

If the C<Content-Type> header is relevant - i.e., if this is a PUT or
POST request and if there is a request entity - check it against 
<< $site->MREST_SUPPORTED_CONTENT_TYPES >>.


=head3 C<valid_entity_length> (B4)

A simple routine that compares the entity length (in bytes) with the 
maximum set in C<< $site->MREST_MAX_LENGTH_REQUEST_BODY >>.


=head3 C<options> (B3)

If your application needs to support the C<OPTIONS> method, you should 
implement this yourself - otherwise, ignore it.


=head2 Part Two (content negotioation)

The HTTP standard provides some complicated logic to enable clients
and servers to "negotiate" the format (media type), language, encoding,
etc. in which content will be passed back and forth. Here in the L<Web::MREST>
documentation we gloss over this complexity and focus only on the media type. 
However, L<Web::Machine> includes methods for handling all the content
negotiation decision nodes and the application developer is free to take
advantage of them.

That said, L<Web::MREST> itself provides JSON handlers for both the request and
the response entities, and should be fully UTF-8 clean. Hopefully, this will
save application developers some work. (For more information, see L<"STATUS
OBJECTS AND ERROR HANDLING">.)

The following subsections detail the principal content negotiation methods.

=head3 C<content_types_provided>

As the L<Web::Machine::Resource> documentation states, this method must be
implemented (i.e., by the application) - otherwise, "your resource will not be
able to return any useful content".

Quoting further: "This should return an ARRAY of HASH ref pairs where the key
is the name of the media type and the value is a CODE ref (or name of a method)
which can provide a resource representation in that media type."

The implementation provided by L<Web::MREST> allows clients to specify (via
an C<Accept> header) one of two media types:

=over

=item C<text/html>

Since it is the first hashref pair of the two, it is the default. That means
if the incoming request does not have an C<Accept> header, the handler
specified for C<text/html> will be called to generate the response entity.

=item C<application/json>

This is the media type that L<Web::MREST> was written to support, both in
request entities and in response entities. However, there is nothing preventing
you as the application developer from specifying handlers for other media types.

=back

If the request includes an C<Accept> header, but none of the media types
specified in it are found in C<content_types_provided>, L<Web::Machine> will
generate a C<406 Not Acceptable> response. (Unfortunately, there is no easy way
for L<Web::MREST> or the application to know in advance that this error will be
triggered, so it will be returned "bare" - i.e., without any explanatory
response entity.)

In the normal case when an acceptable handler exists, it will be called to
generate the response - in other words, whatever is returned by the chosen
handler becomes the response entity, unless an error occurs inside the handler.
In that case, the handler should return a reference to a scalar value
(e.g., \400), which L<Web::Machine> will interpret as an HTTP response code.
See L<"STATUS OBJECTS AND ERROR HANDLING">.

For more on response entity generation, see the sections dedicated to the 
various HTTP methods (L<"GET">, L<"PUT">, L<"POST">, L<"DELETE">), below.


=head3 C<content_types_accepted>

When the client sends C<PUT> or C<POST> requests, it will typically provide a
'Content-Type' header specifying the media type of the bytes it is sending in
the request body. This content type is compared with the media types returned
by this method.  If there is no match, L<Web::Machine> returns a C<415
Unsupported Media Type> error response. (Unfortunately, there is no easy way
for L<Web::MREST> or the application to know in advance that this error will be
triggered, so it will be returned "bare" - i.e., without any explanatory
response entity.)


=head3 Other methods

For handling character sets, encodings, and languages, L<Web::Machine> provides
a number of other content negotiation methods:

=over

=item C<charsets_provided>

=item C<default_charset>

=item C<languages_provided>

=item C<encodings_provided>

=item C<variances>

=back

However, they are only needed if the application does complex content
negotiation.


=head2 Part Three (resource existence)

When we have made it past content negotiation, we know more than just which
routines will be used to process the request entity (if any) and generate the
response. We have gathered quite a bit of information about the request. All
this information has been pushed onto the context, so it is available to all
our resource methods, including the resource handler which we will get to
presently. This information includes:

(FIXME: verify this list as it is outdated)

=over

=item C<method>

The request method

=item C<resource_name>

The resource name, which can be used as a key to look up the full resource
definition in the C<< $Web::MREST::InitRouter::resources >> 

=item C<handler_name>

The name of the resource handler, e.g. C<handler_bugreport>. In L<Web::MREST>, 
the resource handlers reside in the L<Web::MREST::Dispatch> module.

=item C<uri>

The full URI provided with the request

=item C<uri_base>

The base part of the URI (e.g. "http://localhost:5000/" )

=item C<uri_path>

The relative path to the resource (e.g. "/bugreport")

=item C<components>

Reference to an array the elements of which are the individual 'components' 
(i.e., everything between the '/' characters) of the C<uri_path>

=item C<mapping>

A hashref mapping resource parameter names (if any) to their values

=item C<content-length>

The content-length header.

=item C<content-type>

The content-type header.

=back

One major piece of information is missing, however: whether the resource exists
or not. For that, we have to actually call the resource handler. 


=head3 C<resource_exists> (G7)

The term "resource" is not precisely defined. It can refer to the resource
definition (a data structure), the resource handler (a Perl subroutine called
as an object method), or an object (set of records) in an underlying database. 
Or it can refer to all of the above, or to something else. The following
paragraphs describe L<Web::MREST>'s approach.

By the time control reaches this method, the request URI has already been
matched to a resource definition. So the resource handler is known.  Since we
have no other way of knowing, we ask the resource itself, by calling the
handler with the scalar value C<1> (i.e. the numeral 1) as the sole argument.
This handler call is referred to as the "first pass".

How the handler is implemented does not concern us. We only ask that it return
a boolean value (true or false) when called with this argument. If the return
value from the handler is true, we can assume that the handler will be called
again (second pass) in the response generation phase - read on.


=head2 Part Four (generation of response entity)

At this point we have

=over

=item gathered information about the request and placed it on the context

=item run the resource handler (first pass) to determine resource existence

=back

Up until now (i.e., through determination of resource existence), the FSM
has been a series of steps applied, in the same order, regardless of the
HTTP method.

In the sections below, we examine how responses are generated for each of
four HTTP methods (C<GET>, C<PUT>, C<POST>, and C<DELETE>) when the resource
exists and when it doesn't exist.

=head3 Resource exists

=head4 C<GET>

=over

=item 1. C<content_types_provided> method call

First, C<content_types_provided> is called to determine the name of the
method that is capable of generating the response in the required format.
This method is the one we mean when we refer to the "response generator".

=item 2. Response generator method call

Second, the response generator is called (from C<o18> in
L<Web::Machine::FSM::States>). It is expected to always return an
L<App::CELL::Status> object. If an error condition is detected, the
handler should declare it using C<< $self->mrest_declare_status >>
and then return a "non_ok" status.

=back

C<GET> is the only request method that demands a response entity
in the format specified by the C<Accept> header. For the other methods,
response entities are optional, but recommended. In practice, this
means that we have to create them ourselves.


=head4 C<POST>

Here we have two possible paths, depending on the value returned by
C<post_is_create>:

=over

=item C<post_is_create> true

=over

=item C<create_path> and C<create_path_after_handler>

If, and only if, C<post_is_create> is true, processing continues via
C<create_path> and C<create_path_after_handler>. Depending on the value of the
latter, the request handler (determined by consulting
C<content_types_accepted>) is called either before or after C<create_path>.

The request handler should stage the response entity in preparation for
finalization. The content type can be inferred from 
C<< $request->env->{'web.machine.context'} >>.

=item Finalization

Request is finalized by a call to C<finish_request>.

=back

=item C<post_is_create> false

If C<post_is_create> returns false, all bets are off. For reasons I do not
understand, L<Web::Machine> does not consult C<content_types_provided> or
C<content_types_accepted> on this type of request. The only thing it does is
call C<process_post>, and so it is up to this method to do whatever needs to be
done to generate an entity and get it into the response.

L<Web::MREST> helps by making sure that the content type is stored in the
context (in the C<'content_type'> property), so C<process_post> can look 
there for it and generate the response entity accordingly.

=back


=head4 C<PUT>

On all C<PUT> requests, and those C<POST> requests that are handled as
C<PUT> requests (see above), L<Web::Machine> uses the following process:

=over

=item C<content_types_accepted>

This method is called to determine the name of the method that can process
the request body. This method is expected not only to process the request
body, but also to generate the response. Therefore, we refer to this 
method as the "response generator" for C<PUT> requests.

=item Response generator method call

Next, the response generator is called. For C<PUT> requests, the response
generator is determined from C<content_types_accepted> based on the Here again, the method referred
to by C<content_types_provided> is not called by L<Web::Machine>, but the
response generator is free to call C<content_types_provided> and find
out the method itself, and call it. Or do something else.

When C<resource_exists> is true, the response generator is called from C<o14>
in L<Web::Machine::FSM::States>.

=back

Whenever a new resource is created, a C<Location> header is added to
the response with the URI path of the new resource.

In general, we understand C<PUT> to be a request to write to a resource.
Typically, this will involve either creating (INSERT) or modifying (UPDATE) one
or more database records/objects. 

Therefore, it has to be possible for a URI to resolve to a resource that 
does not yet exist. For example:

    PUT employee/nick/Bubba

There may or may not be an employee by the name of Bubba in the database,
but if we have a resource called 'employee/nick/:nick', Path::Router will
match it in C<allowed_methods> and the resource handler will be called in
C<resource_exists> - up until this point, the same sequence of method 
calls is used for C<GET>, C<POST>, C<PUT>, and C<DELETE>.

L<Web::MREST> has no way of knowing whether there is an employee named Bubba.
It is up to the handler to determine this, and then do an INSERT or UPDATE
operation as appropriate. This operation is not expected to fail, but if it
does fail the handler should force a 4xx or 5xx status code (and provide an
explanation) by calling C<< $self->mrest_declare_status >>.

If the request causes a new object - and, hence, a new resource - to be
created, the handler should cause a C<Location> header with the URI of the
new resource to be added to the response. This tells L<Web::Machine> to 
set the response status to C<201 Created>.

If the request only modifies an existing object/resource, simply do not
add a C<Location> header to the response. This will cause L<Web::Machine>
to return a C<200 OK> status in the response.


=head4 C<DELETE>

For C<DELETE>, two methods are called: C<delete_resource> and
C<delete_completed>. The C<delete_resource> method should enact the delete
operation and generate the response entity. The second method, C<delete_completed>,
is for cases when the delete operation cannot be guaranteed to have completed -
this method defaults to false, but if it returns true L<Web::Machine> will 
trigger a C<...> response.


=head3 Resource does not exist

=head4 C<GET>

Request goes to finalization with 404 status.

=head4 C<POST>

Request goes to C<allow_missing_post>, which always returns false in
L<Web::MREST>'s implementation.

After that, the request goes to finalization with 404 status.

If the 

=head4 C<PUT>



=head2 C<finish_request>

The previous sections should suffice for the reader to gain a degree of
understanding of how the state machine works for various types of requests, and
how L<Web::MREST> interfaces with the response handlers.

The last cog of the FSM is C<finish_request>.



=head1 IN-DEPTH DISCUSSIONS OF VARIOUS TOPICS

=head2 Resource definitions

As we read in the "crash course" above, resources are central to what a REST
server is and does: the server processes incoming requests. Each request has
a URI which resolves (or does not resolve) to a resource. Resources are 
defined as module variables: each module that contains resource handlers
should also define a module variable (via C<our $resource_defs = { ... };>)
containing the definitions of the resources covered by that module.

The top-level dispatch module, L<Web::MREST::Dispatch>, should implement
a method called C<init_router> which calls the function

    Web::MREST::InitRouter::load_resource_defs

for all the resource-defining modules. When the first HTTP request comes in,
L<Web::MREST::Resource> calls the C<init_router> method. This only happens
once, ensuring that the resource definitions are fully loaded for the first -
and all subsequent - requests.

Each resource definition is a hashref consisting of a number of properties.
This definition hashref is itself included in the C<$resources> package
hashref, which essentially looks like this:

    {
        RESOURCE_NAME => RESOURCE_DEFINTION,
        RESOURCE_NAME => RESOURCE_DEFINTION,
        RESOURCE_NAME => RESOURCE_DEFINTION,
    }

where C<RESOURCE_NAME> is a resource name (a string like C<'/'> or
C<'docu/text'>) and C<RESOURCE_DEFINITION> is that resource's definition
hashref.

The root resource should be defined under the name C<'/'> and top-level
resources should have a C<parent> property set to this string.

In the resource definition, properties can be specified either as a
scalar value, in which case the definition applies to all the methods
specified in C<< $site->MREST_SUPPORTED_HTTP_METHODS >>, or as a 
hashref in case the given resource is only defined for certain methods.

In the latter case, it is not necessary to define all properties as
hashrefs. The set of permitted methods will always be taken from the 
'handler' property. For example in this snippet whizzo_resource is only
defined for the GET method, and that will be applied to 'foo' (and the
rest of this resource's properties) as well.

    'whizzo_resource' => {
        'handler' => {
            'GET' => 'some_method',
        },
        'foo' => 'barbazbat',
        ...
    }

So 'foo' will only be defined for the GET method.

Examples: 

    'foo_prop' => 'value applied to all available methods',

    'bar_prop' => { 
        'GET' => 'value applied to GET requests', 
        'POST' => 'value applied to POST requests', 
    },

There is one required property, 'handler', which is used to specify the
handler(s) for the resource (see the examples below). The value of this
property is taken to be the name of a method. This method call looks
like this:

    $self->$handler

and is located in Web::MREST::Resource->resource_exists

(The inheritance chain is set up in C<bin/mrest> - the server startup script -
and via C<use parent> statements in the various modules that make up the
inheritance chain.)

In addition, each resource may have any properties you, the application
developer, wish to invest in it. For our 'docu' methods we use the
properties 'description' and 'documentation', for example.

Two properties - 'parent' and 'validations' - are
exceptions to the above and should never be defined on a per-method
basis:

    - 'validations' contains validation checks to be applied when matching
      URI to resource (for more information, see the Path::Router
      documentation). 
   
    - 'parent' contains the name of the resource's parent resource
      (defaults to '' - the root resource)

    - 'documentation' is reserved for the self-documentation feature



=head3 C<Path::Router> object initialization

When the server starts, the C<MREST_RESOURCE_DEFINITIONS> and
C<MREST_ROOT_RESOURCE> meta parameters are initialized from the configuration
file C<config/dispatch_MetaConfig.pm> in the L<Web::MREST> distribution.

The application developer will of course want to define her own set of
resources. This should be done by manipulating the meta parameters
C<MREST_RESOURCE_DEFINITIONS> and C<MREST_ROOT_RESOURCE>. A good place
to do this is in the application's C<mrest_init_router> routine. 

Here are two approaches to defining the application's resources, depending on
whether the application wishes to retain the L<Web::MREST> resources.  

=over

=item 1. retain

    package MyApp::Resource;

    use Clone 'clone';
    use parent 'Web::MREST::Resource';

    # We assume that the application somehow loads its resource definitions
    # (including the root resource) into a package variable $r_defs -- for
    # example by hard-coding them like this
    my $r_defs = { ... };

    # ----------------------------------------
    # mrest_init_router - called by Web::MREST
    # ----------------------------------------
    sub mrest_init_router {
        my $self = shift;

        # set up the root resource
        $meta->set( 'MREST_ROOT_RESOURCE', $r_defs->{''} );
        delete $r_defs->{''};

        # set up the remaining resources, retaining (but possibly
        # overwriting) the Web::MREST default resources
        my $mrest_defs = clone( $meta->MREST_RESOURCE_DEFINITIONS );
        foreach my $r_name ( keys %$r_defs ) {
            $mrest_defs->{$r_name} = $r_defs->{$r_name};
        }
        $meta->set( 'MREST_RESOURCE_DEFINITIONS', $mrest_defs );
    }

=item 2. do not retain

This approach is more simple because no C<mrest_init_router> need be written.
The application should have its own distro sharedir C<config/> and therein a
file C<dispatch_MetaConfig.pm>.  Inside that file, the application puts its own
resource definitions in the C<MREST_RESOURCE_DEFINITIONS> and
C<MREST_ROOT_RESOURCE> parameters (refer to C<config/dispatch_MetaConfig.pm> in
the L<Web::MREST> distribution for syntax and semantics).

The application's definitions will overlay (i.e. replace) those of
L<Web::MREST>.  Even in this scenario, some or all of L<Web::MREST>'s resources
could be used in the application, but only by copy-pasting the definitions and
their respective handlers into the application's source code.

=back


=head3 Tree structure

L<Web::MFILE> allows resources to be defined in a tree structure.  It is
designed to allow a tree structure to be described in a flat configuration
file. The C<MREST_RESOURCE_DEFINITIONS> hash is keyed on the resource name.
Child resources are indicated by including a C<parent> property with the name
of the parent resource. Care should be exercised not to introduce any circular
references.

If a flat structure is desired, simply do not include any C<parent> properties
in your resource definitions.

The format of C<MREST_RESOURCE_DEFINITIONS> hash is documented in
C<config/dispatch_MetaConfig.pm>. 


=head3 C<< $Web::MREST::InitRouter::resources >> 

The resource definition hashrefs in the dispatch modules are designed to be
written and maintained by humans. When the C<init_router> method runs, it loops
over all the resource definitions and builds up a second hash,
C<< $Web::MREST::InitRouter::resources >>, which contains the same information
in a format that is more convenient for automated processing.

Since the resource definitions are a potential source of typographical and
semantic errors, you should dump this package variable to the log and examine
it to make sure your resource definitions are being processed correctly.


=head2 Errors

As we move through the state machine (i.e. the chain of method calls driven
by L<Web::Machine>), we build up a "context" from which we generate the HTTP
response. Stated very simply, the response code can either be 'OK' (200) or
"something else" - i.e., an error of some kind.

And, indeed, checking for errors accounts for a large portion of what our
resource modules do. As RFC2616 explains, errors can be divided into two
brought classes: client errors and server errors.

=over

=item Client errors (4xx)

Client errors have status codes that start with 4 (e.g. 400, 401, 404).

RFC2616 has this to say about them:

    The 4xx class of status code is intended for cases in which the client
    seems to have erred. Except when responding to a HEAD request, the server
    SHOULD include an entity containing an explanation of the error situation, and
    whether it is a temporary or permanent condition. These status codes are
    applicable to any request method. User agents SHOULD display any included
    entity to the user.

=item Server errors (5xx)

Server errors have codes beginning with th digit "5". According to RFC2616,
they

    indicate cases in which the server is aware that it has erred or is
    incapable of performing the request. Except when responding to a HEAD
    request, the server SHOULD include an entity containing an explanation of
    the error situation, and whether it is a temporary or permanent condition.
    User agents SHOULD display any included entity to the user. These response
    codes are applicable to any request method. 

=back

The key point here is that it is not sufficient to return a bare 4xx or 5xx
response status code. The response should include an entity body with an
explanation of the error condition. 

=head3 How to provide explanation in response entity

L<Web::MREST> provides a mechanism for adding the explanation to the entity
body as called for by RFC2616. At the exact place in your resource module
where you discover the error, do something like this:

    $self->mrest_declare_status( code => '400', explanation => 'You messed up' );

This will be converted into the respective L<App::CELL::Status> object and
returned in the response entity. The object will have properties like this:

    { 
        level => 'ERR',
        code => 'You messed up',
        payload => {
            http_code => '500',
            uri_path => ... (taken from the context),
            resource_name => ... (taken from the context),
            found_in => ... (taken from 'caller'),
            permanent => JSON::true (the default),
        },
    }

Alternatively, you can pass in your own arbitary L<App::CELL::Status> object.

To see how the L<App::CELL::Status> object becomes the response entity, see
the C<finish_request> method in L<Web::MREST::Resource>.


=head2 Context

Typically referred to as C<$context>, the "MREST context" is a hashref that is
built up during the course of request processing. In addition to being used
within L<Web::MREST::Resource>, it is always sent as an argument whenever
L<Web::MREST::Resource> calls a hook, so the developer can modify it in her
implementations of the various hook routines.


=head2 Authentication

Ever since the Big Bad Wolf ate Granny, authentication mechanisms have been
prone to abuse by individuals who are willing to lie about their identity.

Humans are good at distinguishing one human from another, provided they can
apply all their senses to the task. Computers lack proper senses and are
downright awful at this task. Computerized authentication schemes typically
operate by presenting the user with one or more hoops to jump through. Whoever
succeeds at this task is deemed to be the user. What could go wrong?

Passwords (or passphrases) are the "hoop" most frequently used to authenticate
users and keep would-be intruders out. Therefore, a system's security is often
gauged by how well it protects user credentials from disclosure. Since
usernames are public, the only thing keeping a determined intruder at bay are
the passwords, and various measures are taken to protect them. 

From the perspective of L<Web::Machine>, authentication is a matter of 
calling the L<is_authorized> method. If the return value is false, the response
will be C<401 Unauthorized>. If it is true, request processing continues.
Whatever authentication measures the application developer decides to implement
should be triggered by this method call.

For more about L<is_authorized>, see the L<Web::Machine::Resource documentation|https://metacpan.org/pod/Web::Machine::Resource#is_authorized-authorization_header>



=head2 Authorization

Once authentication has determined the user's identity, a related task,
authorization, begins. As the name would imply (and the RFC's vague
use of the term "authorization" notwithstanding), authorization answers
the question:

    Is this specific user authorized to make this request?

Compare this with authentication, which answers a different question:

    Is this user really who they are purporting to be?

Or, even more pithily:

    Who is this user?

Authorization implies a boolean "function" (in both the mathematical and
computer science sense) that takes three arguments: the username, the HTTP
method, and the resource. Implementation of this function is left to the
application developer.

It is worth noting here that L<Web::Machine> provides a C<forbidden> method.
Since C<is_authorized> is already taken for authentication, we can use
C<forbidden> for authorization. Just be sure to understand thoroughly that
a true return value from C<forbidden> means "not authorized".


=head2 Customized URI parsing

While L<Web::MREST> provides for URI parsing using L<Path::Router>, if this is
not desired the application developer can parse URIs herself by simply
substituting her own C<init_router> and C<match> methods for the ones provided
by L<Path::Router> and L<Path::Router::Route::Match>, respectively.

When request processing enters C<resource_exists>, 
Alternatively, the application developer can overlay the C<init_router> routine
with one that returns an arbitrary object (stored in C<$router>) that has a
C<match> method. After that, L<Web::MREST> does

    my $match = $router->match( $path );

where C<$path> is the relative portion of the URI (i.e. everything left after
the C<http://myapp.example.com/> part is cut off).

The C<$match> object should provide a C<route> method, which should return the
definition of the matched resource. See L<"RESOURCE DEFINITIONS">.


=head1 FUNCTIONS IN THIS MODULE

=head2 init

Do initialization-like things, such as loading configuration parameters.
Takes a PARAMHASH which can contain one of the following:

=over

=item C<distro>

The name of the application distribution from which the distro sharedir will be
loaded.

=item C<path>

The name (full path) of a directory containing the application's configuration
files.

=item C<hashref>

A reference to a hash containing meta parameters to be loaded.

=back

=cut 

sub init {
    my %ARGS = validate( @_, {
        distro => { type => SCALAR, optional => 1 },
        sitedir => { type => SCALAR, optional => 1 },
        hashref => { type => HASHREF, optional => 1 },
        early_debug => { type => SCALAR, optional => 1 },
    } );
    
    my $tf = $ARGS{'early_debug'};
    if ( $tf ) {
        _touch $tf;
        if ( -r $tf and -w $tf ) {
            unlink $tf;
            Log::Any::Adapter->set( 'File', $tf );
            $log->debug( __PACKAGE__ . "::init activating early debug logging to $tf" );
        } else {
            print "Given unreadable/unwritable early debugging filespec $tf\n";
        }
    }

    # always load Web::MREST's configuration parameters
    my $target = File::ShareDir::dist_dir('Web-MREST');
    $log->debug( "About to load Web::MREST configuration parameters from $target" );
    my $status = $CELL->load( sitedir => $target, verbose => 1 );
    return $status if $status->not_ok;

    $meta->set( 'MREST_EARLY_DEBUGGING', $tf );

    # if argument provided, load that, too
    if ( %ARGS ) {
        $target = undef;
        if ( $ARGS{'distro'} and $ARGS{'distro'} ne 'Web-MREST' ) {
            # distro must be given as "MyApp-Foo", not "MyApp::Foo"
            $target = File::ShareDir::dist_dir( $ARGS{'distro'} );
            $status = $CELL->load( sitedir => $target );
            return $status if $status->not_ok;
        }
        if ( my $sitedir_target = $ARGS{'sitedir'} ) {
            if ( -d $sitedir_target ) {
                $status = $CELL->load( sitedir => $sitedir_target );
                return $status if $status->not_ok;
            } else {
                $log->warn( 'Web::MREST::init() says sitedir argument given, but it is not a directory: ' .
                    Dumper( $sitedir_target ) );
            }
        }
        if ( $ARGS{'hashref'} ) {
            my $count = 0;
            foreach my $key ( keys %{ $ARGS{'hashref'} } ) {
                $meta->set( $key, $ARGS{'hashref'}->{$key} );
                $count += 1;
            }
            $log->notice( "Web::MREST::init loaded $count meta parameters from a hashref" );
        }
    }

    return $CELL->status_ok;
}


=head2 version

Accessor method (to be called like a constructor) providing access to C<$VERSION> variable

=cut

sub version { $VERSION; }

1;
