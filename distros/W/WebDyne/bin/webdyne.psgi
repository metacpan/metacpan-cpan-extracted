#!/usr/bin/env perl
#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
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
use warnings;
no warnings qw(uninitialized);


#  External Modules
#
use HTTP::Status qw(:constants is_success is_error);
use IO::String;
use Data::Dumper;
use Cwd qw(cwd);


#  WebDyne Modules
#
use WebDyne;
use WebDyne::Constant;
use WebDyne::Util;
use WebDyne::Request::PSGI;
use WebDyne::Request::PSGI::Constant;


#  Version information
#
$VERSION='2.046';


#  API file name cache
#
our (%API_fn);


#  Test file to use if no DOCUMENT_ROOT found
#
(my $test_dn=$INC{'WebDyne.pm'})=~s/\.pm$//;
my $test_fn=File::Spec->catfile($test_dn, 'time.psp');


#  Set DOCUMENT_DEFAULT
#
$DOCUMENT_DEFAULT=$ENV{'DOCUMENT_DEFAULT'} || $DOCUMENT_DEFAULT;


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
    
    
    #  Used to do --static as option, now default, change to negate option, i.e. always
    #  serve static files for convenience when started from the command line, same with noindex
    #
    my $nostatic_fg;
    if ($nostatic_fg=grep {/^--nostatic$/} @ARGV) {
        @ARGV=grep {!/^--nostatic/} @ARGV;
    }
    my $noindex_fg;
    if ($noindex_fg=grep {/^--noindex$/} @ARGV) {
        @ARGV=grep {!/^--noindex/} @ARGV;
    }


    #  Mac conflicts with Plack default port of 5000 - choose 5001
    #
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
    #if ($test_fg || !$DOCUMENT_ROOT) {
    #    $DOCUMENT_ROOT=$test_fn;
    #}
    if ($test_fg) {
        $DOCUMENT_ROOT=$test_fn;
    }
    elsif(! $DOCUMENT_ROOT) {
        $DOCUMENT_ROOT=cwd();
    }
    $DOCUMENT_ROOT=&normalize_dn($DOCUMENT_ROOT);
    
    
    #  Indexing ? Do by default unless file specified as DOCUMENT_ROOT or --noindex spec'd etc.
    #
    unless (-f $DOCUMENT_ROOT || -f File::Spec->catfile($DOCUMENT_ROOT, $DOCUMENT_DEFAULT) || $noindex_fg) {

        #  Final check. Only do if directory
        #
        if (-d $DOCUMENT_ROOT) {
    
            #  We can do indexing
            #
            $DOCUMENT_DEFAULT=File::Spec->rel2abs(File::Spec->catfile($test_dn, $WEBDYNE_PSGI_INDEX));
            
        }
        
    }
    
    
    #  Read in local webdyne.conf.pl
    #
    &local_constant_load($DOCUMENT_ROOT);
    
    
    #  Show error information by default
    #
    $WebDyne::WEBDYNE_ERROR_SHOW=1;
    $WebDyne::WEBDYNE_ERROR_SHOW_EXTENDED=1;


    #  Done - run it
    #
    $plack_or->run(&handler_build($nostatic_fg ? \&handler : &handler_static(\&handler)));
    exit 0;

}
else {

    #  Not running from comamnd line. Get DOCUMENT_ROOT from environment or
    #  vars file
    #
    $DOCUMENT_ROOT=$ENV{'DOCUMENT_ROOT'} 
        || $DOCUMENT_ROOT || $test_fn;
    $DOCUMENT_ROOT=&normalize_dn($DOCUMENT_ROOT);


    #  Read in local webdyne.conf.pl
    #
    &local_constant_load($DOCUMENT_ROOT);

}


#  Return handler code ref
#
&handler_build($WEBDYNE_PSGI_STATIC ? &handler_static(\&handler) : \&handler);


#==================================================================================================

sub normalize_dn {

    #  Normal dir, normally document_root
    #
    my $rel_dn=shift();
    my $abs_dn=File::Spec->rel2abs($rel_dn);
    $abs_dn =~ s{/$}{} unless $abs_dn eq '/';
    return $abs_dn;
    
}


