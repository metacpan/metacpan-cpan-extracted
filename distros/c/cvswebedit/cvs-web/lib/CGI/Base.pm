#!/usr/local/bin/perl -w

package CGI::Base;

require 5.001;

use Exporter;
use Socket;
use CGI::Carp;
use URI::Escape;
#use SelfLoader;

@ISA = qw(Exporter);

my $Revision = '$Id: Base.pm,v 2.76 1996/4/5 08:39:48 lstein Exp $';
my $Debug = 0;
my $SendHeaders_sent = 0;


=head1 NAME

CGI::Base - HTTP Daemon Common Gateway Interface (CGI) Base Class


=head1 SYNOPSIS

    use CGI::Base;
	
    $cgi = new CGI::Base;       # reads vars from environment
	
    $cgi->var($name);           # get CGI variable value
    $cgi->var($name, $value);   # set CGI variable value
	
    @names  = $cgi->vars;       # lists standard CGI variables
	
    $mime_type  = $cgi->accept_best(@mime_types);
    $preference = $cgi->accept_type($mime_type);
	
    $cgi->pass_thru($host, $port); # forward request to server
    $cgi->redirect($url);          # redirect client
	
    $cgi->done($dump);     # end response, does NOT send </BODY>
	
    $cgi->exit(@log_msgs); # exit, optionally logging messages
	
	
    # Other functions:
	
    @escaped_texts = html_escape(@texts);   # '>' -> '&lt;' etc
    @texts         = html_br_lines(@texts); #  \n -> '<BR>'
	
    SendHeaders();  # send and flush HTTP header(s)
	
    CGI::Base::Debug($level);


=head1 DESCRIPTION

This module implements a CGI::Base object. This object represents the
I<interface> between the application and an HTTP deamon.

In a typical CGI scenario the I<interface> is just a collection of
environment variables. This module makes those variables available
either via a $cgi->var() method or optionally as plain perl variables
(see IMPORTING CGI VARIABLES below).  Small scripts will tend to use
the imported variables, larger scripts may prefer to use the var
method.

By default the CGI::Base class will transparently deal with POST and
PUT submissions by reading STDIN into $QUERY_STRING.

The CGI::Base module simplifies CGI debugging by providing logging
methods (which redirect STDERR to a file) and a very handy test mode.
The test mode automatically detects that the script is not being run by
a HTTP server and requests test input from the user (or command line).

=head2 IMPORTING CGI VARIABLES

Users of this module can optionally import the CGI values as ordinary
perl variables of the same name into their package. For example,
saying:

    use CGI::Base qw(:DEFAULT QUERY_STRING REQUEST_METHOD);

will allow you to refer to the CGI query string and request method as
simply $QUERY_STRING and $REQUEST_METHOD.  Any changes made to these
variables will be reflected in the values returned by the var() method.

To import all the fixed CGI variables (excludes optional variables
string with HTTP_) use:

    use CGI::Base qw(:DEFAULT :CGI);

=head2 NOTES

The CGI::Base class has been specifically designed to enable it to be
subclassed to implement alternative interfaces. For example the
CGI::MiniSvr class implements a 'mini http daemon' which can be spawned
from a CGI script in order, for example, to maintain state information
for a client 'session'.

The CGI::Base class (and classes derived from it) are not designed to
understand the contents of the data they are handling. Only basic data
acquisition tasks and basic metadata parsing are performed by
CGI::Base. The QUERY_STRING is not parsed.

Higher level query processing (parsing of QUERY_STRING and handling of
form fields etc) is performed by the CGI::Request module.

Note that CGI application developers will generally deal with the
CGI::Request class and not directly with the CGI::Base class.


=head2 FEATURES

Object oriented and sub-classable.

Exporting of CGI environment variables as plain perl variables.

Supports pass_thru and redirection of URL's.

Extensible attribute system for CGI environment variables.

Very handy automatic test mode if script is run manually.


=head2 PRINCIPLES and ASSUMPTIONS

These basic principles and assumptions apply to CGI::Base and can be
built into any application using CGI::Base. Any subclass of CGI::Base,
such as CGI::MiniSvr, must uphold these principles.

STDIN, STDOUT are connected to the client, possibly via a server.

STDERR can be used for error logging (see open_log method).

%ENV should not be used to access CGI parameters. See ENVIRONMENT
section below.


=head2 ENVIRONMENT

The CGI::Base module copies all the CGI/1.1 standard environment
variables into internal storage. See the definition of %CgiEnv and
@CgiObj. The stored values are available either via the var method
or as exported variables.

It is recommended that $ENV{...} is not used to access the CGI
variables because alternative CGI interfaces, such as CGI::MiniSvr, may
not bother to maintain %ENV consistent with the internal values. The
simple scalar variables are also much faster to access.


=head2 RECENT CHANGES

=over

=item 2.6

Changes to create compatability with CGI::Form.

