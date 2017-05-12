package Netscape::Registry;

# -------------------------------------------------------------------
#   Registry.pm - emulate perl CGI programming under nsapi_perl
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

# --- Attempt to emulate Apache::Registry for nsapi_perl
require Exporter;
use File::Basename;
use Netscape::Server::Socket;
use Netscape::Server qw/:all/;
#use strict; # - See Apache::Registry :-)
use subs qw/
    _cgi_env
    /;
use vars qw/
    %Registry
    @ISA
    @EXPORT_OK
    /;
@ISA = qw/
    Exporter
    /;
@EXPORT_OK = qw/
    exit
    /;

my $Is_Win32 = $^O eq "MSWin32";

sub handler {
    my($pb, $sn, $rq) = @_;
    my($path, $mtime, $size, $program, $package, $code, $dir, $basename, $last_gasp);
    my $sub = 'Netscape::Registry::handler';
    my @old_inc;
    my %old_env;

    # --- Get the path to the requested file
    $path = $rq->vars('path');
    unless (defined $path) {
	log_error(LOG_FAILURE, $sub, $sn, $rq, 'path not defined');
	return REQ_ABORTED;
    }

    # --- Sanity checks
    unless (-f $path) {
	log_error(LOG_FAILURE, $sub, $sn, $rq, "$path: not a plain file");
	return REQ_ABORTED;
    }
       unless ($Is_Win32 or -x _) {
	log_error(LOG_FAILURE, $sub, $sn, $rq, "$path: cannot execute");
	return REQ_ABORTED;
    }

    # --- Set up the environment to be like CGI
    %old_env = %ENV;
    %ENV = &_cgi_env($sn, $rq);

    # --- Tie STDOUT to this session
    tie(*STDOUT, 'Netscape::Server::Socket', $sn, $rq) or do {
	log_error(LOG_FAILURE, $sub, $sn, $rq, 'unable to tie STDOUT to socket');
	return REQ_ABORTED;
    };

    # --- Tie STDIN to this session
    tie(*STDIN, 'Netscape::Server::Socket', $sn, $rq) or do {
	log_error(LOG_FAILURE, $sub, $sn, $rq, 'unable to tie STDIN to socket');
	return REQ_ABORTED;
    };

    # --- Create a fake package name to compile the program into
    ($package = $path) =~ tr/a-zA-Z0-9_/_/c; # - This might not be unique but it's close enough for now
    $package = "Netscape::Registry::CGI_$package";

    # --- Chdir to the right place
    $dir = dirname($path);
    chdir $dir or do {
	log_error(LOG_FAILURE, $sub, $sn, $rq, "unable to change to $dir: $!");
	return REQ_ABORTED;
    };

    # --- See whether the file has changed or not
    $size = (stat(_))[7];
    $mtime = (stat(_))[9];
    if ((not defined $Registry{$path}) or
	$size != $Registry{$path}{'size'} or
	$mtime != $Registry{$path}{'mtime'}) {

	# --- The file has changed

	# --- Slurp it in
      INPUT: {
	  local $/; undef $/;
	  open(INPUT, $path) or do {
	      log_error(LOG_FAILURE, $sub, $sn, $rq, "couldn't open $path: $!");
	      return REQ_ABORTED;
	  };
	  $program = <INPUT>;
	  close INPUT;
      }
	
	# --- Build up a fake module to compile
	$code = <<_END_CGI_;
	
CGI_PROGRAM: {
    package $package;
    use Netscape::Registry qw/exit/;
    # --- nsapi_perl_init.pl might have mucked if @INC
    \@INC = \@lib::ORIG_INC if \@lib::ORIG_INC;
    sub cgi_program {
        $program
    }
}
_END_CGI_
    ;

	# --- Compile it
	eval $code;
	if ($@) {
	    $last_gasp = $@;
	    log_error(LOG_FAILURE, $sub, $sn, $rq, "trouble compiling $path: $last_gasp");
	    return REQ_ABORTED;
	}
	
	# --- Store the info
	$Registry{$path}{'size'} = $size;
	$Registry{$path}{'mtime'} = $mtime;
	$Registry{$path}{'code'} = $code;
    } else {
	$code = $Registry{$path}{'code'};
    }
    
    # --- Do it
    eval { $package->cgi_program; };

    if ($@ and $@ !~ /Netscape::Registry::exit called/) {
	$last_gasp = $@;
	log_error(LOG_FAILURE, $sub, $sn, $rq, "trouble running $path: $last_gasp");
	return REQ_ABORTED;
    }

    # --- Clean up
    eval {&CGI::_reset_globals};
    %ENV = %old_env;
    return REQ_PROCEED;
}

