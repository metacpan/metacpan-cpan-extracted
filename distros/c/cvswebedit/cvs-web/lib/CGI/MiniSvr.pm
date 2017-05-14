#!/usr/local/bin/perl -w

package CGI::MiniSvr;

require 5.001;

use CGI::Carp;
use Socket;
use Exporter;
use CGI::Base qw(:DEFAULT :CGI :HDR);
use sigtrap;				# handy while debugging

@ISA = qw(CGI::Base Exporter);
@EXPORT = ();

# use strict qw(refs subs);

$Revision = '$Id: MiniSvr.pm,v 2.75 1996/2/15 04:54:10 lstein Exp $';
($VERSION = $Revision) =~ s/.*(\d+\.\d+).*/$1/;

my $Debug = 0;


=head1 NAME

CGI::MiniSvr - Adds to CGI::Base the ability for a CGI script to become
a mini http server.


=head1 SYNOPSIS

	

    use CGI::MiniSvr;
	
    $cgi = new CGI::MiniSvr;
    $cgi = new CGI::MiniSvr $port_or_path;
    $cgi = new CGI::MiniSvr $port_or_path, $timeout_mins;
	
    $cgi->port;               # return MiniSvr port number with leading colon

    $cgi->spawn;              # fork/detach from httpd
	
    $cgi->get;                # get input
	
    $cgi->pass_thru($host, $port);
    $cgi->redirect($url);
	
    $cgi->done;               # end 'page' and close connection (high-level)
    $cgi->close;              # just close connection (low-level)


See also the CGI::Base methods.


=head1 DESCRIPTION

This file implements the CGI::MiniSvr object. This object represents an
alternative I<interface> between the application and an HTTP deamon.

In a typical CGI scenario the I<interface> is just a collection of
environment variables passed to a process which then generated some
outout and exits. The CGI::Base class implements this standard
interface.

The CGI::MiniSvr class inherits from CGI::Base and extends it to
implement a 'mini http daemon' which can be spawned (forked) from a CGI
script in order to maintain state information for a client 'session'.

This is very useful. It neatly side-steps many of the painful issues
involved in writing real-world multi-screen applications using the
standard CGI interface (namely saving and restoring state between
screens).

Another use for the MiniSvr is to allow cgi scripts to produce output
pages with dynamically generated in-line graphics (for example). To do
this the script would spawn a MiniSvr and refer to its port number in
the URL's for the embedded images. The MiniSvr would then sit on the
port, with a relatively short timeout, ready to serve the requests for
those images.  Once all the images have been served the MiniSvr would
simply exit.

Like the CGI::Base module the CGI::MiniSvr module does not do any
significant data parsing. Higher level query processing (forms etc) is
performed by the CGI::Request module.

Note that the implementation of these modules means that you should
invoke C<new CGI::Base;> before C<new CGI::MiniSvr;>. This is the
natural order anyway and so should not be a problem.


=head2 WARNING!

This module is B<not> a good solution to many problems! It is only a good
solution to some. It should only be used by those who understand why it
is B<not> a good solution to many problems!

For those who don't see the pitfalls of the mini server approach,
consider just this one example:  what happens to your machine if new
'sessions' start, on average, faster than abandoned ones timeout?

Security and short-lifespan URL's are some of the other problems.

If in doubt don't use it! If you do then don't blame me for any of the
problems you may (will) experience. B<You have been warned!>


=head2 DIRECT ACCESS USAGE

In this mode the MiniSvr creates an internet domain socket and returns
to the client a page with URL's which contain the MiniSvr's own port
number.

  $q = GetRequest();      # get initial request
  $cgi = new CGI::MiniSvr;# were going to switch to CGI::MiniSvr later
  $port = $cgi->port;     # get our port number (as ':NNNN') for use in URL's
  $me = "http://$SERVER_NAME$port$SCRIPT_NAME"; # build my url
  print "Hello... <A HREF="$me?INSIDE"> Step Inside ...</A>\r\n";
  $cgi->done(1);          # flush out page, include debugging
  $cgi->spawn and exit 0; # fork, original cgi process exits
  CGI::Request::Interface($cgi); # default to new interface

  while($q = GetQuery() or $cgi->exit){ # await request/timeout
     ...
  }


=head2 INDIRECT ACCESS USAGE

