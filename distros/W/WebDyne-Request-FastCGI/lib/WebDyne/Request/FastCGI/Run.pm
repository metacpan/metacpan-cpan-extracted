#
#
#  Copyright (C) 2006-2010 Andrew Speer <andrew@webdyne.org>. All rights 
#  reserved.
#
#  This file is part of WebDyne::Request::FastCGI
#
#  WebDyne is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
package WebDyne::Request::FastCGI::Run;


#  Compiler Pragma
#
use strict	qw(vars);
use vars	qw($VERSION);


#  External modules
#
use WebDyne;
use WebDyne::Base;
use WebDyne::Request::FastCGI;
use WebDyne::Request::FastCGI::Constant;
use FCGI;
use CGI;
use HTTP::Status qw(RC_INTERNAL_SERVER_ERROR RC_NOT_FOUND);


#  Set handler as constant. No longer do this - load hander on per request basis on
#  information from dir_config.
#
#use constant WebDyneHandler=>$ENV{'WebDyneHandler'} ? $ENV{'WebDyneHandler'} : 'WebDyne';


#  Load up whichever handler we are using
#
#my $handler=WebDyneHandler;
#eval ("require $handler") || die("unable to load handler $handler, $@");


#  Version information
#
$VERSION='1.002';


#  Signal handlers (seem broken with lighttp, ignore for now
#
#$SIG{'USR1'}=sub { exit 0 };
#$SIG{'TERM'}=sub { exit 0 };
#$SIG{'PIPE'}='IGNORE';


#  Sig handler
#
#sub sig {
#    exit(0) if !$busy;
#    $exit++;
#}


#  CGI needs to be hacked under some versions of FastCGI so path_info returns correct string, otherwise
#  CGI->self_url does not return correct value, then forms with explicit action attr stop working
#
my $path_info_cr=\&CGI::path_info || die('unable to get CGI code ref for path_info');
*CGI::path_info=sub {
    my $path_info=$path_info_cr->(@_);
    $path_info=~s/^\Q$ENV{'SCRIPT_NAME'}\E//;
    $path_info;
};



#  Debug
#
#debug("wdfastcgi handler for pid $$ is $handler, env %s", &Data::Dumper::Dumper(\%ENV));


#  All done. Positive return
#
1;


#==================================================================================================


#  Start endless loop
#
sub start {


    #  Can optionally be passed a socket file name at start
    #
    my ($class, $socket_fn, $backlog)=@_;
    my $socket_fh=$socket_fn && do {
	$backlog ||=  WEBDYNE_FASTCGI_BACKLOG;
	FCGI::OpenSocket($socket_fn, $backlog) ||
	    die ("could not open socket $socket_fn, $!");
    };
    
    
    #  Workaround for perlbug 73672
    #
    my %env=%ENV;
    *ENV=\*env;


    #  Cache handler for a location
    #
    my ($handler, %handler);


    #  Get FastCGI request object
    #
    my $fcgi_r=$socket_fh ?
	FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV, $socket_fh) : FCGI::Request();
    my ($busy, $exit);
    
    
    while($busy=($fcgi_r->Accept() >= 0)) {


	#  Create new FastCGI Request object, will pull filename from
	#  environment. goto only invoked if no object created, which
	#  should never happen !
	#
    	my $r=WebDyne::Request::FastCGI->new() ||
	    goto RENDER_ERROR;
	    
	    
        #  Get handler
        #
        unless ($handler=$handler{my $location=$r->location()}) {
            my $handler_package=
                $r->dir_config('WebDyneHandler') || $ENV{'WebDyneHandler'};
            if ($handler_package) {
                local $SIG{'__DIE__'};
                unless (eval("require $handler_package")) {
                    #  Didn't load - let Webdyne handle the error.
                    $handler='WebDyne';
                }
                else {
                    $handler=$handler{$location}=$handler_package;
                }
            }
            else {
                $handler=$handler{$location}='WebDyne';
            }
        }


	#  Call handler and evaluate results
	#
	my $status=eval { $handler->handler($r) } if $handler;
	if (!defined($status)) {
	    if (($status=$r->status) ne RC_INTERNAL_SERVER_ERROR) {
		my $error=errdump() || $@; errclr();
		$r->custom_response(
		    $r->status($status=RC_INTERNAL_SERVER_ERROR),
		    $r->err_html($status, $error)
		);
	    }
	}
	elsif (($status < 0) && !(-f (my $fn=$r->filename()))) {
	    $r->status($status=RC_NOT_FOUND);
	    warn("file $fn not found") if $WEBDYNE_FASTCGI_WARN_ON_ERROR;
	}
	elsif ($status < 0) {
	    $r->custom_response(
		$r->status($status=RC_INTERNAL_SERVER_ERROR),
		$r->err_html($status, "Unexpected return ($status) from handler $handler")
	       );
	}
	debug("handler status was $status");


	#  If status ne Apache::OK invoke error handler
	#
	$status && $r->send_error_response();


	#  Done, call destoy manually so cleanup_handlers run
	#
	$r->DESTROY;


	#  Signal handlers broken, these never get checked
	#$busy=0;
	#last if $exit;
	next;


	#  Error handler, exceptional cases only (usually handled by
	#  WebDyne handler).
	#
	RENDER_ERROR:
	require CGI;
	my $error=errdump() || 'unknown error'; errclr();
	CORE::print 
	    sprintf("Status: %s\r\n", RC_INTERNAL_SERVER_ERROR),
	    "Content-Type: text\html\r\n\r\n",
		WebDyne::Request::FastCGI->err_html(RC_INTERNAL_SERVER_ERROR, CGI->pre($error));

    };

    #  All done, quit. Commented out due to broken sig handlers
    #
    #$fcgi_r->Finish();
    #exit(0);

}