sub local_constant_load {


    #  Read in local webdyne.conf.pl
    #
    my $root_dn=shift();
    
    
    #  If root_dn is a file get dir name
    if (-f $root_dn) {
        $root_dn=(File::Spec->splitpath($root_dn))[1];
    }
    WebDyne::Constant->import(File::Spec->catfile($root_dn, sprintf('.%s', $WEBDYNE_CONF_FN)));

}
    

#  Build a Plack::Build ref if there is middleware requested
#
sub handler_static {


    #  Used when starting webdyne.psgi from command line without plackup or via starman - presumably for dev
    #  purposes so include the Plack static middleware to allow serving non-psp files such as css
    #
    my ($handler_cr, @param)=@_;
    if (my $qr=$WEBDYNE_PSGI_MIDDLEWARE_STATIC) {
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
    my ($handler_cr, @param)=@_;
    if (my $middleware_ar=$WEBDYNE_PSGI_MIDDLEWARE) {
        #  Yes, middleware requested
        #
        foreach my $middleware_hr (@{$middleware_ar}) {
            while (my ($middleware, $opt_hr)=each %{$middleware_hr}) {
                if ($middleware !~ /^Plack::Middleware/) {
                    $middleware = "Plack::Middleware::${middleware}";
                }
                (my $middleware_pm = $middleware) =~ s{::}{/}g;
                $middleware_pm.='.pm';
                eval { require $middleware_pm } ||
                    return err("error loading Plack middleware: $middleware ($middleware_pm), $@");
                if (ref($opt_hr) eq 'CODE') {
                    #  If opt_hr is code ref means we want DOCUMENT_ROOT built in
                    $opt_hr=$opt_hr->($DOCUMENT_ROOT);
                }
                $handler_cr=$middleware->wrap($handler_cr, %{$opt_hr});
            }
        }
    }
    #if ($WEBDYNE_PSGI_ENV_KEEP || $WEBDYNE_PSGI_ENV_SET) {
    #    require Plack::Middleware::ForceEnv;
    #    $handler_cr=Plack::Middleware::ForceEnv->wrap($handler_cr, 
    #        %{$WEBDYNE_PSGI_ENV_SET},
    #        map {$_=>$ENV{$_}} @{$WEBDYNE_PSGI_ENV_KEEP}
    #    )
    #}
    return $handler_cr;
    
}
    

#  Actual Plack handler
#
sub handler {


    #  Get env
    #
    my ($env_hr, @param)=@_;
    local *ENV=$env_hr;
    debug('in handler, env: %s, param:%s', Dumper(\%ENV, \@param));
    
    
    #  Set any env vars we want
    #
    @ENV{qw(DOCUMENT_ROOT DOCUMENT_DEFAULT)}=($DOCUMENT_ROOT, $DOCUMENT_DEFAULT);
    if (WEBDYNE_PSGI_ENV_SET) {
        map { $ENV{$_}=$WEBDYNE_PSGI_ENV_SET->{$_} } keys %{$WEBDYNE_PSGI_ENV_SET}
    }


    #  Cache handler for a location
    #
    #my ($handler, %handler);


    #  Create new PSGI Request object, will pull filename from
    #  environment. 
    #
    my $html;
    my $html_fh=IO::String->new($html);
    my $r=WebDyne::Request::PSGI->new(select => $html_fh, document_root => $DOCUMENT_ROOT, document_default => $DOCUMENT_DEFAULT, uri=>$ENV{'PATH_INFO'}, env=>$env_hr, @param) ||
        return err('unable to create new WebDyne::Request::PSGI object: %s', 
    			$@ || errclr() || 'unknown error');
    debug("r: $r");


    #  Get handler. Update - Commented out. Let WebDyne handle this as borks if
    #  using WebDyne::Template and index.psp gets called. Keep code for reference
    #
    my $handler='WebDyne';
    if (0) {
        my %handler;
        unless ($handler=$handler{my $location=$r->location()}) {
            my $handler_package=
                $r->dir_config('WebDyneHandler') || $ENV{'WebDyneHandler'};
            if ($handler_package) {
                local $SIG{'__DIE__'};
                (my $handler_package_pm=$handler_package)=~s{::}{/}g;
                $handler_package_pm.='.pm';
                unless (eval {require $handler_package_pm}) {
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
    }
    debug("calling handler: $handler");


    #  Call handler and evaluate results
    #
    my $status=eval {$handler->handler($r)};
    debug("handler returned status: $status");


	#  Can close html file handle now
	#
    $html_fh->close();
    debug("html returned: $html");


	#  Present error if non 200 (success) status returned. Yes - there are other status codes but this is most
	#  common and quickest test, other 200 codes will fall through the if/else statements and still work
	#
	unless ($status == HTTP_OK) {
	    
	    
	    #  OK. Most common match didn't happen. Is it an error ?
	    #
	    if (!defined($status) || ($status < 0) ||  is_error($status)) {
	
	    
            #  Something went wrong. Let's start working through it
            #
            if (($status eq HTTP_NOT_FOUND) && !(-f (my $fn=$r->filename()))) {

            
                #  We couldn't find file but this might be an API request. Go back through
                #  file paths looking for a file that matches the apu request, e.g. if URI
                #  is /api/user/42 go back looking for /api/user.psp or /api.psp in the treet
                #
                debug("status: $status, fn: $fn");
                my $document_root=$r->document_root;
                if ($WEBDYNE_API_ENABLE) {
                    debug("status: $status, fn:$fn (%s), looking for API match", $r->filename());
                    #(my $api_dn=$fn)=~s/^${document_root}//;
                    (my $api_dn=$ENV{'PATH_INFO'})=~s/^${document_root}//;
                    my @api_dn=grep {$_} File::Spec::Unix->splitdir($api_dn);
                    my @api_fn;
                    while (my $dn=shift @api_dn) {
                        push @api_fn, $dn;
                        my $api_fn=File::Spec->catfile($document_root, @api_fn) . WEBDYNE_PSP_EXT;
                        debug("check $api_fn");
                        #  Check of outside docroot
                        last if (index($api_fn, $document_root) !=0);
                        if ($API_fn{$api_fn} || (-f $api_fn)) {
                            debug("found api file name: $api_fn, %s, dispatching", Dumper(\%API_fn));
                            $API_fn{$api_fn}++; # Cache so not stat()ing on file system
                            return &handler($env_hr, filename=>$api_fn);
                        }
                    }
                }
                
                
                #  If get here nothing found, send 404 error
                #
                debug("status: $status, fn:$fn, setting HTTP_NOT_FOUND");
                $r->status(HTTP_NOT_FOUND);
                my $error=errdump() || "File not found, status ($status)"; errclr();
                $html=$r->err_html($status, $error)
            }
            elsif (is_error($status)) {
            
                #  Some other error besides 404
                #
                debug("returning custom error: $status");
                $html=$r->custom_response($status) ||
                    "Error $status with no content - try server error logs ?";
            }
            else {
            
                #  Weird non HTTP status code, something has gone wrong along way
                #
                debug('undefined status returned, looking for error handler');
                my $error=errdump() || $@; errclr();
                $error ||=  "Unexpected return status ($status) from handler $handler";
                debug("request handler status:$status, detected error: $error, calling err_html");
                $r->status(HTTP_INTERNAL_SERVER_ERROR);
                $html=$r->err_html($status, $error)

            }
                
        }
        else {
        
        
            #  Not an error, but not HTTP_OK
            #
            debug("status: $status is not an error, proceeding");
            
        }

    }
    debug("final handler status: %s, content_type: %s, html:%s", $status, $r->content_type(), $html);


	#  If html defined set header content type unless already set during handler run
	#
	$r->content_type($WEBDYNE_CONTENT_TYPE_HTML) 
	    if ($html && !$r->content_type());

	
	#  Return structure
	#
	my @return=(
        $r->status() || HTTP_INTERNAL_SERVER_ERROR,
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
	my @error=@_;
	my $error=sprintf(shift(), @error) ||
		'Unknown error';

	#  Basic error response
	#
    return [
        HTTP_INTERNAL_SERVER_ERROR,
        ['Content-Type' => 'text/plain'],
        [join($/,
			'Internal Server Error:',
			undef, 
			$error
		)]
    ];

}

#  DO NOT END WITH 1; Here - will break Apache PSGI 
#
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

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

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

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