In this mode the MiniSvr creates a unix domain socket and returns to the
client a page with a hidden field containing the path to the socket.

  $q = GetRequest(); # get initial request
  $path = $q->param('_minisvr_socket_path');
  if ($path) {
      # just pass request on to our mini server
      $q->cgi->pass_thru('', $path) or (...handle timeout...)
      $q->cgi->done;
  } else {
      # launch new mini server
      $path = "/tmp/cgi.$$";
      $cgi = new CGI::MiniSvr $path; # unix domain socket
      # code here mostly same as 'DIRECT ACCESS' above except that
      # the returned page has an embedded field _minisvr_socket_path
      # set to $path
      ...
  }

=head2 SUBCLASSING THE MINISVR

In some cases you may wish to have more control over the behaviour of
the mini-server, such as handling some requests at a low level without
disturbing the application.  Subclassing the server is generally a good
approach. Use something like this:

  #   Define a specialised subclass of the MiniSvr for this application
  {
    package CGI::MiniSvr::FOO;
    use CGI::MiniSvr;
    @ISA = qw(CGI::MiniSvr);

    # Default behaviour for everything except GET requests for .(gif|html|jpg)
    # Note that we must take great care not to: a) try to pass_thru to ourselves
    # (it would hang), or b) pass_thru to the server a request which it will
    # try to satisfy by starting another instance of this same script!

    sub method_GET {
        my $self = shift;
        if ($self->{SCRIPT_NAME} =~ m/\.(gif|jpg|html)$/){
            $self->pass_thru('', $self->{ORIG_SERVER_PORT});
            $self->done;
            return 'NEXT';
        }
        1;
    }
    # ... other overriding methods can be defined here ...
  }

Once defined you can use your new customised mini server by changing:

  $cgi = new CGI::MiniSvr;

into:

  $cgi = new CGI::MiniSvr::FOO;

With the example code above any requests for gif, jpg or html will be
forwarded to the server which originally invoked this script. The application
no longer has to deal with them. I<Note:> this is just an example usage
for the mechanism, you would typically generate pages in which any
embedded images had URL's which refer explicitly to the main httpd.

With a slight change in the code above you can arrange for the handling
of the pass-thru to occur in a subprocess. This frees the main process
to handle other requests. Since the MiniSvr typically only exists for
one process, forking off a subprocess to handle a request is only
useful for browsers such as Netscape which make multiple parallel
requests for inline images.

    if ($self->{SCRIPT_NAME} =~ m/\.(gif|html|jpg)$/){
        if ($self->fork == 0) {
            $self->pass_thru('', $self->{ORIG_SERVER_PORT});
            $self->exit;
        }
        $self->done;
        return 'NEXT';
    }

Note that forking can be expensive. It might not be worth doing for
small images.

=head2 FEATURES

Object oriented and sub-classable.

Transparent low-level peer validation (no application involvement
but extensible through subclassing).

Transparent low-level pass_thru/redirecting of URL's the application
is not interested in  (no application involvement but extensible
through subclassing).

Effective timeout mechanism with default and per-call settings.

Good emulation of standard CGI interface (for code portability).


=head2 RECENT CHANGES

=over

=item 2.2 and 2.3

Slightly improved documentation. Added a basic fork() method. Fixed
timeout to throw an exception so it's reliable on systems which restart
system calls. Socket/stdio/filehandle code improved. Cleaned up
done/close relationship. Added experimental support for optionally
handling requests by forking on a case-by-case basis. This is handy for
serving multiple simultaneous image requests from Netscape for example.
Added notes about the MiniSvr, mainly from discussions with Jack Shirazi
Removed old explicit port searching code from _new_inet_socket().
Improved SIGPIPE handling (see CGI::Base).

=item 2.1

Fixed (worked around) a perl/stdio bug which affected POST handling.
Changed some uses of map to foreach. Slightly improved debugging.
Added support for any letter case in HTTP headers. Enhanced test code.

=item 2.0

Added more documentation and examples. The max pending connections
parameter for listen() can now be specified as a parameter to new().
SIGPIPE now ignored by default. Simplified inet socket code with ideas
from Jack Shirazi. Improved server Status-Line header handling. Fixed
validate_peer() error handling and redirect().  Simplified get_vars()
by splitting into get_valid_connection() and read_headers(). Moved
example method_GET() out of MiniSvr and into the test script.

