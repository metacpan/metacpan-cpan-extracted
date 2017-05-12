package Netscape::Server::Request;

# -------------------------------------------------------------------
#   Request.pm - Interface to NSAPI Request structure
#
#   Copyright (C) 1997, 1998 Benjamin Sugars
#
#   This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# 
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this software. If not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
# -------------------------------------------------------------------

use strict;
use vars qw(@ISA);

require DynaLoader;

@ISA = qw(AutoLoader DynaLoader);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Netscape::Server::Request - Perl interface to Netscape server Request

=head1 SYNOPSIS

 package Netscape::Server::Something;
 use Netscape::Server qw/:all/;

 sub handler {
     my($pb, $sn, $rq) = @_;
     ...
     $auth_type = $rq->auth_type;
     $path_info = $rq->path_info;
     $query_string = $rq->query_string;
     $remote_user = $rq->remote_user;
     $request_method = $rq->request_method;
     $server_protocol = $rq->server_protocol;
     $user_agent = $rq->user_agent;
     $vars = $rq->vars;
     $reqpb = $rq->reqpb;
     $headers = $rq->headers;
     $srvhdrs = $rq->srvhdrs;
     $rq->protocol_status($sn, $status, $reason);
     $proceed = $rq->protocol_start_response($sn, $rq);
     ...
 }

=head1 DESCRIPTION

The Netscape::Server::Request class provides a Perl-object interface
to the Netscape Server API Request structure.  Instances of the
Netscape::Server::Request structure are passed as arguments to all
Perl subroutines that are executed by a Netscape server that has been
integrated with Perl using nsapi_perl.

For an overview of integrating Perl and NSAPI, see L<nsapi_perl>.
Suffice it to say here that nsapi_perl provides a mechanism by which a
Perl interpreter is embedded into a Netscape server.  The NSAPI can
then be programmed to in Perl rather than in C.  This is acheived by
placing the appropriate hooks in the server configuration files;
nsapi_perl will then call whatever Perl subroutines you wish at
various stages of processing a request from a client.

When a Perl subroutine is called by nsapi_perl, it is passed three
arguments:

 my($pb, $sn, $rq) = @_;

I<$pb> is a reference to hash to the I<key=value> pairs passed to the
argument from the server configuration files; see L<nsapi_perl> for
more details.  I<$sn> is an instance of Netscape::Server::Session
which has its own man page. I<$rq> is an instance of
Netscape::Server::Request and is the subject of the rest of this
document.

=head1 OBJECT ABSTRACTION

A request in the world of the NSAPI is an entity that encapsulates the
header data sent from the client and header data sent back by the
server during an http transaction. In addition, information internal
to the server generated in during a transaction is considered part of
a request.  In the NSAPI all this information is maintained in a C
structure called a I<Request>.

Netscape::Server::Request provides a Perl interface to the Request
structure.  It also provides methods that cause the server to perform
an action based on the current state of the request.

Some Netscape::Server::Request methods require that an instance of
Netcape::Server::Session be passed as an argument.  You will find that
those methods requiring this will have a synonym method defined in
Netscape::Server::Session.  This is so you don't have to remember
whether such a method is to be written as

 $rq->method($sn);

or

 $sn->method($rq);

where $rq is an instance of Netscape::Server::Request and $sn is an
instance of Netscape::Server::Session.  Either method call will do the
same thing.

=head1 INSTANCE METHODS

Netscape::Server::Request methods can be divided into those that
return request attributes, those that access server variables, and
those that perform actions.

=head2 Request Attributes

These methods return or set attributes of the request.

=over 4

=item B<auth_type>

 $auth_type = $rq->auth_type($type);

With no arguments returns the authorization type of the request.  This
will either be 'basic' if authorization has been provided by the
client or undef if the client provided no authorization.  The $type
argument sets the authorization to the value of $type.

=item B<path_info>

 $path_info = $rq->path_info($path);

With no arguments returns the extra path information appended to the
URI of the request.  Note that this may not be defined during the
initial stages of processing a request; usually it is defined by
NameTrans directives.  The optional argument allows you to set the
extra path information.

=item B<query_string>

 $query_string = $rq->query_string($path);

With no arguments returns the query string information appended to the
URI of the request.  Note that this may not be defined during the
initial stages of processing a request; usually it is defined by
NameTrans directives.  The optional argument allows you to set the
query string information.

=item B<remote_user>

 $remote_user = $rq->remote_user($user);

With no arguments returns the remote user as determined from http
authentication.  If no authentication has been provided with the
request this will be undef.  The optional argument allows you to set
the remote user.

=item B<request_method>

 $request_method = $rq->request_method($method);

With no arguments returns the request method of the request.  This
will probably be one of GET, POST, or HEAD.  The optional argument
allows you to set the request method.

=item B<server_protocol>

 $server_protocol = $rq->server_protocol($protocol);

With no arguments returns something like "HTTP/1.0", or whatever
protocol the server is using to process the request.  The optional
argument allows you to set the server protocol, although I'm not sure
how this affects server internals.

=item B<user_agent>

 $user_agent = $rq->user_agent($agent);

With no arguments returns the value sent by the browser in the
"User-Agent" field of the http request header.  The optional argument
allows you to set the user agent.

=back

=head2 Server Variable Methods

These methods allow you to work with the variables the server uses
when constructing a response to a request.  Each such variable is
basically a key=value pair.  The variables are grouped into 4
different categories.  Each category of variable is accessed using a
method specific to that category.

