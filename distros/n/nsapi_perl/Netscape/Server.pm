package Netscape::Server;

# -------------------------------------------------------------------
#   Server.pm - Perl module to integrate Netscape web server
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
use Carp;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD @EXPORT_OK %EXPORT_TAGS);
require Exporter;
require DynaLoader;

@ISA = qw(DynaLoader Exporter);
@EXPORT_OK = qw/
    error_codes
    LOG_CATASTROPHE
    LOG_FAILURE
    LOG_INFORM
    LOG_MISCONFIG
    LOG_SECURITY
    LOG_WARN
    log_error
    func_exec
    protocol_codes
    PROTOCOL_BAD_REQUEST
    PROTOCOL_FORBIDDEN
    PROTOCOL_NOT_FOUND
    PROTOCOL_NOT_IMPLEMENTED
    PROTOCOL_NOT_MODIFIED
    PROTOCOL_NO_RESPONSE
    PROTOCOL_OK
    PROTOCOL_PROXY_UNAUTHORIZED
    PROTOCOL_REDIRECT
    PROTOCOL_SERVER_ERROR
    PROTOCOL_UNAUTHORIZED
    request_codes
    REQ_ABORTED
    REQ_EXIT
    REQ_NOACTION
    REQ_PROCEED
    all
    /;

%EXPORT_TAGS = (
		'error_codes' => [
				  qw /
				  LOG_CATASTROPHE
				  LOG_FAILURE
				  LOG_INFORM
				  LOG_MISCONFIG
				  LOG_SECURITY
				  LOG_WARN
				  log_error
				  /],
		'protocol_codes' => [
				     qw /
				     PROTOCOL_BAD_REQUEST
				     PROTOCOL_FORBIDDEN
				     PROTOCOL_NOT_FOUND
				     PROTOCOL_NOT_IMPLEMENTED
				     PROTOCOL_NOT_MODIFIED
				     PROTOCOL_NO_RESPONSE
				     PROTOCOL_OK
				     PROTOCOL_PROXY_UNAUTHORIZED
				     PROTOCOL_REDIRECT
				     PROTOCOL_SERVER_ERROR
				     PROTOCOL_UNAUTHORIZED
				     /],
		'request_codes' => [ qw /
				    REQ_ABORTED
				    REQ_EXIT
				    REQ_NOACTION
				    REQ_PROCEED
				    /],
		'all' => [ @EXPORT_OK ],
		);

$VERSION = '0.24';

sub AUTOLOAD {
    # --- This AUTOLOAD subroutine is kind of weired because 3.x servers
    # --- seem to mangle errno (perhaps due to threading?).  In any
    # --- case, it basically looks to see if $constname is in a 
    # --- predefined list; it it is, it loads it from C.  If not,
    # --- it moves on to the AUTOLOAD in AutoLoader
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my($constname, $val);
    ($constname) = ($AUTOLOAD =~ /::([^:]+)$/);
    die if $constname eq 'constant';
    # --- I'll replace the grep with a lookup into a hash
    # --- when I have a bit more time.
    if (grep(/^$constname$/, @EXPORT_OK)) {
	$val = constant($constname, @_ ? $_[0] : 0);
    } else {
	$AutoLoader::AUTOLOAD = $AUTOLOAD;
	goto &AutoLoader::AUTOLOAD;
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}


bootstrap Netscape::Server $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Netscape::Server - framework for integrating Perl and Netscape servers

=head1 SYNOPSIS

 use Netscape::Server;
 use Netscape::Server qw/:request_codes/;
 use Netscape::Server qw/:protocol_codes/;
 use Netscape::Server qw/:error_codes/;
 use Netscape::Server qw/:all/;

 log_error($degree, $sub, $sn, $rq, $gripe);
 func_exec($fname, $sn, $rq, $args);

=head1 DESCRIPTION

The Netscape::Server module provides a framework for other modules
that implement an interface between Perl and the Netscape Server
Application Programming Interface (NSAPI).  Netscape::Server provides
definitions of the various NSAPI constants and server functions for
error logging.

For an overview of integrating Perl and NSAPI, see L<nsapi_perl>.
Suffice it to say here that nsapi_perl provides a mechanism by which a
Perl interpreter is embedded into a Netscape server.  The NSAPI can
then be programmed to in Perl rather than in C.  This is achieved by
placing the appropriate hooks in the server configuration files;
nsapi_perl will then call whatever Perl subroutines you wish at
various stages of processing a request from a client.

Perl modules interfacing to the NSAPI will require access to the
structures and constants defined in the NSAPI C header files.  The two
structures defined in these header files that are of most interest are
the I<Session> structure and the I<Request> structure.  These two
structures are represented in Perl by instances of the
Netscape::Server::Request and Netscape::Server::Session classes; see
their individual man pages for full details.

The rest of this document describes the constants and functions
declared in the NSAPI header files that are accessible through the
Netscape::Server module.

=head1 IMPORTABLE CONSTANTS

Importable from the point of view of whoever is using
Netscape::Server, that is.

NSAPI constants of interest to Perl fall into the following categories
(for full details, see your Netscape Server documentation or the NSAPI
header files).

=head2 Request-Response Codes

Request-Response codes are those constants that NSAPI C functions
return to the server to tell the server what to do next.  Similarly,
Perl subroutines called from nsapi_perl should return one of these
constants.

=over 4

=item I<REQ_PROCEED>

Returned by a subroutine when it has performed its task without a problem.

=item I<REQ_NOACTION>

Returned by a subroutine when conditions indicate it is not appropriate
for the subroutine to perform its task.

=item I<REQ_ABORTED>

Returned by a subroutine when an error has occurred an the client's
request cannot be completed.

=item I<REQ_EXIT>

Returned by a subroutine when a read or write error to or from the
client has occurred and no further communication with the client is
possible.

=back

See L<nsapi_perl> for a description of how the server behaves when a
particular constant is returned from a subroutine.

=head2 Protocol-Status Codes

Subroutines should use these constants to set the HTTP status of the
server's response to the request.  This should be done (using the
protocol_status() method of either Netscape::Server::Session or
Netscape::server::Request) before any data is sent to the client.
These constants have exact analogs in the definition of the http
protocol itself.