The module file can be run as a cgi script to execute a demo/test. You
may need to chmod +x this file and teach your httpd that it can execute
*.pm files.

=item 1.18

Added note about possible use of MiniSvr to serve dynamically generated
in-line images. Added optional DoubleFork mechanism to spawn which
might be helpful for buggy httpd's, off by default.

=item 1.17

Added support for an 'indirect, off-net, access' via a local UNIX
domain socket in the file system. Now uses strict. ORIG_* values now
stored within object and not exported as globals (Base CGI vars
remain unchanged).  See CGI::Base for some more details.

=back

=head2 FUTURE DEVELOPMENTS

Full pod documentation.

None of this is perfect. All suggestions welcome.

Test unix domain socket mechanism.

Issue/problem - the handling of headers. Who outputs them and when? We
have a sequence of: headers, body, end, read, headers, body, end, read
etc. The problem is that a random piece of code can't tell if the
headers have been output yet. A good solution will probably have to
wait till we have better tools for writing HTML and we get away from
pages of print statements.

A method for setting PATH_INFO and PATH_TRANSLATED to meaningful values
would be handy.


=head2 AUTHOR, COPYRIGHT and ACKNOWLEDGEMENTS

This code is Copyright (C) Tim Bunce 1995. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This module includes ideas from Pratap Pereira
<pereira@ee.eng.ohio-state.edu>, Jack Shirazi <js@biu.icnet.uk> and
others.

IN NO EVENT SHALL THE AUTHORS BE LIABLE TO ANY PARTY FOR DIRECT,
INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION (INCLUDING, BUT NOT
LIMITED TO, LOST PROFITS) EVEN IF THE AUTHORS HAVE BEEN ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

=head2 SEE ALSO

CGI::Base, CGI::Request, URI::URL

=head2 SUPPORT

Please use comp.infosystems.www.* and comp.lang.perl.misc for support.
Please do _NOT_ contact the author directly. I'm sorry but I just don't
have the time.

=cut

my $Version  = $Revision; $Version =~ s/.*(\d+\.\d+).*/$1/;
my $MaxForkTries = 5;

# Define low default timeout (in fractional minutes) and sensible range limits
my $DefaultTimeout = 2;
my $MinTimeout     = 1;
my $MaxTimeout     = 60 * 2;

my @HEADERS;	# store all HTTP headers for current request


sub new {			# should only ever be called once
    my($class, $portpath, $maxlisten) = @_;
    $portpath  = '' unless defined $portpath;
    $maxlisten = 5  unless $maxlisten;

    # get a CGI::Base object	(it's actually always the same one)
    my $cgi = new CGI::Base;

    # Force immediate processing of environment from HTTPD CGI.
    # Note that this is a CGI::Base->get and not a CGI::MiniSvr->get.
    $cgi->get;

    # Save a copy of the original environment values into
    # self with prefix of ORIG_*
    foreach ($cgi->vars) { $cgi->{"ORIG_$_"} = $ENV{$_} }

    # Create a socket for this MiniSvr instance to use.
    my $fh = $class->_newfh;	# new unopened file handle ref

    if ($portpath and $portpath !~ m/^\d+$/) {
	# file system / non-network / private socket
	_new_unix_socket($fh, $portpath) or confess $!;
	$cgi->{'port'} = '';
    } else {
	# internet / public socket
	$cgi->{'port'} = _new_inet_socket($fh, $portpath) or confess $!;
    }

    listen($fh, $maxlisten) or confess "listen($maxlisten): $!";

    $cgi->sigpipe_catch unless $SIG{PIPE};
    $cgi->{'timeout'} = $DefaultTimeout;
    $cgi->{'socket'}  = $fh;

    bless $cgi, $class;	# re-bless from CGI::Base
    $cgi;
}


sub _new_unix_socket {
    my($fh, $portpath) = @_;
    socket($fh, AF_UNIX, SOCK_STREAM, 0) or confess "socket($portpath): $!";
    my $inaddr = pack('S a', AF_INET, $portpath);
    unless (bind($fh, $inaddr)) {
	my $err = "bind: $!";
	close($fh);
	confess $err;
    }
    1;
}