=over 4

=item B<vars>

This method accesses server working variables.

 $vars = $rq->vars;
 $vars = $rq->vars($key);
 $vars = $rq->vars($key, $value);

With no arguments returns a reference to hash containing the names and
values of server working variables for this request.  Server working
variables are internal variables set up by the server during the
various stages of processing a request.  These variables describe
things like the document root directory for the server, the full path
to the requested file, and so on.

With one argument returns the value of the variable named by $key, or
undef if the variable doesn't exist.

With two arguments sets the variable named by $key to $value.  This is
the "official" way for one nsapi_perl subroutine to pass data to a
second subroutine that will run later on during the request.

I do not know of a definitive list of server working variable names,
but the following seem to be in common usage in NSAPI documentation
and examples.

B<auth-type>: This variable is defined by subroutines running in the
AuthTrans stage of processing a request.  It should be to the literal
B<basic> if http authentication is in effect for this request.

B<auth-user>: This variable is defined by subroutines running in the
AuthTrans stage of processing a request.  It should be set to the
username as determined from the client's authentication information if
authentication was successful.

B<ppath>: This variable initially contains the partial path as
determined from the clients request header.  For instance if a client
requests B<http://server/file.html>, B<ppath> would initially contain
the string B</file.html>.

B<name>: This variable can be created by a NameTrans subroutine to
indicate that the object named by B<name> is to be added to the set of
active objects processing this request.  See L<nsapi_perl> and your
Netscape server documentation for what an object is in this context.

B<path>: This variable contains the full path to the requested file
after all NameTrans subroutines have run.  If don't plan on having the
built-in NameTrans function run in addition to your subroutines, then
you are responsible for setting this variable to the correct value.

You can create any number of your own variables to pass information to
subroutines that will run later on in processing of the request.

=item B<reqpb>

This method accesses client request line variables.

 $reqpb = $rq->reqpb;
 $reqpb = $rq->reqpb($key);
 $reqpb = $rq->reqpb($key, $value);

With no arguments returns a reference to a hash containing these
entries:

B<method>: The method of the request: either B<GET>, B<HEAD>, or
B<POST>.

B<uri>: The URI the client asked for in the request.

B<protocol>: The protocol of the request, as in HTTP/1.0 or something
like that.

B<clf-request>: The full test of the first line of the client's
request.

With one argument this method returns the value of the field named by
$key.

With two arguments this method sets the field named by $key to $value.

=item B<headers>

This method accesses client request header variables.

 $headers = $rq->headers;
 $headers = $rq->headers($key);
 $headers = $rq->headers($key, $value);

With no arguments returns a reference to hash containing the client's
request headers.  The keys of this hash are the names of the various
header lines conveted to all lower case, such as B<user-agent> and
B<cookie>.  The values are whatever text appeared in that field of the
header.

With one argument this method returns the value of the request header
field named by $key.  Be sure to use the all lower-case form of the
field name.

With two arguments sets the value of the request header field named by
$key (again all lower-case) to $value.  Setting one of these values is
not an ethical thing.

=item B<srvhdrs>

This method accesses server response header variables.

 $srvhdrs = $rq->srvhdrs;
 $srvhdrs = $rq->srvhdrs($key);
 $srvhdrs = $rq->srvhdrs($key, $value);

With no arguments returns a reference to a hash containing
the server's response headers.  The keys of this hash are the names of
the various header lines converted to all lower case, such as
B<content-type> and B<set-cookie>.  The values are whatever text
appears in that field of the header.

With one argument this method returns the value of the request header
field name dby $key.  Be sure to user the all lower-case form of the
field name.

With two arguments sets the value of the request header field named by
$key (again all lower-case) to $value.  This is the "official" way to
set the server's response headers.  Make sure you do this I<before>
using protocol_start_response() (a method defined below).

=back

=head2 Action Methods

These methods cause the server to take an action based on the current
state of the request.  They are listed in the approximate sequence in
which they should be used by the nsapi_perl subroutine.  Some of these
methods indicate success or failure by returning one of the constants
defined in the Netscape::Server module.

=over 4

=item B<protocol_status>

 $rq->protocol_status($sn, $status, $reason);

Sets the HTTP status of the session.  $sn is an instance of
Netscape::Server::Session.  $status is one of the protocol-status
constants, like PROTOCOL_OK, that can imported from Netscape::Server.
$reason is an optional string sent to the client in the status line.
If $reason is omitted the server will pick one based on $status
defaulting to "unknown reason" in degenerate cases. This method
returns nothing.

=item B<protocol_start_response>

 $proceed = $rq->protocol_start_response($sn, $status, $reason);

Initiates an http response to the client by sending an http header
based on the current state of $sn and $rq.  $sn is an instance of
Netscape::Server::Session.  Returns either REQ_PROCEED, REQ_NOACTION
or REQ_ABORTED.  If REQ_PROCEED is returned the subroutine can
continue as normal.  If REQ_NOACTION is returned, the method
succeeded, but the client needs no actual data (perhaps because the
client has the data in its cache.)  If REQ_ABORTED is returned, the
method did not succeed.

=back

To send data to the client see net_write() in
L<Netscape::Server::Session>.

=head1 AUTHOR

Benjamin Sugars <bsugars@canoe.ca>

=head1 SEE ALSO

perl(1), nsapi_perl, Netscape::Server, Netscape::Server::Session

=cut