=item 2.5

Miscellaneous small bug fixes.

=item 2.4

get_url() now adds SERVER_PORT to the url. pass_thru() split into
component methods forward_request() and pass_back().  The new
forward_request method can shutdown() the sending side of the socket.
SendHeaders does nothing and returns undef if called more than once.
All these changes are useful for sophisticated applications.

=item 2.2 and 2.3

Slightly improved documentation. Added html_br_lines() to purify
html_escape().  Added SIGPIPE handling (not used by default).
Documented the automatic test mode. Assorted other minor clean ups.

=item 2.1

Added support for any letter case in HTTP headers. Fixed (worked
around) a perl/stdio bug which affected POST handling in the MiniSvr.
Added $ENTITY_BODY to hold the Entity-Body for PUT, POST and CHECKIN
methods. $QUERY_STRING now only set from $ENTITY_BODY if CONTENT_TYPE
is application/x-www-form-urlencoded. Changed some uses of map to foreach.
Slight improved performance of pass_thru.

=item 2.0

A major overhaul. Now much more object oriented but retaining the
ability to export CGI variables. A new var() method provides access
to CGI variables in a controlled manner. Some rather fancy footwork
with globs and references to hash elements enables the global variables
and hash elements to be automatically kept in sync with each other.
Take a look at the link_global_vars method. An export tag is provided
to simplify importing the CGI variables.

The new code is also much faster, mainly because it does less. Less
work is done up front, more is defered until actually used. I have
removed the 'expand variables' concept for now. It might return later.
The code for read_entity_body(), get_vars_from_env() and accept_best()
and many others has been revised. All the code now compiles with use
strict;

SendHeaders can now be told to automatically add a server Status-Line
header if one is not included in the headers to be output. This greatly
simplifies header handling in the MiniSvr and fixes the redirect() method.

The module file can be run as a cgi script to execute a demo/test. You
may need to chmod +x this file and teach your httpd that it can execute
*.pm files.


=item 1.17

The done method no longer sends </BODY>. It was appealing but
inappropriate for it to do so.  Added html_escape function and exported
it by default (this should be moved into an HTML module once we have
one). Applied html_escape to as_string.  ContentTypeHdr, LocationHdr,
StatusHdr and ServerHdr no longer exported by default. Added Debug
function.  Set default Debug level to 0 (off). Code to set $URI is no
longer invoked by default and has been moved to a new get_uri method.
This avoids the overhead for setting $URI which few people used.
Methods like as_string which make use of $URI now call get_uri if
needed.

=item 1.16

POST data read more robust. fmt() renamed to as_string(). pass_thru()
now takes host and port parameters, applies a timeout and has better
logging.  HTTP_REFERER defined by default. Assorted fixes and tidyups.

=back

=head2 FUTURE DEVELOPMENTS

Full pod documentation.

None of this is perfect. All suggestions welcome.

How reliable is CONTENT_LENGTH?

Pod documentation for the methods needs to be added.