sub _new_inet_socket {
    my($fh, $portpath) = @_;

    socket($fh, PF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2])
	or confess "socket(tcp): $!";

    # If no port, use 0. System will assign a port.
    $portpath = $portpath ? int($portpath) : 0 ;

    my $inaddr = pack('S n C4 x8', AF_INET, $portpath, 0,0,0,0);

    unless (bind($fh, $inaddr)) {
	my $err = "bind: $!";
	close($fh);
	confess $err;
    }
    # retrieve the assigned port
    # note that we leave $SERVER_PORT unchanged (typically 80)
    $portpath = (unpack('S n C4 x8',getsockname($fh)))[1];

    # return port.
    $portpath;
}


sub port {
    my $port = $_[0]->{'port'};
    ($port) ? ":$port" : "";
}

sub _as_string_extra {		# called by inherited as_string()
    "\nCGI::MiniSvr version $Version, pid=$$<P>";
} 


sub spawn {
    my $self = shift;
    $self->log("Spawning detached miniserver");
    $self->close;	# flush
    open(STDERR,">/dev/null") unless $self->is_logging;
    $self->fork;
}

sub fork {
    my $self = shift;
    # Basic fork used by spawn to spwan and method_* to hand-off handling
    # a request (such as an image) to a subprocess.
    my($pid, $tries);
    while ( ($pid = fork) < 0 ){
	$self->end("fork failed") if ++$tries > $MaxForkTries;
	$self->log("spawn: fork $!");
	sleep 1;
    }
    $pid;
}


sub DESTROY {
    my $self = shift;
    my $class = ref $self;
    close($self->{'socket'});
    $self->log("$class TERMINATING");
}


# --- This code implements the core of the mini server


sub accept_timeout {
    # don't stdio from signal handlers (but malloc's not much better)
    # my $msg = "accept_timeout: SIG@_\n";
    # syswrite(STDERR, $msg, length($msg));
    die "Interrupted\n";	# see await_connect()
}


sub await_connect {
    my($self, $timeout) = @_;
    my $peer;
    my $fh = $self->{'socket'};
    $self->log("Awaiting connection on port $self->{'port'} "
		."($timeout minute timeout) ...") if $Debug;

    eval {	# catch die from accept_timeout SIGALRM handler
	local($SIG{'ALRM'}) = \&accept_timeout; # local for auto reset
	alarm($timeout * 60);
	$peer = accept(CLIENT, $fh); # Block waiting for client
	alarm(0);
    };

    unless ($peer){
	my $err = "accept() failed: ". ( $@ ? $@ : $!);
	$err = 'Timeout' if $err =~ m/Interrupted/i;
	$self->log($err);
	return undef;
    }
    open(STDIN ,"<&CLIENT") or confess $!;
    open(STDOUT,">&CLIENT") or confess $!;
    close(CLIENT) or confess $!;
    $peer;
}


sub validate_peer {
    # protocol level check only, application checks are separate
    my($self, $peer, $dotquad, $hostname) = @_;

    return 1 if (   $dotquad  eq $CGI::Base::REMOTE_ADDR
		and $hostname eq $CGI::Base::REMOTE_HOST);

    # I've been told that some very large service providers
    # may be dynamically proxying on a per-request basis!
    # If that becomes a problem we'll have to look at this again.

    $self->log("validate_peer: $hostname ($dotquad) REFUSED,"
	." expecting $CGI::Base::REMOTE_HOST ($CGI::Base::REMOTE_ADDR)");
    SendHeaders(ServerHdr(), ContentTypeHdr());
    print "<H2>Connection refused (from $hostname $dotquad)</H2><P>";
    print "You are not the expected client for this server.\r\n";
    $self->done;
    0;
}


sub get_valid_connection {
    # blocks waiting for connection, returns false on timeout
    my($self, $timeout) = @_;
    my($peer, $dotquad, $hostname, $uri);

    $timeout = $self->{'timeout'} unless $timeout;
    $timeout = $DefaultTimeout    unless $timeout;
    $timeout = $MinTimeout if $timeout < $MinTimeout;
    $timeout = $MaxTimeout if $timeout > $MaxTimeout;

    do {
	$peer = $self->await_connect($timeout);

	return undef unless $peer;	# Timeout etc

	my ($family, $port, @addr) = unpack("S n C4 x8", $peer);
	$dotquad = join('.', @addr);
	$hostname = (gethostbyaddr(pack("C4",@addr), AF_INET))[0];
	$hostname = $dotquad unless $hostname;

	$self->log("Connection from $hostname ($dotquad:$port)");

    } until $self->validate_peer($peer, $dotquad, $hostname);

    1;
}


