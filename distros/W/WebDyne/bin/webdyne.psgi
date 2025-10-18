#!/usr/bin/perl
#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#

package WebDyne::Request::PSGI::Run;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);


#  External Modules
#
use HTTP::Status qw(RC_INTERNAL_SERVER_ERROR RC_NOT_FOUND HTTP_OK);
use IO::String;
use Data::Dumper;


#  WebDyne Modules
#
use WebDyne;
use WebDyne::Constant;
use WebDyne::Util;
use WebDyne::Request::PSGI;
use WebDyne::Request::PSGI::Constant;


#  Version information
#
$VERSION='2.014';


#  Test file to use if no DOCUMENT_ROOT found
#
(my $test_dn=$INC{'WebDyne.pm'})=~s/\.pm$//;
my $test_fn=File::Spec->catfile($test_dn, 'time.psp');


#  All done. Start endless loop if called from command line or return
#  handler code ref.
#
if (!caller || exists $ENV{PAR_TEMP}) {

    #  Running from command line without being stared by plackup or starman
    #
    require Plack::Runner;
    my $plack_or=Plack::Runner->new();
    

    #  User specified --test on command line ? Note and consume before 
    #  passing to parse_options ?
    #
    my $test_fg;
    if ($test_fg=grep {/^--test$/} @ARGV) {
        @ARGV=grep {!/^--test$/} @ARGV;
    }
    
    
    #  Same with static handler
    #
    my $static_fg;
    if ($static_fg=grep {/^--static$/} @ARGV) {
        @ARGV=grep {!/^--static$/} @ARGV;
    }


    #  Mac conflicts with Plack default port of 5000 - choose 5001
    if ($^O eq 'darwin') {
        $plack_or->parse_options('--port', '5001', @ARGV);
    }
    else {
        $plack_or->parse_options(@ARGV);
    }
    
    
    #  Finalise DOCUMENT_ROOT. First try and get as last command line option or env or variable but --test
    #  flag wins over everything else
    #
    $DOCUMENT_ROOT=shift(@{$plack_or->{'argv'}}) ||
        $ENV{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT;
    if ($test_fg || !$DOCUMENT_ROOT) {
        $DOCUMENT_ROOT=$test_fn;
    }
    

    #  Done - run it
    #
    $plack_or->run(&handler_build($static_fg ? &handler_static(\&handler) : \&handler));
    exit 0;

}
else {

    #  Not running from comamnd line. Get DOCUMENT_ROOT from environment or
    #  vars file
    #
    $DOCUMENT_ROOT=$ENV{'DOCUMENT_ROOT'} 
        || $DOCUMENT_ROOT || $test_fn;

}


#  Return handler code ref
#
&handler_build(\&handler);


#==================================================================================================


#  Build a Plack::Build ref if there is middleware requested
#
sub handler_static {


    #  Used when starting webdyne.psgi from command line without plackup or via starman - presumably for dev
    #  purposes so include the Plack static middleware to allow serving non-psp files such as css
    #
    my $handler_cr=shift();
    if (my $qr=$WEBDYNE_PLACK_MIDDLEWARE_STATIC) {
        my $root_dn;
        if (-f $DOCUMENT_ROOT) {
            #  DOCUMENT_ROOT is actually a file. Get the directory name
            #
            require File::Basename;
            $root_dn=&File::Basename::dirname($DOCUMENT_ROOT)
        }
        else {
            #  DOCUMENT_ROOT is a dirname, keep but check
            $root_dn=$DOCUMENT_ROOT;
            (-d $root_dn) || return err("$root_dn is not a directory, aborting");
        }
        require Plack::Middleware::Static;
        $handler_cr=Plack::Middleware::Static->wrap($handler_cr, path=>$qr, root=>$root_dn );
    }
    return $handler_cr;

}


sub handler_build {
    
    
    #  Check for any additional Plack middleware handlers requested in config and wrap them if needed
    #
    my $handler_cr=shift();
    if (my $middleware_ar=$WEBDYNE_PLACK_MIDDLEWARE_AR) {
        #  Yes, middleware requested
        #
        foreach my $middleware_hr (@{$middleware_ar}) {
            while (my ($middleware, $opt_hr)=each %{$middleware_hr}) {
                if ($middleware !~ /^Plack::Middleware/) {
                    $middleware = "Plack::Middleware::${middleware}";
                }
                (my $middleware_fn = $middleware) =~ s|::|/|g;
                require "${middleware_fn}.pm";
                if (ref($opt_hr) eq 'CODE') {
                    #  If opt_hr is code ref means we want DOCUMENT_ROOT built in
                    $opt_hr=$opt_hr->($DOCUMENT_ROOT);
                }
                $handler_cr=$middleware->wrap($handler_cr, %{$opt_hr});
            }
        }
    }
    return $handler_cr;
    
}
    

#  Actual Plack handler
#
sub handler {


    #  Get env
    #
    my $env_hr=shift();
    local *ENV=$env_hr;
    #$ENV{'DOCUMENT_ROOT'} ||= $DOCUMENT_ROOT;
    debug('in handler, env: %s', Dumper(\%ENV));


    #  Cache handler for a location
    #
    my ($handler, %handler);


    #  Create new PSGI Request object, will pull filename from
    #  environment. 
    #
    my $html;
    my $html_fh=IO::String->new($html);
    my $r=WebDyne::Request::PSGI->new(select => $html_fh, document_root => $DOCUMENT_ROOT) ||
        return err('unable to create new WebDyne::Request::PSGI object: %s', 
			$@ || errclr() || 'unknown error');
    debug("r: $r");


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
    debug("calling handler: $handler");
    

    #  Call handler and evaluate results
    #
    my $status=eval {$handler->handler($r)} if $handler;
    debug("handler returned status: $status");


	#  Can close html file handle now
	#
    $html_fh->close();
    debug("html returned: $html");


	#  Present error if no status returned
	#
    if (!defined($status)) {
        debug('undefined status returned, looking for error handler');
        if (($status=$r->status) ne RC_INTERNAL_SERVER_ERROR) {
            my $error=errdump() || $@; errclr();
            debug("request handler status:$status, detected error: $error, calling err_html");
            $r->status(RC_INTERNAL_SERVER_ERROR),
            $html=$r->err_html($status, $error)
        }
        else {
            debug('status fall through !')
        }
    }
    elsif (($status < 0) && !(-f (my $fn=$r->filename()))) {
        debug("status: $status, fn:$fn, setting RC_NOT_FOUND");
        $r->status(RC_NOT_FOUND);
		my $error=errdump() || "File '$fn' not found, status ($status)"; errclr();
		$html=$r->err_html($status, $error)
        #warn("file $fn not found") if $WEBDYNE_FASTCGI_WARN_ON_ERROR;
    }
    elsif ($status < 0) {
        debug("status: $status, setting RC_INTERNAL_SERVER_ERROR");
        $r->status($status=RC_INTERNAL_SERVER_ERROR),
        $html=$r->err_html($status, "Unexpected return status ($status) from handler $handler")
	}
	elsif (($status eq RC_INTERNAL_SERVER_ERROR) && !$html) {
	    $html=$r->custom_response($status) ||
	        "Error $status with no content - try server error logs ?";
    }
    debug("final handler status is $status, html:$html");


	#  If html defined set header content type unless already set during handler run
	#
	$r->content_type($WEBDYNE_CONTENT_TYPE_HTML) 
	    if ($html && !$r->content_type());

	
	#  Return structure
	#
	my @return=(
        $r->status() || RC_INTERNAL_SERVER_ERROR,
        [
			%{$r->headers_out()}
		],
        [
			$html 
		]
	);


	#  Finished with response handler now
	#
	$r->DESTROY();


	#  And return
	#
	debug('return %s', Dumper(\@return));
	return \@return;


}


sub error {

	#  Get and return error string as last resort. Test function not used 
	#  in main handler.
	#
	my $error=sprintf(shift(), @_) ||
		'Unknown error';

	#  Basic error response
	#
    return [
        RC_INTERNAL_SERVER_ERROR,
        ['Content-Type' => 'text/plain'],
        [join($/,
			'Internal Server Error:',
			undef, 
			$error
		)]
    ];

}

__END__

# Documentation in Markdown. Convert to POD using markpod from 
#
# https://github.com/aspeer/pl-markpod.git 

=begin markdown

# NAME

WebDyne - PSGI application for handling web requests

# SYNOPSIS

`webdyne.psgi [--option] <document_root>`

`webdyne.psgi --port 8080 /var/www/html` 

# DESCRIPTION

`webdyne.psgi` is a PSGI application script that handles web requests using the WebDyne framework. It initializes the environment, creates a new PSGI request object, determines the appropriate handler, and processes the request to generate a response.

# OPTIONS

Command line options are handled by the Plack::Runner module and are the same as described in the [plackup(1)](man:plackup(1)) man page. Refer to that page for full options but some common options are:

**--host** Which host interface to bind to

**--port** Which port to bind to

**--server** Which server to use, e.g. Starman

**--reload** Reload if libraries or other files change

**-I** Same as perl -I for library include paths

**-M** Same as perl -M for loading modules before the script starts


# EXAMPLES

To run the script, use the following command for basic functionality and serving files from the /var/www/html directory. If no specific .psp requested the file 'index.psp' will attempt to be loaded (this can be changed - see below)

`webdyne.psgi /var/www/html`

Specify an alternative default document to serve if none specified

`DOCUMENT_DEFAULT=time.psp webdyne.psgi /var/www/html`

Run a single page app. Only this page will be allowed

`webdyne.psgi /var/www/html/time.psp`

Start with the Starman server

`DOCUMENT_DEFAULT=time.psp webdyne.psgi --no-default-middleware  --server Starman /home/aspeer/public_html`

# ENVIRONMENT VARIABLES

This script is a frontend to the WebDyne::Request::PSGI module. All environment variables and configuration files from that module are applicable when running this script.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

=end markdown


=head1 NAME

WebDyne - PSGI application for handling web requests


=head1 SYNOPSIS

C<<< webdyne.psgi [--option] <document_root> >>>

C<webdyne.psgi --port 8080 /var/www/html> 


=head1 DESCRIPTION

C<webdyne.psgi> is a PSGI application script that handles web requests using the WebDyne framework. It initializes the environment, creates a new PSGI request object, determines the appropriate handler, and processes the request to generate a response.


=head1 OPTIONS

Command line options are handled by the Plack::Runner module and are the same as described in the L<plackup(1)|man:plackup(1)> man page. Refer to that page for full options but some common options are:

B<--host> Which host interface to bind to

B<--port> Which port to bind to

B<--server> Which server to use, e.g. Starman

B<--reload> Reload if libraries or other files change

B<-I> Same as perl -I for library include paths

B<-M> Same as perl -M for loading modules before the script starts


=head1 EXAMPLES

To run the script, use the following command for basic functionality and serving files from the /var/www/html directory. If no specific .psp requested the file 'index.psp' will attempt to be loaded (this can be changed - see below)

C<webdyne.psgi /var/www/html>

Specify an alternative default document to serve if none specified

C<DOCUMENT_DEFAULT=time.psp webdyne.psgi /var/www/html>

Run a single page app. Only this page will be allowed

C<webdyne.psgi /var/www/html/time.psp>

Start with the Starman server

C<DOCUMENT_DEFAULT=time.psp webdyne.psgi --no-default-middleware  --server Starman /home/aspeer/public_html>


=head1 ENVIRONMENT VARIABLES

This script is a frontend to the WebDyne::Request::PSGI module. All environment variables and configuration files from that module are applicable when running this script.


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2025 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