sub exit {
    # --- Used to override the built-in within called CGI programs
    die "Netscape::Registry::exit called\n";
}

sub _cgi_env {
    # --- Little hack to set the environment up to be like CGI.
    # --- This will need reworking later.
    my($sn, $rq) = @_;
    my(%env);

    # --- Set up all the HTTP_ ones
    my $headers = $rq->headers;
    while ((my $key, my $value) = each %$headers) {
	$key =~ tr/a-z\-/A-Z_/;
	$env{"HTTP_$key"} = $value;
    }

    # --- Now just go through a fixed list in a dumb, ugly way
    $env{'HTTPS'} = 'OFF'; # :-)
    $env{'AUTH_TYPE'} = $rq->vars('auth-type') if defined $rq->vars('auth-type');
    $env{'REMOTE_USER'} = $rq->vars('auth-user') if defined $rq->vars('auth-user');
    $env{'REMOTE_ADDR'} = $sn->remote_addr;
    $env{'REMOTE_HOST'} = $sn->remote_host;
    $env{'REQUEST_METHOD'} = $rq->request_method;
    $env{'SERVER_PROTOCOL'} = $rq->server_protocol;
    $env{'QUERY_STRING'} = $rq->query_string if defined $rq->query_string;
    $env{'PATH_INFO'} = $rq->path_info if defined $rq->path_info;
    $env{'PATH_TRANSLATED'} = $rq->vars('ntrans-base') . $env{'PATH_INFO'} if
	(defined $rq->vars('ntrans-base') and defined $env{'PATH_INFO'});
    $env{'SCRIPT_NAME'} = $rq->reqpb('uri'); $env{'SCRIPT_NAME'} =~ s/$env{'PATH_INFO'}$//;
    $env{'GATEWAY_INTERFACE'} = "CGI/1.1; nsapi_perl/$Netscape::Server::VERSION";
    $env{'CONTENT_LENGTH'} = $rq->headers('content-length') if defined $rq->headers('content-length');
    $env{'CONTENT_TYPE'} = $rq->headers('content-type') if defined $rq->headers('content-type');

    return %env;
}

1;

__END__

=head1 NAME

Netscape::Registry - emulate perl CGI programming under nsapi_perl

=head1 SYNOPSIS

In F<obj.conf>

 NameTrans fn="pfx2dir"
     from="/perl" dir="/full/path/to/perl" name="perl"

 <Object name="perl">
 ObjectType fn="force-type" type="application/perl"
 Service fn="nsapi_perl_handler" module="Netscape::Registry"
 </Object>

=head1 DESCRIPTION

This module allows CGI programs written in Perl to be run within the
Netscape httpd server process.  This provides a large performance
boost by reducing overhead from the normal fork/exec/compile process
for Perl CGI programs.  Netscape::Registry is loaded into the server
by nsapi_perl, the Perl interface to the Netscape httpd API.

For the full details of nsapi_perl, see L<nsapi_perl>.  Suffice it to
say here that nsapi_perl provides a mechanism by which a Perl
interpreter is embedded into a Netscape server.  The NSAPI can then be
programmed to in Perl rather than in C.  This is achieved by placing
the appropriate hooks in the server configuration files; nsapi_perl
will then call whatever Perl subroutines you wish at various stages of
processing a request from a client.

This module was inspired by and derived from Apache::Registry, which
provides the same functionality for the Apache web server.

=head1 USAGE

Basically you need to tell your Netscape server that all files
underneath a certain directory, or ending with a certain suffix, are
to be handled during the B<Service> stage of the transaction by the
Perl module B<Netscape::Registry>.  This generally involves editing
the file F<obj.conf>; see L<nsapi_perl> and your server's
documentation for full details.  See also L</EXAMPLES>.

After this initial setup, it's essentially CGI programming as per
normal.  However, since your scripts are actually run in the server
process, it's prudent to avoid the use of global variables since they
may by left around after your script has finished.

Netscape::Registry works with Lincoln Stein's CGI.pm module but you
should use version 2.36 or more recent; earlier versions may not clean
up global variables properly.

Compile and run-time errors from your scripts are written to the
server's error log.