sub get_vars {
    my($self, $timeout) = @_;

    $CGI::Base::NeedServerHeader = 1;

    $self->sigpipe_reset;	# forget any earlier SIGPIPE

    # blocks waiting for connection, returns false on timeout
    $self->get_valid_connection($timeout) or return undef;

    $self->read_headers(\*STDIN);
}


sub read_headers {
    my($self, $fh) = @_;
    my($uri);

    local($_) = scalar <$fh>;	# read first line

    if (m/^\s+$/) {	# POST bug workaround
	$_ = scalar <$fh>;	# read real first line
	$self->log("Warning: CGI::MiniSvr needed to skip initial blank line");
    }

    if ($Debug >= 2) {
	my $line = $_;
	$line =~ s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
        $line =~ s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
	$self->log("Request-Line: $line");
    }

    ($REQUEST_METHOD, $uri, $SERVER_PROTOCOL) = split;
    ($SCRIPT_NAME, $QUERY_STRING) = split(/\?/, $uri, 2);

    $SERVER_PROTOCOL = "HTTP/0.9" unless $SERVER_PROTOCOL;
    $QUERY_STRING    = ''         unless $QUERY_STRING;

    $SERVER_SOFTWARE	= "PERL_CGI_MINISVR/$Version";
    $GATEWAY_INTERFACE	= 'CGI/1.1';

    $self->{URI} = $uri;

    # Do we need $PATH_INFO and $PATH_TRANSLATED ?
    # Or just leave them untouched from original CGI values?

    @HTTP_ACCEPT = ();
    @HEADERS     = ($_);

    my($key, $val, $last_key);
    while (<$fh>) {
	push(@HEADERS, $_);	# record for possible redirection
	s/\s+$//;		# remove trailing whitespace
	last if $_ eq '';	# end of headers
        if (s/^\s+//){		# continuation line ?
	    # Umm, what to do about this ?
	    $self->log("Continuation line for '$last_key' skipped!");
	    next;
	}
	# $self->log("read '$_'") if $Debug;
        # XXX handle split header lines
	# XXX Need better (more general) scheme than this!
	($key, $val) = m/^(.*?:)\s*(.*)/;
	if ($key eq 'Accept:'){
	    push(@HTTP_ACCEPT, $val);
	} elsif ($key eq 'User-Agent:'){
	    $HTTP_USER_AGENT = $val;
	} elsif ($key eq 'Referer:'){
	    $HTTP_REFERER = $val;
	} else {
	    $self->{lc($key)}	= $val;	# NOTE: save with known case
	    # $self->log("Attrib '$key' = '$val' not known") if $Debug;
	}
	$last_key = $key;
    }

    $HTTP_ACCEPT = join(', ',@HTTP_ACCEPT);

    # Set CGI vars from headers (e.g., $CONTENT_LENGTH from 'Content-Length:')
    foreach ($self->vars){
	my $hdr = $self->attr($_, 'HDR');	# HDR's must be all lowercase
	next unless $hdr and $self->{$hdr};
        $self->var($_, $self->{$hdr});
    }

    1;
}



sub close {	# disconnect from client
    my($self) = @_;
# These close()s should not be needed but perl/stdio problems
# mean that await_connect (accept) may setup a STDIN which
# has characters left over from a previous connection!
# I think this is fixed now so the closes are commented out.
# close(STDIN); close(STDOUT);
    # much safer to open to /dev/null than to just close STDIN/OUT
    open(STDIN, "</dev/null");
    open(STDOUT,">/dev/null");
}

sub exit {              # Terminate, and optionally log a message
    my $self = shift;
    $self->close;
    $self->CGI::Base::exit(@_);
}

sub pass_thru_headers {
    join('', @HEADERS);
}




{ # Execute simple test if run as a script
  package main; no strict;
  $INC{'CGI/MiniSvr.pm'} = 1;
  eval join('',<main::DATA>) || die "$@ $main::DATA" unless caller();
}


