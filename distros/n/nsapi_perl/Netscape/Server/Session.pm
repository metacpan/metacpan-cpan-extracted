package Netscape::Server::Session;

# -------------------------------------------------------------------
#   Session.pm - Perl interface to NSAPI Session structures
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
use vars qw(@ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);

# bootstrap Netscape::Server::Session $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Netscape::Server::Session - Perl interface to Netscape server Session

=head1 SYNOPSIS

 package Netscape::Server::Something;
 use Netscape::Server qw/:all/;

 sub handler {
     my($pb, $sn, $rq) = @_;
     ...
     $remote_host = $sn->remote_host;
     $remote_addr = $sn->remote_addr;
     ...
     $sn->protocol_status($rq, $status, $reason);
     $proceed = $sn->protocol_start_response($rq);
     $sn->net_write($message);
     $sn->net_read($length, $timeout);
     $sn->sys_net_read($length, $offset);
     ...
 }

=head1 DESCRIPTION

The Netscape::Server::Session class provides a Perl-object interface
to the Netscape Server API Session structure.  Instances of the
Netscape::Server::Session class are passed as arguments to all Perl
subroutines that are executed by a Netscape server that has been
integrated with Perl using nsapi_perl.

For an overview of integrating Perl and NSAPI, see L<nsapi_perl>.
Suffice it to say here that nsapi_perl provides a mechanism by which a
Perl interpreter is embedded into a Netscape server.  The NSAPI can
then be programmed to in Perl rather than in C.  This is achieved by
placing the appropriate hooks in the server configuration files;
nsapi_perl will then call whatever Perl subroutines you wish at
various stages of processing a request from a client.

When a Perl subroutine is called by nsapi_perl, it is passed three
arguments:

 my($pb, $sn, $rq) = @_;

I<$pb> is a reference to hash to the key=value pairs passed to the
subroutine from the server configuration files; see L<nsapi_perl> for
more details.  I<$rq> is an instance of Netscape::Server::Request
which has its own man page. I<$sn> is an instance of
Netscape::Server::Session and is the subject of the rest of this
document.

=head1 OBJECT ABSTRACTION

In NSAPI circles, "a I<session> is the time between the opening and
the closing of the connection between the client and the server",
quoting the Netscape server documentation.  The NSAPI stores
information about a session in a C structure called I<Session>. This
information includes the client host's IP address and hostname, socket
and buffer information about the connection to the client, and
parameters related to the client's ability to transmit data encrypted
through SSL.

Netscape::Server::Session exposes these properties to nsapi_perl
subroutines through instance methods.  Since these properties apply
session-wide, these properties are read-only.

In addition to allowing access to these properties, other
Netscape::Server::Session instance methods cause the server to perform
actions for the I<Session>.  For example, the I<net_write()> method
sends a message to the client.

Some methods require that an instance of Netscape::Server::Request be
passed as an argument.  Those that do will also have synonyms in the
Netscape::Server::Request class so that you don't have to remember
whether the method is to be written as

  $sn->method($rq);

or

  $rq->method($sn)

where $sn is an instance of Netscape::Server::Session and $rq is an
instance of Netscape::Server::Request. Either method call will do the
same thing.

=head1 INSTANCE METHODS

Netscape::Server::Session instance methods can be divided into those
that return session attributes and those that perform actions.

=head2 Session Attributes

=over 4

=item B<remote_host>

 $remote_host = $sn->remote_host;

Returns the hostname of the client's host.  Returns undef if the
hostname cannot be resolved.

=item B<remote_addr>

 $remote_addr = $sn->remote_addr;

Returns the IP address of the client's host.

=back

=head2 Session Actions

These methods are listed in the approximate sequence in which they
should be used by the nsapi_perl subroutine. Some of these methods
indicate success or failure by returning one of the constants defined
in the Netscape::Server module.

=over 4

=item B<protocol_status>

 $sn->protocol_status($rq, $status, $reason);

Set the HTTP status of the session.  $rq is an instance of
Netscape::Server::Request.  $status is one of the protocol-status
constants, like PROTOCOL_OK, that can imported from Netscape::Server.
$reason is an optional string sent to the client in the status line.
If $reason is omitted the server will pick one based on $status
defaulting to "unknown reason" in degenerate cases. This method
returns nothing.

=item B<protocol_start_response>

 $proceed = $sn->protocol_start_response($rq);

Initiates an http response to the client by sending an http header
based on the current state of $sn and $rq.  $rq is an instance of
Netscape::Server::Request.  Returns either REQ_PROCEED, REQ_NOACTION
or REQ_ABORTED.  If REQ_PROCEED is returned the subroutine can
continue as normal.  If REQ_NOACTION is returned, the method
succeeded, but the client needs no actual data (perhaps because the
client has the data in its cache.)  If REQ_ABORTED is returned, the
method did not succeed.

=item B<net_write>

 $sn->net_write($message);

Sends the contents of $message to the client.  Returns the number of
bytes actually sent (which may be less than the length of message if
there are problems).  This seems to be the preferred method to send
data to the client.

=item B<net_read>

 $sn->net_read($length);
 $sn->net_read($length, $timeout);

Reads $length bytes of data from the body of this Session's http
request. If $timeout is specified, its default value of 10 seconds is
overridden. In the event of an error, $! is set to reflect errno.

=item B<sys_net_read>

 $sn->sys_net_read($buffer, $length, $offset);

Reads $length bytes of data from the body of this Session's http
request into $buffer.  If $offset is specified, the content read will
will written to $buffer starting at position $offset in
$buffer. $buffer will grow or shrink as necessary. It returns the
number of bytes read. This method can be used to read HTML form data
sent to the server by a client; see, for instance, the READ method in
Netscape::Server::Socket.

=back

=head1 AUTHOR

Benjamin Sugars <bsugars@canoe.ca>

Contributions by Olivier Dehon <dehon_olivier@jpmorgan.com>.

=head1 SEE ALSO

perl(1), nsapi_perl, Netscape::Server, Netscape::Server::Request

=cut