=over 4

=item I<PROTOCOL_OK>

Request can be fulfilled no problem.

=item I<PROTOCOL_REDIRECT>

The client making the request should be sent to another URL.

=item I<PROTOCOL_NOT_MODIFIED>

The requested object has not been modified since the date indicated by
the client in its initial request.

=item I<PROTOCOL_BAD_REQUEST>

The request was not understandable.

=item I<PROTOCOL_UNAUTHORIZED>

The client did not supply proper authorization to access the requested
object.

=item I<PROTOCOL_FORBIDDEN>

The client is explicitly forbidden to access the requested object.

=item I<PROTOCOL_NOT_FOUND>

The requested object could not be found.

=item I<PROTOCOL_SERVER_ERROR>

An internal server error has occurred.

=item I<PROTOCOL_NOT_IMPLEMENTED>

The server has been asked to do something it knows it cannot do.

=back

=head2 Error-Logging Codes

Error-logging codes are used by subroutines when an error has
occurred.  In particular, when an error occurs, the subroutine should
call the function log_error(); see L</FUNCTIONS> for more
details.

=over 4

=item I<LOG_INFORM>

An informational message.

=item I<LOG_WARN>

A warning message.

=item I<LOG_MISCONFIG>

An internal misconfiguration or permission problem.

=item I<LOG_SECURITY>

An authentication failure.

=item I<LOG_FAILURE>

A problem internal to your subroutine.

=item I<LOG_CATASTROPHE>

A non-recoverable server error.

=back

=head1 FUNCTIONS

The following functions may be imported in to the calling package's
namespace.

=over 4

=item B<log_error>

 $success = log_error($degree, $sub, $sn, $rq, $gripe);

I<$degree> is one of the constants defined in L</Error-Logging Code>;
it specifies the severity of your problem.  I<$sub> is a string that
should contain the name of the subroutine producing the error.  I<$sn>
is an instance of Netscape::Server::Session.  I<$rq> is an instance of
Netscape::Server::Request.  $gripe is an excuse for the error you have
begat; make it a good one.

I<log_error> returns true if the error has been successfully logged;
I<undef> otherwise (Note: the log_error function for the servers I
have access to produces different return values than what the
documentation says I should expect.  I have built the perl log_error()
function based on the return values I have emprically determined.  If
Netscape changes their API to agree with the documentation, the
perl log_error() function might break.)

=item B<func_exec>

 $proceed = func_exec($fname, $sn, $rq, $args);
 $proceed = func_exec($fname, $sn, $rq);

Call a function from the NSAPI. Returns REQ_ABORTED if no function was
executed, or the return code of the called function. I<$fname> is the
function name, as it would appear in a directive line from
obj.conf. I<$sn> is an instance of Netscape::Server::Session. I<$rq>
is an instance of Netscape::Server::Request. The optional I<$args> is
a reference to a hash containing argument and value pairs.

Example:

  $proceed = func_exec('find-index', $sn, $rq,
               {'index-names' => 'my_index'});

=back

=head1 IMPORT TAGS

A module wishing to import Netscape::Server symbols into its namespace
can use the following tags as arguments to the I<use Netscape::Server>
call.

=over 4

=item I<:request_codes>

Import the constants request-response codes like I<REQ_PROCEED>,
I<REQ_NOACTION>, etc.

=item I<:protocol_codes>

Import the protocol-status codes like I<PROTOCOL_OK>,
I<PROTOCOL_REDIRECT>, etc.

=item I<:error_codes>

Import the error-logging codes like I<LOG_INFORM>, I<LOG_WARN>, etc.
This tag also imports the I<log_error()> function.

=item I<:all>

Import all constant symbols, the I<log_error()> and I<func_exec()>
functions.

=back

=head1 AUTHOR

Benjamin Sugars <bsugars@canoe.ca>

Contributions from Steve Nielsen <spn@enteract.com> and Olivier Dehon
<dehon_olivier@jpmorgan.com>.

=head1 SEE ALSO

perl(1), nsapi_perl, Netscape::Server::Session,
Netscape::Server::Request

=cut