1;

__END__

import CGI::Base qw(:DEFAULT :CGI);
import CGI::MiniSvr;
use CGI::Request;


#   Define a specialised subclass of the MiniSvr for this test application
{
    package CGI::MiniSvr::Test;
    use CGI::MiniSvr;
    @ISA = qw(CGI::MiniSvr);

    # Default behaviour for everything except GET requests for .(gif|html|jpg)

    # Note that we must take great care not to: a) try to pass_thru to ourselves
    # (it would hang), or b) pass_thru to the server a request which it will
    # try to satisfy by starting another instance of this same script!

    sub method_GET {
	my $self = shift;
	if ($self->{SCRIPT_NAME} =~ m/\.(gif|html|jpg)$/){
	    # Experimental forking handler code
	    if ($self->fork == 0) {
		$self->pass_thru('', $self->{ORIG_SERVER_PORT});
		$self->exit;
	    }
	    $self->done;
	    return 'NEXT';
	}
	1;
    }
}


chdir("/home/timbo/WWW/cgi");
CGI::Base::LogFile("cgi.log") unless -t STDIN;
$req = GetRequest('R');	# fetch initial request from default interface (CGI::Base)

# Get a minisvr to switch to later:
$cgi = new CGI::MiniSvr::Test;	# see code at bottom of this file
$port = $cgi->port;	# get our port number (as ':NNNN') for use in URL's
$me = "http://$SERVER_NAME$port$SCRIPT_NAME";

print "\n<HEAD><TITLE>CGI::MiniSvr test ".`pwd; date`."</TITLE></HEAD>\n";

print <<END;
<BODY>
<P>CGI mini-server starting on $SERVER_NAME$port.<P> 
<A HREF="$me?step=inside"><B> Step Inside ...</B></A>
END
print $req->as_string;
$cgi->done;

$cgi->exit('Aborted - test mode (not running under HTTPD')
	unless $REMOTE_ADDR and !-t STDIN;


# --- Detach from HTTPD by forking child process and terminating the parent

$cgi->spawn and exit 0;


# --- Now running in child

# Tell CGI::Request to use our chosen interface by default. This just avoids
# the need to pass CGI::Request the reference each time.

CGI::Request::Interface($cgi);


# get results from previous prompt

$req = GetRequest() or $cgi->exit;

# Here's a trivial example of the sort of linear coding which
# you just can't do without the miniserver concept.
# Eventually we'll have constructors for compostite widgets
# and named forms in event loops...

my $string1 = string_prompt($cgi, 'Example prompt 1', 'edit me!');

my $string2 = string_prompt($cgi, 'Prompt 2 (defaults to your last entry)', $string1);

CGI::Base::Debug(2);
CGI::Request::Debug(2);

while (1) {

    SendHeaders();

    print "\n<HEAD><TITLE>CGI MiniSvr $$ ".`date`." $SCRIPT_NAME</TITLE></HEAD>\n";

    print <<END;
    <BODY>
    <ISINDEX>
    TEST1: <A HREF="$me"          > "$me" </A> <BR> 
    TEST2: <A HREF="$me?TEST2+A+B"> "$me?TEST2+A+B" </A> <BR> 
    TEST3: <A HREF="$me?TEST3=XYZ"> "$me?TEST3=XYZ" </A> <BR> 
    TEST4: <A HREF="$me/TEST4"    > "$me/TEST4" </A> <BR> 
    <A HREF="http://$SERVER_NAME$cgi->{ORIG_SCRIPT_NAME}" > START NEW MiniSvr  </A> <BR>
    <A HREF="$me?QUIT" > QUIT  </A> <P> 
    <P>Images:
    <IMG SRC="http://$SERVER_NAME:80/gifs/misc/Warning.gif"> Served via httpd
    <IMG SRC="http:/gifs/misc/Warning.gif"> Served via CGI::MiniSvr pass-thru!
END

    print <<END;
    <FORM METHOD="POST" ACTION="$SCRIPT_NAME/FORM">
    String: <INPUT NAME="string" SIZE=5>
    Number: <INPUT NAME="number" SIZE=5>
    <INPUT TYPE="radio" NAME="radio" VALUE="A" CHECKED> A
    <INPUT TYPE="radio" NAME="radio" VALUE="B"> B
    <SELECT NAME="option"><OPTION>One<OPTION>Two</SELECT>
    <INPUT TYPE="reset" VALUE="Reset">.
    <INPUT TYPE="submit" VALUE="Submit">
    </FORM>
Query: $QUERY_STRING
END
    if ($SCRIPT_NAME =~ m:/FORM$:){
	print "<HR><H2>You selected:</H2><P><PRE>
String: $R::string, Number: $R::number, $R::radio, $R::option
</PRE>
"
    }

    print $req->as_string;
    $cgi->done;

    $req = GetRequest('R') or $cgi->exit;	# new request or timeout

    # user asked to quit
    if ($QUERY_STRING =~ /QUIT$/){
	# redirect to somewhere else
	$cgi->redirect("http://$SERVER_NAME:80/gifs/misc/Warning.gif");
	$cgi->done;
	last;
    }

}