Header handling is not ideal (but it's getting better).
Header handling should be moved into an HTTP specific module.

Need mechanism to identify a 'session'. This may come out of the
ongoing HTTP security work. A session-id would be very useful for any
advanced form of inter-query state maintenance.  The CGI::Base module
may have a hand in providing some form of session-id but would not be
involved in any further use of it.

For very large POST's we may need some mechanism to replace
read_entity_body on a per call basis or at least prevent its automatic
use. Subclassing is probably the 'right' way to do this.

These functions should be moved out into a CGI::BasePlus module since
few simple CGI applications need them:  pass_thru, forward_request,
pass_back, new_server_link, pass_thru_headers. The CGI::BasePlus module
would still be a 'package CGI::Base;'.


=head2 AUTHOR, COPYRIGHT and ACKNOWLEDGEMENTS

This code is Copyright (C) Tim Bunce 1995. All rights reserved.  This
code is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

This code includes ideas from the work of Steven E. Brenner
<S.E.Brenner@bioc.cam.ac.uk> (cgi-lib), Lincoln Stein
<lstein@genome.wi.mit.edu> (CGI.pm), Pratap Pereira
<pereira@ee.eng.ohio-state.edu> (phttpd) and possibly others.

IN NO EVENT SHALL THE AUTHORS BE LIABLE TO ANY PARTY FOR DIRECT,
INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION (INCLUDING, BUT NOT
LIMITED TO, LOST PROFITS) EVEN IF THE AUTHORS HAVE BEEN ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

=head2 SEE ALSO

URI::URL, CGI::Request, CGI::MiniSvr

=head2 SUPPORT

Please use comp.infosystems.www.* and comp.lang.perl.misc for support.
Please do _NOT_ contact the author directly. I'm sorry but I just don't
have the time.

=cut

#=head1 METHODS and FUNCTIONS
#
#B<NOTE!> most of the functions and methods are B<NOT> yet documented.
#
#=cut

($VERSION = $Revision) =~ s/.*(\d+\.\d+).*/$1/;
my $LogFile  = '';
my $TcpProto = undef;

# The Content-Length header typically gives a value that does not
# include a trailing \r\n pair. Normally this can be ignored.
# The MiniSvr had a problem with perl/stdio which meant that this
# pair appeared at the head of a new connection! This variable
# was part of an initial fix which was later replaced by explicit
# close()s in the MiniSvr. I've kept this here for reference.
my $read_entity_body_extra = 0;  # set two 2 to read \r\n pair.

# shortcuts to reduce pain of strict refs
my $stdout = \*STDOUT;
my $stderr = \*STDERR;

$NeedServerHeader = 0;	# See Sendheaders() and CGI::MiniSvr


# List CGI Environment Variables and attributes.
# Note that HDR attributes must be stored in lowercase form.

my %CgiEnv = (
    AUTH_TYPE		=> { HDR =>'authorization:'	},
    CONTENT_LENGTH	=> { HDR =>'content-length:'	},
    CONTENT_TYPE	=> { HDR =>'content-type:',	},
    GATEWAY_INTERFACE	=> {},
    HTTP_ACCEPT		=> {},
    HTTP_USER_AGENT	=> {},
    HTTP_REFERER        => {},
    PATH_INFO		=> {},
    PATH_TRANSLATED	=> {},
    QUERY_STRING	=> { string_fmt=>'%s = %.200s'	},
    REMOTE_ADDR		=> {},
    REMOTE_HOST		=> {},
    REMOTE_IDENT	=> {},
    REMOTE_USER		=> {},
    REQUEST_METHOD	=> {},
    SCRIPT_NAME		=> {},
    SERVER_NAME		=> {},
    SERVER_PORT		=> {},
    SERVER_PROTOCOL	=> {},
    SERVER_SOFTWARE	=> {},
);
$ENTITY_BODY = undef;		# See read_entity_body

my @CgiEnv = sort keys %CgiEnv;
my @CgiExp = map { '*'.$_ } (@CgiEnv, 'ENTITY_BODY');

# We only have one CGI::Base object, and here it is:
my %CgiObj;

link_global_vars(\%CgiObj);	# should only be called once

@EXPORT = qw(
    SendHeaders html_br_lines html_escape
);# SendHeaders & html_escape should/will be moved elsewhere later

@EXPORT_OK = (
    @CgiExp,
    qw(LogFile ContentTypeHdr LocationHdr StatusHdr ServerHdr),
);

%EXPORT_TAGS = (
    CGI => [@CgiExp],
    HDR => [qw(ContentTypeHdr LocationHdr StatusHdr ServerHdr)],
);


my %Request_Method_Dispatch = (
    GET		=> 'method_GET',
    HEAD	=> 'method_HEAD',
    PUT		=> 'method_PUT',
    POST	=> 'method_POST',
    DELETE	=> 'method_DELETE',
    LINK	=> 'method_LINK',
    UNLINK	=> 'method_UNLINK',
    CHECKIN	=> 'method_CHECKIN',
    CHECKOUT	=> 'method_CHECKOUT',
    SHOWMETHOD	=> 'method_SHOWMETHOD',
    other	=> 'method_other',
);

# use strict qw(vars refs subs);


sub new {	# Constructor, but not much to construct!
    my($class) = @_;
    my $self = \%CgiObj;
    bless $self, $class;
}

sub port {	# see CGI::MiniSvr
    undef;
}

sub vars {
    @CgiEnv;
}

sub attr {
    my($self, $var, $attr) = @_;
    my $a = $CgiEnv{$var};
    return undef unless defined $a;
    $a->{$attr};
}


sub get {
    my($self, $timeout) = @_; 
    my $result;

    do {

	$self->log("$self->get(timeout=$timeout)") if $Debug >= 2;

	$self->get_vars($timeout) or return undef; 	# get or timeout

	$self->log_request if $self->is_logging;

	my $meth = $Request_Method_Dispatch{$CGI::Base::REQUEST_METHOD}
		|| $Request_Method_Dispatch{'other'};

	$result = $self->$meth();

    } while ($result eq 'NEXT');	# see method_*() below

    $result;
}


# Handler Methods for REQUEST_METHOD's
#
# These methods can return on of:
#	1	Normal, pass request up to application.
#	ERROR	An non-fatal error occured.
#	NEXT	Request has been satisfied without needing to
#		pass it up to the application. (Only applicable
#		to CGI::MiniSvr or similar dynamic interfaces).
#		Get next request.
#	0/undef	Fatal error or Timeout (in MiniSvr)
#
# These methods are designed to be overridden in subclasses.

sub method_CHECKIN	{ shift->read_entity_body }
sub method_CHECKOUT	{ 1 }
sub method_DELETE	{ 1 }
sub method_GET		{ 1 }
sub method_HEAD		{ 1 }
sub method_LINK		{ 1 }
sub method_POST		{ shift->read_post_body }
sub method_PUT		{ shift->read_entity_body }
sub method_SHOWMETHOD	{ 1 }
sub method_UNLINK	{ 1 }
sub method_other	{ 1 }


sub read_entity_body {	# read $ENTITY_BODY of CONTENT_LENGTH from STDIN
    my($self, $timeout) = @_;
    my $contlen = $CGI::Base::CONTENT_LENGTH;
    $CGI::Base::ENTITY_BODY = '';

    # Perl read() relies on C stdio fread() to deal with incomplete
    # network reads. read() will block if trying to read too much.
    $self->log("read_entity_body: expecting $contlen bytes ...")
	if $Debug;
# Alarm line commented out by Martin Cleaver
#    alarm($timeout || 60);	# Alarm set. No handler, just die, HACK

    $contlen = 0 if $contlen < 0; # weird server/client bug fix
    my $readlen = read(STDIN, $CGI::Base::ENTITY_BODY, $contlen);

    if ($read_entity_body_extra) { # normally false, see top of file
	my $dummy = '';	# the read will block if nothing to read!
	$dummy = read(STDIN, $dummy, $read_entity_body_extra);
	$self->log("read $readlen bytes extra");
    }
# Alarm line commented out by Martin Cleaver
#    alarm(0);			# Alarm reset.

    if ($readlen != $contlen){
	my $msg = sprintf("read_entity_body: read %d of %d bytes",
			    length($CGI::Base::ENTITY_BODY), $contlen);
	$msg .= ": $!" if $readlen < 0;	# include errno if error
	$self->log($msg);
	return 0;	# must be treated as failure
    }
    $self->log("read_entity_body: read ok") if $Debug;

    1;
}


# Call read_entity_body then convert ENTITY_BODY into QUERY_STRING
# if CONTENT_TYPE eq "application/x-www-form-urlencoded".

sub read_post_body {

    shift->read_entity_body or return 0;

    if ($CGI::Base::CONTENT_TYPE eq "application/x-www-form-urlencoded") {

	# Convert posted query string back into canonical form.
	# We have to deal with browsers which use CRLF, CR or LF.
	($CGI::Base::QUERY_STRING = $CGI::Base::ENTITY_BODY)
		=~ s/\r?[\n\r]/&/mg;
    }
    1;
}


# --- SIGPIPE Handling ---

# We don't setup a handler by default since the default behaviour (exiting)
# is usually appropriate. We provide this code so that people who need to
# cleanup etc can test for a SIGPIPE event. The MiniSvr also uses this.
my $SigPipe  = 0;			# set to 1 by SIGPIPE handler

sub sigpipe         { $SigPipe     }	# method to check for SIGPIPE event
sub sigpipe_handler { $SigPipe = 1 }	# record SIGPIPE event
sub sigpipe_reset   { $SigPipe = 0 }	# reset SIGPIPE event
sub sigpipe_catch {			# establish handler
    $SIG{PIPE} = ($_[1]) ? $_[1] : \&sigpipe_handler;
}


# --- CGI Variable Handlers ---

sub get_vars {		# create new variables with same names as env var
    my($self) = @_;	# we ignore timeout argument

    $self->get_vars_from_env;
    $self->get_vars_by_debug  unless $CGI::Base::REQUEST_METHOD;

    # Temporary workaround HACK for me (badly installed HTTPD I think)
    $CGI::Base::SERVER_NAME = 'toad' if $CGI::Base::SERVER_NAME eq 'toad.co.uk';

    1;	# must return success
}


sub get_vars_from_env {		# Import from environment
    my($self, $prefix) = @_;
    my $name;
    no strict qw(refs);
    foreach $name (keys %ENV) {
	my $attr = $CgiEnv{$name};
	next unless $attr or $name=~m/^HTTP_/;
	my $key = ($prefix) ? $prefix.$name : $name;
	$CgiEnv{$key} = {} unless $attr; # is new HTTP_ var
	$self->{$key} = $ENV{$name};	 # import into cgi object
    }
}


sub link_global_vars {
    my($self) = @_;
    # Link CGI global variables (which can be exported) to the elements of
    # the object hash.  We use some glob magic for this. Wild but cute!
    # Note that if this should only be done once as later calls will not
    # effect variables imported into other packages. This is not a problem
    # for us since we only ever has one cgi object: \%CgiObj.
    no strict qw(refs);
    foreach (@CgiEnv) {
	${$_} = '' unless defined ${$_};
	*{$_} = \$self->{$_};
    }
}


sub put_vars {
    my($self) = @_;
    # Not recommended, included to allow alternative CGI interfaces
    # to be compatible with old CGI scripts. Not called by default.
    foreach (@CgiEnv) {
	$ENV{$_} = $self->{$_};
    };
}


sub get_vars_by_debug {		# Handy debugging modes
    my($self) = @_;
    my($qs, $sn);
    # Set reasonable defaults for debugging
    # As an indication of test mode don't define REMOTE_*
    $CGI::Base::SERVER_SOFTWARE = "PERL_CGI_BASE/$CGI::Base::VERSION";
    $CGI::Base::SERVER_NAME = 'localhost';
    $CGI::Base::SERVER_PORT = 80;
    $CGI::Base::SERVER_PROTOCOL = 'HTTP/1.0';
    $CGI::Base::HTTP_USER_AGENT = $CGI::Base::SERVER_SOFTWARE;
    $sn = $0;
    unless ($sn =~ m:^/:) {
		require Cwd;
        my $cwd = Cwd::fastcwd();
        $cwd =~ s:/?$:/:; # force trailing slash on dir
        $sn = $cwd . $sn;
    }
    $CGI::Base::SCRIPT_NAME   = $sn;
    $CGI::Base::REQUEST_METHOD = 'GET';

    $qs = '';
    if (@ARGV) {	# Debugging off-line via command line args
	$qs = "@ARGV";
	$qs =~ tr/ /&/ if $qs =~ m/=/;

    } else {		# Debugging off-line via standard input
	my @lines;
	print { (-t $stdout) ? $stdout : $stderr }
		"(waiting for HTTP query on standard input)\n";
	chomp(@lines = <>);             # remove all newlines
	# we assume it's a form if it contains an =
	my $is_form = ("@lines" =~ m/=/);
	$qs = join( $is_form ? "&" : "+", @lines);
    }
    $CGI::Base::QUERY_STRING = $qs;
}


sub get_uri {
    my($self) = @_;
    my $uri = $self->{URI};
    return $uri if $uri and ref $uri;

    unless ($uri) {

	# Create URI from $SCRIPT_NAME and $QUERY_STRING if appropriate.
	# The URI we are trying to recreate is the one that the HTTPD
	# received in the initial client request. CGI::MiniSvr does the inverse.
	$uri = $CGI::Base::SCRIPT_NAME;
	$uri.= '?'.$CGI::Base::QUERY_STRING if ($CGI::Base::QUERY_STRING
			    and $CGI::Base::REQUEST_METHOD !~ m/^(POST|PUT)$/);
    }
    return '' unless $uri;	# something's wrong

    # Convert uri into a real object, provide appropriate base url.
    my $base = "http://$CGI::Base::SERVER_NAME";
    $base .= ':'.$CGI::Base::SERVER_PORT if $CGI::Base::SERVER_PORT;
    $uri = uri_escape("$base$uri");

    $self->{URI} = $uri;
    $uri;
}


sub var {
    my($self, $name, @values) = @_;
    my $v = $self->{$name};			# get old value
    $self->{$name} = $values[0] if @values;	# set new value
    $v;
}


# -----------------------------------------------------------------------

# This needs to be moved to an HTML module and considered more carefully.
my %html_escape = ('&' => '&amp;', '>'=>'&gt;', '<'=>'&lt;', '"'=>'&quot;');
my $html_escape = join('', keys %html_escape);
sub html_escape {
    my @text = @_;
    foreach(@text) { s/([$html_escape])/$html_escape{$1}/mgoe; }
    @text;
}

sub html_br_lines {
    my @text = @_;
    foreach(@text) { s/\r?\n/<BR>/mg }
    @text;
}


sub as_string {
    my $self = shift;
    my(@h, $var, $attr, $fmt, $val);
    push(@h, "<BR><HR>");
    push(@h, "<B>CGI Interface Variables:</B> ");
    push(@h, "(CGI::Base version $CGI::Base::VERSION)<BR><PRE>");
    no strict qw(refs);
    my @vars = sort @CgiEnv;
    foreach $var (@vars){
	$attr= $CgiEnv{$var};
	$fmt = "%s = %s";
	$fmt = $attr->{string_fmt} if ($attr && $attr->{string_fmt});
	$val = (defined $self->{$var}) ? "'$self->{$var}'" : 'undefined';
	push(@h, sprintf($fmt, $var, html_br_lines(html_escape($val))));
    }
    my $uri = $self->get_uri || '';
    push(@h, sprintf("URI = %s", html_escape($uri)));
#    if ($uri) {
#	foreach(qw(netloc path query frag)){
#	    my $val = $uri->_elem($_);
#	    $val = (defined $val) ? "'$val'" : 'undefined';
#	    push(@h, sprintf("URI %7s = %s", $_, html_escape($val)));
#	}
#    }
    push(@h, $self->_as_string_extra); # give subclass a chance
    # XXX also output user id and cwd info ? Security risk ?
    push(@h, "</PRE>");
    join("\r\n", '',@h);
}

sub _as_string_extra {
    ();		# see MiniSvr
}



# =head2 accept_type
# 
# Without parameters, returns an array of the MIME types the browser
# accepts.
# 
# With a single parameter equal to a MIME type, will return undef if the
# browser won't accept it, 1 if the browser accepts it but doesn't give a
# preference, or a floating point value between 0.0 and 1.0 if the
# browser declares a quantitative score for it.
# 
# The parameter can also be a search pattern.
# 
# This handles MIME type globs correctly.
# 
# =cut

sub accept_type {
    my($self, $search) = @_;
 
    my $ha = $self->var("HTTP_ACCEPT_cache");

    unless($ha) {	# cached already ?
	my($pref, $mxb, $media);
	my @HTTP_ACCEPT = split(/\s*,\s*/, $CGI::Base::HTTP_ACCEPT);
	$ha = {};
	foreach (@HTTP_ACCEPT) {
	    ($media) = m#(\S+/[^;]+)#;
	    ($pref)  = m/\bq=(\d\.\d+|\d+)/;
	    ($mxb)   = m/\bmxb=(\d+)/;
	    $pref = 1  unless defined $pref;
	    $mxb  = '' unless defined $mxb;
	    $ha->{$media} = { 'q'=>$pref, 'mxb'=>$mxb };
	}
	$self->var("HTTP_ACCEPT_cache", $ha);
    }

    return keys %$ha unless $search;
 
    # if a search type is provided, we may need to
    # perform a pattern matching operation.
    # The MIME types use a glob mechanism, which
    # is easily translated into a perl pattern match
 
    # First return the preference for directly supported types:
    return $ha->{$search}->{'q'} if $ha->{$search};
 
    # Didn't get it, so try pattern matching.
    my $pat;
    foreach (keys %$ha) {
        next unless /\*/;	# not a pattern match
        $pat = "\Q$_";		# escape all meta characters
        $pat =~ s/\\*/.*/g;	# turn escaped * (\*) into .*
        return $ha->{$_}->{'q'} if $search=~/$pat/;
    }
    0;
}      


# =head2 accept_best
# 
#   $type = accept_best('foo/bar', 'foo/baz');
# 
# Given a list of mime types accept_best() will return the type most
# prefered by the user agent. Returns undef if none of the supplied types
# are acceptable.
# 
# =cut

sub accept_best {
    my($self, @types) = @_;
    croak "accept_best not yet implemented"; # volunteers welcome
}


# --- End response to client (does more in CGI::MiniSvr)


sub done {		# mark the completion of a 'page'
    # Simple apps often don't bother with this. MiniSvr apps must.
    my($self, $dump) = @_;
    # show CGI vars to client
    print $self->as_string if $dump and !$SigPipe;
    $self->log($SigPipe ? "Done (SigPipe)\n" : "Done.\n");
    $SendHeaders_sent = 0;	# reset for next time (MiniSvr)
    $self->close;
}

sub close {
    # it doesn't make such sense to close STDIN/OUT in CGI::Base
}

sub spawn {		# See CGI::MiniSvr
    my $self = shift;
    $self->log("Can't spawn this interface (use CGI::MiniSvr)");
    0;
}


sub exit {		# Terminate, and optionally log a message
    my $self = shift;
    $self->log(@_) if @_;
    exit 0;
}



# --- Alternative Response Methods

# This function passes a request thru to the main HTTPD and passes
# the response back to the client. Although it's in the CGI::Base
# class it's only currently usable by CGI::MiniSvr. EXPERIMENTAL!

$CGI::Base::pass_thru_shutdown = 0;

sub pass_thru {
    my($self, $host, $port) = @_;
    $port = 80 unless $port;

    $self->log("Pass-thru to $host:$port") if $Debug;

    my $svr_fh = $self->new_server_link($host, $port) or return 0;

    my $sent = $self->forward_request($svr_fh, $CGI::Base::pass_thru_shutdown);

    $self->log("Request forwarded, awaiting response on fd"
		.fileno($svr_fh)) if $Debug >= 2;

    my $bytes = $self->pass_back($svr_fh);

    close($svr_fh);
    if ($Debug) {
	$self->log("Pass-thru complete. Bytes: $sent thru, $bytes back.");
	$self->log("Warning: possibly truncated by SIGPIPE") if $SigPipe;
    }
    1;
}


sub forward_request {
    my($self, $svr_fh, $shutdown) = @_;

    # pass_thru_headers() is overridden in CGI::MiniSvr
    my $hdrs = $self->pass_thru_headers();

    print $svr_fh $hdrs;	# send the headers

    # Send QUERY_STRING and ENSURE EVERYTHING IS FLUSHED OUT!
    {   no strict 'refs';
	select((select($svr_fh), $|=1)[0]);
	print $svr_fh $CGI::Base::QUERY_STRING;
    }
    # $shutdown=1 will close the write side of the socket
    shutdown($svr_fh, 1) if $shutdown;
    length($hdrs) + length($CGI::Base::QUERY_STRING);
}


sub pass_back {
    my($self, $svr_fh) = @_;
    # Pass back the results as fast as possible (may be binary data)
    my($bytes, $len, $buf) = (0,0,'');
    while ($len = read($svr_fh, $buf, 1024)) {
	print $buf;
	last if $SigPipe;
	$bytes += $len;
    }
    $bytes;
}


my %server_link_cache = ();

sub new_server_link {
    my($self, $host, $port, $timeout) = @_;
    my $port_in;
    $timeout = 30 unless $timeout;	# just for connect();
    $host = $CGI::Base::SERVER_NAME || 'localhost' unless $host;
    $port = $CGI::Base::SERVER_PORT || 80          unless $port;

    my $fh = $self->_newfh;
    if ($port > 0){	# numeric port, else path to unix socket
	$TcpProto = (getprotobyname('tcp'))[2] unless defined $TcpProto;
	unless (socket($fh, AF_INET, SOCK_STREAM, $TcpProto)){
	    $self->log("socket tcp: $!");
	    return 0;
	}
	unless ($port_in = $server_link_cache{"$host:$port"}){
	    # get and cache connection details for main server
	    my $host_in = (gethostbyname($host))[4];
	    $port_in = pack('S n a4 x8', AF_INET, $port, $host_in);
	    $server_link_cache{"$host:$port"} = $port_in;
	}
    } else {
	# connect to a unix domain socket, probably a MiniSvr
	unless (socket($fh, AF_UNIX, SOCK_STREAM, 0)){
	    $self->log("socket $port: $!");
	    return 0;
	}
    }
    alarm($timeout) if $timeout;
    unless (connect($fh, $port_in)){
	alarm(0);
	$self->log("connect($host:$port): $!");
	return 0;
    }
    alarm(0);
    # don't set to non-buffered yet
    $fh;
}


sub pass_thru_headers {
    my($self, $new_uri) = @_;
    $new_uri = $self->get_uri unless $new_uri;
    my @h; # Construct a plausable set of HTTP headers
    push(@h, "$CGI::Base::REQUEST_METHOD $new_uri $CGI::Base::SERVER_PROTOCOL");
    my @HTTP_ACCEPT = split(/\s*,\s*/, $CGI::Base::HTTP_ACCEPT);
    push(@h, map { "Accept: $_" } @HTTP_ACCEPT);
    push(@h, "User-Agent: $CGI::Base::HTTP_USER_AGENT");
    join("\r\n", @h, '');	# add blank line
}


# The alternative to pass_thru (above) is redirecting the HTTPD
# or client via a 3xx status and a Location: and/or URI: headers.
# It is important that SendHeaders has NOT already been called.
# This means that applications wishing to use redirect should NOT
# use the GetRequest interface of CGI::Request (use new instead).

sub redirect {
    my $self = shift;
    my $to_uri = shift;
    my $perm = shift;
    my $orig_uri = $self->get_uri;
    $self->log("Redirecting $CGI::Base::REQUEST_METHOD $orig_uri to $to_uri")
	if $Debug;
    my $msg =   ($perm) ? ServerHdr(301,"Moved Permanently")
			: ServerHdr(302,"Moved Temporarily");
    my $hdrs = SendHeaders($msg, LocationHdr($to_uri));
    $self->log($hdrs);
}


# =head2 Debug
# 
#     $old_level = CGI::Base::Debug();
#     $old_level = CGI::Base::Debug($new_level);
# 
# Set debug level for the CGI::Base module.  See LogFile()
# function or open_log() method.
# 
# =cut

sub Debug {
    my($level) = @_;
    my $prev = $Debug;
    if (defined $level) {
        $Debug = $level;
        print STDERR "CGI::Base::Debug($level)\n";
    }  
    $prev;
}


# --- Logging and other utility methods

sub open_log {
    my($self, $file, $trunc) = @_;
    return close_log() unless $file;
    $trunc = ($trunc) ? '>' : '>>';
    open($stderr,"$trunc$file") or return $self->log("open($file) $!\n");
    no strict 'refs';
    select((select($stderr), $|=1)[0]);
    print $stderr "\n###### ".&timestamp.": CGI::Base $CGI::Base::VERSION, pid $$\n"
	if $file ne $LogFile;
    $LogFile = $file;
}

sub close_log {
    open($stderr,">/dev/null");
    $LogFile = '';
}

sub is_logging {
    $LogFile;
}

sub log {
    return unless $LogFile;
    my $self = shift;
    my $stamp = &timestamp."-$$: ";
    print $stderr $stamp,@_,"\n";
}

sub timestamp { # Efficiently generate a time stamp for log files
    package CGI::Base::timestamp;	# keep our globals static
    my $time = time;	# optimise for many calls in same second
    no strict qw(vars);
    return $last_str if $last_time and $time == $last_time;
    my($sec,$min,$hour,$mday,$mon,$year)
	= localtime($last_time = $time);
    $last_str = sprintf("%02d%02d%02d %02u:%02u:%02u",
		    $year,$mon+1,$mday, $hour,$min,$sec);
}

sub LogFile {		# non-method way to set logfile
    my($file) = @_;
    CGI::Base->open_log($file);
}

END {
    CGI::Base->log("Process terminated.") if $Debug;
}


sub log_request {	# Write summary of request to the log
    my $self = shift;
    my $uri = $self->get_uri;
    $self->log("Request: $CGI::Base::REQUEST_METHOD $uri $CGI::Base::SERVER_PROTOCOL");
    if ($Debug) {
	$self->log("Script: '$CGI::Base::SCRIPT_NAME'")  if $CGI::Base::SCRIPT_NAME;
	$self->log("Query:  '$CGI::Base::QUERY_STRING'") if $CGI::Base::QUERY_STRING;
	$self->log("Agent:  '$CGI::Base::HTTP_USER_AGENT'");
    }
}


# Return a filehandle which can be used without upsetting strict refs
# This is a method to make it easy for MiniSvr (etc) to use it.
my $_newfh_seq = "newfh000";

sub _newfh {
    my($self, $fh) = @_;
    no strict 'refs';
    unless ($fh) {
	$fh = ++$_newfh_seq;
	$fh = "CGI::Base::_$fh";
    }
    close($fh) if defined fileno($fh);	# may be being reused
    $fh = $$fh if ref $fh;		# reusing previous ref
    bless \*{$fh}, 'FileHandle';
}


sub _not_typos {
    no strict; &_not_typos;
    $AUTH_TYPE, $CONTENT_LENGTH, $CONTENT_TYPE, $GATEWAY_INTERFACE,
    $HTTP_ACCEPT, $HTTP_USER_AGENT, $HTTP_REFERER, $PATH_INFO,
    $PATH_TRANSLATED, $QUERY_STRING, $REMOTE_ADDR, $REMOTE_HOST,
    $REMOTE_IDENT, $REMOTE_USER, $REQUEST_METHOD, $SCRIPT_NAME,
    $SERVER_NAME, $SERVER_PORT, $SERVER_PROTOCOL, $SERVER_SOFTWARE,
	# These appear again since they don't appear in the source at all
	$REMOTE_ADDR, $GATEWAY_INTERFACE, $REMOTE_HOST, $AUTH_TYPE,
	$REMOTE_USER, $PATH_TRANSLATED, $PATH_INFO, $REMOTE_IDENT,
	$HTTP_REFERER,
}

######################################################################
#
# Handy but tacky functions supporting the output of Headers
# These should get moved to an HTTP specific module
#
# THIS ALL NEEDS REWORKING. There are major outstanding issues relating
# to who should output headers and when.

sub SendHeaders {	# e.g., SendHeaders() or SendHeaders(StatusHdr(400));
    my(@hdrs) = @_;
    return undef if $SendHeaders_sent++;	# make idempotent
    push(@hdrs, ContentTypeHdr()) unless @hdrs;
    if ($CGI::Base::NeedServerHeader) {	# Tacky but effective
	unshift(@hdrs, ServerHdr()) unless $hdrs[0]=~m:^HTTP/\d:;
    }
    my $msg = join("", @hdrs);
    print $msg;
    local($|) = 1;	# flush the headers out to the client now
    print "\r\n";	# extra line to mark end of headers
    $msg;		# return what was sent (for logging etc)
}

# Header constructors:

sub ContentTypeHdr {
    "Content-Type: ".($_[0] || 'text/html')."\r\n";
}
sub LocationHdr {
    "Location: $_[0]\r\n";
}
sub StatusHdr {
    my($status, $msg) = @_;
    sprintf("Status: %03d %s\r\n", $status, $msg);
}
# TO DO: Add one for "Pragma: no-cache"
# TO DO: Document the handy "Status: 204 No Content"
sub ServerHdr {
    my($status, $msg) = @_;
    $status = 200 unless defined $status;
    unless ($msg){ # XXX lookup standard msgs for $status codes?
	$msg = "No reason text supplied";
    }
    "HTTP/1.0 $status $msg\r\n"
	."Server: $CGI::Base::SERVER_SOFTWARE\r\n";
}


{ # Execute simple test if run as a script
  package main; no strict;
  eval join('',<main::DATA>) || die "$@ $main::DATA" unless caller();
}

1;

__END__
# Test code. Execute this module as a CGI script.

import CGI::Base;

SendHeaders();

$cgi = new CGI::Base;
$cgi->get;

print "<ISINDEX>\r\n"; # try: "aa bb+cc dd=ee ff&gg hh<P>ii;"

print $cgi->as_string;

# end