See L</BUGS> for a summary of (some) known bugs.

=head1 INTERNALS

The first request for a given file causes the file to be compiled (by
eval()) into a subroutine whose package is is unique to that file.
The modification time and length of the source file are then stored in
a global hash.

The subroutine is then executed by a statement like this:

 eval {package->subroutine};

Each subsequent request for the file causes Netscape::Registry to
check the time stamp and size of the file.  If the file has changed,
it is recompiled and then executed.  If the file has not changed, it
is executed immediately.

Standard input and output are tie()d to the Netscape::Server::Socket
class.  This enables your script's output to be sent to the client.
It also lets your script read the content of POST-type requests on the
standard input (but don't do this yourself; let CGI.pm take care of it
for you).

The perl built-in exit() function is redefined to be a mutation of
die() - and hence trapable by the above eval() - so that it doesn't
cause grief for the server.

=head1 ENVIRONMENT

Netscape::Registry attempts to provide the same environment as for
normal CGI, but at the time of writing there are some differences.

=over 4

=item B<AUTH_TYPE>

This variable is the same as under regular CGI.  It is only defined if
the program being accessed is under access control.

=item B<CONTENT_LENGTH>

This variable is the same as under regular CGI.

=item B<CONTENT_TYPE>

This variable is the same as under regular CGI.

=item B<GATEWAY_INTERFACE>

This variable is defined as B<CGI/1.1; nsapi_perl/x.y> where B<x> and
B<y> are respectively the major and minor version numbers of
nsapi_perl.

=item B<HTTPS>

This variable is currently hardcoded to the value B<OFF>.  Let the
author know if this is a problem.

=item B<HTTP_*>

These variables, which represent the header lines from the client's
request header, are defined the same as they would be under regular
CGI.

=item B<PATH>

This variable is currently not defined under nsapi_perl but it is
under (at least some of) Netscape's implementations of CGI.  I don't
think it *should* be defined under CGI, so if you've come to rely on
it, that's your problem :-)

=item B<PATH_INFO>

This variable is the same as under regular CGI.

=item B<PATH_TRANSLATED>

Under Netscape's implementation of CGI, this variable (if defined) is
B<PATH_INFO> appended to the server's document root.  Under
nsapi_perl, this variable (if defined) is B<PATH_INFO> appended to the
full path to the script.  One of these implementations is probably in
error.

=item B<QUERY_STRING>

This variable is the same as under regular CGI.

=item B<REMOTE_ADDR>

This variable is the same as under regular CGI.

=item B<REMOTE_HOST>

This variable is the same as under regular CGI.

=item B<REQUEST_METHOD>

This variable is the same as under regular CGI.

=item B<REMOTE_USER>

This variable is the same as under regular CGI.  It is only defined if
the program being accessed is under access control.

=item B<SCRIPT_NAME>

This variable is the same as under regular CGI.

=item B<SERVER_NAME>

This variable is currently undefined under nsapi_perl.  This is a bug.

=item B<SERVER_PORT>

This variable is currently undefined under nsapi_perl.  This is a bug.

=item B<SERVER_PROTOCOL>

This variable is the same as under regular CGI.

=item B<SERVER_SOFTWARE>

This variable is currently undefined under nsapi_perl.  This is a bug.

=item B<SERVER_URL>

This variable is currently undefined under nsapi_perl.  This is a bug.

=back

=head1 BUGS

Command-line switches on your CGI scripts are currently ignored by
nsapi_perl.  For example, if you dutifully put

 #!/usr/bin/perl -w

at the start of your script, it will be ignored.

See L</ENVIRONMENT> for some important differences in environment
variables between nsapi_perl and regular CGI.

Extension modules that dynamically load a shared object may cause you
grief.  See the section titled B<DYNAMIC LOADING OF EXTENSION MODULES>
in L<nsapi_perl> if you suffer problems.  The good news is that such
modules are reported to work "out of the box" on Win32.

use CGI::Carp('fatalsToBrowser') doesn't work as expected.

CGI programs can't - or at least shouldn't - muck with @INC.

Expect other bugs and weirdness.  Please don't get mad; just report
them to nsapi_perl mailing list: nsapi_perl@samurai.com.

=head1 AUTHOR

Benjamin Sugars <bsugars@canoe.ca>

=head1 SEE ALSO

perl(1), nsapi_perl, modperl, Apache::Registry

=cut