$cgi->exit;



# Self-contained dialogue function (currently very primitive)

sub string_prompt {
    my($cgi, $prompt, $default) = @_;
    $default = '' unless defined $default;

    SendHeaders();

    print <<END;
<HEAD><TITLE>Example simple prompt</TITLE></HEAD>
<BODY><FORM>
    $prompt: <INPUT NAME="string_prompt" TYPE=TEXT VALUE="$default">
</FORM>
END
    print $cgi->as_string;
    $cgi->done;

    my $req = new CGI::Request or $cgi->exit; # new request or timeout
    $req->param('string_prompt');
}



$dummy = <<'END_OF_NOTES';
--------------------------------------------------------------------------------------
With regard to the validate_peer method:

From: Andy Finkenstadt <andyf9@genie.is.ge.com>
Date: Mon, 20 Mar 1995 23:06:08 -0500 (EST)

> It's the latter, but can you explain *in detail* how the firewall
> in use by one client would change from minute to minute ?
> Does this happen often in practice or is it a theoretical problem?

It is not a theoretical problem -- Prodigy, CompuServe, and America
Online all use multiple egress firewalls through which they generate
connections from web proxy servers (plural) inside the firewall, each
serving multiple clients.  This is easily determined by inspection of
the DNS records.

GEnie plans to have a similar setup.  Our internal DNS provides
round-robin resource records to clients via "egress.genie.net" which
randomly selects a firewall through which to establish a connection.
Currently this resolves to the INTERNAL address of what is known on the
net as "fw1.genie.net" and "fw2.genie.net".  199.164.140.{11|12}.

Prodigy has already released about 500,000 new people onto the Web.
Both America Online and CompuServe are going to add another 2 million
or so on top of that, and GEnie will add a much more modest amount. :)
By my calculations this increases the universe of web users by a factor
of 50-75% (my business partner just quirped up and said more than
doubles the number!) in the span of about 6 months.

It may be a theoretical problem today; it will be a practial problem
tomorrow, as more companies and other sites create robust
fault-tolerant solutions for connecting to the 'net securely.
(oxymoron alert!)

I just wanted to alert yo to a potential problem given what
I *know* will be happening in the very near future.

-Andy
--------------------------------------------------------------------------------------

Message Headers

 Convert to HTTP_* variables ?
 Accumulate repeats into array ?
 Deal with split lines!
 How to deal with non-'standard' case (upper/lower/mixed etc) ?
 Note that HTTPD CGI will pass them as $ENV{'HTTP_*'} (uppercased name)

   General-Header = Date
		  | Forwarded
		  | Message-ID
		  | MIME-Version
		  | extension-header
   Request-Header = Accept
		  | Accept-Charset
		  | Accept-Encoding
		  | Accept-Language
		  | Authorization
		  | From
		  | If-Modified-Since
		  | Pragma
		  | Referer
		  | User-Agent
		  | extension-header
   Entity-Header  = Allow
		  | Content-Encoding
		  | Content-Language
		  | Content-Length
		  | Content-Transfer-Encoding
		  | Content-Type
		  | Derived-From
		  | Expires
		  | Last-Modified
		  | Link
		  | Location
		  | Title
		  | URI-header
		  | Version
		  | extension-header
--------------------------------------------------------------------------------------

Assorted (unsorted) notes about the MiniSvr, mainly from discussions with
Jack Shirazi:

> > > The troubles with MiniSvr are that:
> > > 1. It scales very badly. One process hanging around per initial query
> > > means that batches of queries will bring the server machine to its knees.
> > 
> > On the contrary, the process startup overheads of the traditional
> > approach have a much greater impact. The per-transaction cost of the
> > mini-server approach is very low. The first thing a collegue said when
> > I showed her the first prototype was "wow, that's fast!".
> 
> That's the transactions after the initial connection. Obviously subsequent
> transactions are fast to the user since the server has no startup overhead.
> I am talking about the cost to the server _machine_ in having a separate
> extra process hanging around after every time a specific cgi script
> is started.
> 
> Say timeout is 20 mins.
> With MinSvr, 5 initiating connections to the original CGI script
> within 20 minutes gives 5 servers. 50 initiating connections
> gives 50 servers. Have a number of CGI scripts which use this,
> and hey presto 'No swap available, cannot start anything - and
> all other processes start thrashing from the lack of swap'.
> 
You are assuming a) a long default timeout and b) that everyone orphans
their mini-server. The former is possible, the latter is unrealistic.

The only time a mini-server would be orphaned (for want of a better term)
would be if the user does not follow one of the links on a page produced
by the mini-server. Typically a 'commit' button would commit the changes
to the database and the mini-server would produce a new page and exit.


> 2. Many's the time I've sent off a www query, got the result and left it
> for a long time before responding to it (sometimes overnight). How long
> is the MiniSvr going to wait for?

That's an application choice. The default will probably be around 5 minutes.
Some applications may set it higher, some lower. Some may change it from
dynamically.

> The longer it waits, the worse it gets
> for the server machine. The shorter it waits, the more annoyed I (and
> all its other clients) are going to get when we post back the form
> only to get a 'Server not responding' message.

That's a tradeoff you have to make. It would be possible to have a field
on the form to allow a user settable timeout (within application limits).

> 3. Security of CGI bin scripts has a bad enough reputation at the moment.
> This will make it worse.
> 
Why? Please explain in detail. Remember that the mini-server is started
by a full server which can deal with the 'big' authentication issues
and 'set the scene' before it starts the cgi script. I'm very happy to
add any checks as required but I need hard facts. The mini-server
already always re-validates the client ip address.


> In exactly the same way you plan to do it with the MiniSvr. You either keep
> a list of changes, or maintain the session in the external state server
> and rollback from there. How do you plan to do it with the MiniSvr?
> 
I think you're missing the point. I'm talking about relational database
transactions made by a client over a series of forms.

You *cannot* simply 'keep a list of changes' because once a change is
commited other database users may have started using your changed data
and/or your changes may have triggered database procedures. Basically
once commited it's too late! With a process-per-form you'd have to commit.

Using an external server for this type of application is:
a) *much* more complicated form many reasons including the need to
pipe returned query data (how do you send a rows of data, possibly
including image blobs, back from the server to the cgi application?)
b) is only possible for databases which allow one process to manage/juggle
many distinct database connections.
c) has poor performance (latency) under load (unless you make the server
multi-threaded and few if any database vendors support multi-threaded clients).

> It starts up an internet socket. Anyone can connect to the socket -
> how are you validating that it was exactly the client that started the
> connection (in general - not for password registered forms only)? 

The mini-server currently validates that the same ip address is being
used. Other authentication checks can be added. Within reason any
authentication checks a full server can do a mini-server could also do.

> Each MiniSvr is going to have its own request processing - can
> you guarantee that this is always loophole free? No system accessing
> except where you stated - i.e taint free on all data inputted through
> the socket? Remember that the MiniSvr is a general mechanism - I'd
> be foolish to have mine be
> 
> startMiniSvr; $r=readRequest; eval $r;
> 
> But someone could do the equivalent without realizing it. HTTPD daemons
> have some of these problems with CGI scripts, but at least they get to
> 'validate' all the input to the machine. You would be bypassing that
> mechanism.
> 
This is no different to existing CGI applications. HTTPD daemons don't
'validate' the input in any meaningful sense. If you have a form with
an text field and your cgi script evals the contents of that field
the httpd will not stand in your way.

> What happens if the service proves popular - how many simultaneous
> processes are going to be hanging around at any one time?
> 
It's a trade-off. Swap-space vs process creation overhead.

END_OF_NOTES
