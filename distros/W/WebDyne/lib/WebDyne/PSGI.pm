#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package WebDyne::PSGI;


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
use Cwd qw(fastcwd);
use File::Basename;
use File::Spec;


#  PSGI modules
#
use Plack::Request;
use Plack::Response;


#  WebDyne Modules
#
use WebDyne;
use WebDyne::Constant;
use WebDyne::Util;
use WebDyne::PSGI::Constant;
use WebDyne::Request::PSGI;


#  Environment
#
my %ENV_BASE=(
    %{$WEBDYNE_PSGI_ENV_SET}, 
    (map { $_=>$ENV{$_}  } (
        grep { defined($ENV{$_}) }
        qw(DOCUMENT_DEFAULT DOCUMENT_ROOT SERVER_NAME APPL_MD_PATH),
        @{$WEBDYNE_PSGI_ENV_KEEP},
        (grep {/^WEBDYNE/i} keys %ENV), # Note not WEBDYNE_, just /WEBDYNE/i to allow for DirConfig type entries such as WebDyneHandler
        (grep {/^HTTP_/i} keys %ENV),
        (grep {/^CONTENT_/i} keys %ENV)
    ))
);


#  Version information
#
$VERSION='3.015';


#==================================================================================================

sub new {


    #  Get options
    #
    my ($class, %opt)=@_;
    
    
    #  Test ?
    #
    if ($opt{'test'}) {
        $opt{'root'}=$WEBDYNE_DEFAULT_TEST_FN;
    }
    
    
    #  Indexing. 1 for enable with internal, string for some other indexing file
    #
    if ($opt{'index'} eq '1') {
        $opt{'index'}=$WEBDYNE_DEFAULT_INDEX_FN;
    }
    

    #  Fix document root
    #
    $opt{'root'}=File::Spec->rel2abs($opt{'root'});


    #  API file name cache
    #
    $opt{'API_fn'}={};
    

    #  Done
    #
    return bless(\%opt, $class);
    
}


sub to_app {


    #  Self ref
    #
    my $self=shift();


    #  Dispatch code ref
    #
    my $app_cr=sub { $self->handler(@_) };
    

    #  Done
    #
    return $app_cr;
    
}


#  Actual Plack handler
#
sub handler {


    #  Get env
    #
    my ($self, $env_hr, @param)=@_;
    debug('in handler, self: %s, env: %s, param:%s', Dumper($self, $env_hr, \@param));
    
    
    #  Set up
    #
    local %ENV=(%ENV_BASE, %{$env_hr});
    my @env_key=keys %ENV;


    #  Setup request and response handlers
    #
    my $req_or=Plack::Request->new($env_hr);
    my $res_or=Plack::Response->new(HTTP_OK);
    
    
    #  Create new PSGI Request object, will pull filename from
    #  environment. 
    #
    my $html;
    my $html_fh=IO::String->new($html);
    my $r=WebDyne::Request::PSGI->new(select => $html_fh, document_root => $self->{'root'}, document_default => $self->{'index'}, env=>$env_hr, req=>$req_or, res=>$res_or, no_head_insert=>$self->{'no_head_insert'}, filename=>$self->{'filename'}, @param) ||
        return err('unable to create new WebDyne::Request::PSGI object: %s', 
    			$@ || errclr() || 'unknown error');
    debug("r: $r");
    
    
    #  Get handler
    #
    my $handler=$self->{'handler'} ||= 'WebDyne';


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
	    debug('status: %s is not HTTP_OK, branching', $status);
 	    if (!defined($status) || ($status < 0) ||  is_error($status) || !$html) {
	
	    
            #  Something went wrong. Let's start working through it
            #
            if (($status eq HTTP_NOT_FOUND) && !(-f (my $fn=$r->filename()))) {

            
                #  We couldn't find file but this might be an API request. Go back through
                #  file paths looking for a file that matches the apu request, e.g. if URI
                #  is /api/user/42 go back looking for /api/user.psp or /api.psp in the treet
                #
                debug("status: $status, fn: $fn");
                if (my $api_fn=$self->api_filename($r)) {
                    debug("status: $status, fn:$fn (%s), found API match, dispatching", $r->filename());
                    #return &handler($env_hr, filename=>$api_fn);
                    return $self->handler($env_hr, filename=>$api_fn);
                }
                
                
                #  If get here nothing found, send 404 error
                #
                debug("status: $status, fn:$fn, setting HTTP_NOT_FOUND");
                $r->status(HTTP_NOT_FOUND);
                my $error=errstr() || "File not found, status ($status)"; 
                my $errdump=errdump();
                errclr();
                #$html=$r->err_html($status, $error)
                return psgi_error($r, $status, $error, $errdump );
            }
            elsif (is_error($status)) {
            
                #  Some other error besides 404
                #
                debug("returning custom error: $status");
                $r->status($status);
                $html=$r->custom_response($status);
                unless ($html=~/^<!DOCTYPE html>/) {
                    #  Not a HTML error, revert to text
                    my $error=$html || errstr() || $@ || 
                        "Error $status with no content - try server error logs ?";
                    my $errdump=errdump();
                    errclr();
                    return psgi_error($r, $status, $error, $errdump);
                }
                else {
                    #  HTML error, keep going - will be displayed as-s
                }
            }
            else {
            
                #  Weird non HTTP status code, something has gone wrong along way
                #
                debug('undefined status returned, looking for error handler');
                my $error=errstr() || $@; 
                my $errdump=errdump();
                errclr();
                $error ||=  "Unexpected return status ($status) from handler $handler";
                debug("request handler status:$status, detected error: $error, calling err_html");
                $r->status(HTTP_INTERNAL_SERVER_ERROR);
                #$html=$r->err_html($status, $error)
                return psgi_error($r, $status, $error, $errdump);

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
        [ %{$r->headers_out()} ],
        [ $html ]
    );


    #  Finished with response handler now
    #
    $r->DESTROY();
    
    
    #  Env changed ?
    #
    if (keys %ENV != @env_key) {
        debug('ENV keys changed, checking');
        my %env=%ENV;
        delete @env{@env_key};
        debug('keys to add into ENV_BASE: %s', Dumper(\%env));
        map {$ENV_BASE{$_}=$ENV{$_}} keys %env;
    }


    #  And return
    #
    debug('return %s', Dumper(\@return));
    return \@return;


}


sub api_filename {

    my ($self, $r)=@_;
    return unless WEBDYNE_API_ENABLE;

    my $document_root=$r->document_root;
    my $api_dn=$ENV{'PATH_INFO'} || '';
    $api_dn=~s/^${document_root}//;
    my @api_dn=grep {$_} File::Spec::Unix->splitdir($api_dn);
    my @api_fn;
    my $API_fn=$self->{'API_fn'};
    while (my $dn=shift @api_dn) {
        push @api_fn, $dn;
        my $api_fn=File::Spec->catfile($document_root, @api_fn) . WEBDYNE_PSP_EXT;
        debug("check $api_fn");
        #  Check of outside docroot
        last if (index($api_fn, $document_root) !=0);
        if ($API_fn->{$api_fn} || (-f $api_fn)) {
            debug("found api file name: $api_fn, %s, dispatching", Dumper($API_fn));
            $API_fn->{$api_fn}++; # Cache so not stat()ing on file system
            return $api_fn;
        }
    }

    return;
}


sub psgi_error {

    #  Return HTML or text error
    #
    my ($r, $status, $error, $errdump)=@_;
    debug("in PSGI error handler, r: $r, status: $status, error: $error");
    unless (is_error($status)) {
        $status=HTTP_INTERNAL_SERVER_ERROR;
    }
    my ($content_type, $body);
    if ($WEBDYNE_ERROR_TEXT) {
        $content_type=$WEBDYNE_CONTENT_TYPE_TEXT;
        $body=$errdump || $error;
    }
    else {
        if (eval {$body=$r->err_html($status, $error)}) {
            $content_type=$WEBDYNE_CONTENT_TYPE_HTML;
        }
        else {
            $body=$errdump || $error;
            $content_type=$WEBDYNE_CONTENT_TYPE_TEXT;
        }
    }
    my @return=(
        $status,
        ['Content-Type' => $content_type],
        [$body]
    );
    $r->DESTROY();
    debug('return: %s', Dumper(\@return));
    return \@return;
    
}
         


__END__

=begin markdown

# WebDyne::PSGI #

# NAME #

WebDyne::PSGI - PSGI application wrapper for WebDyne

# SYNOPSIS #

```perl
use WebDyne::PSGI;

my $app = WebDyne::PSGI->new(
    root  => '.',
    index => 1,
)->to_app;

my $single_file_app = WebDyne::PSGI->new(
    root     => '.',
    filename => 'app.psp',
)->to_app;
```

# DESCRIPTION #

`WebDyne::PSGI` wraps the core WebDyne handler in a PSGI application. It translates PSGI environment data into a `WebDyne::Request::PSGI` object, dispatches to the main WebDyne handler, and converts the result back into a PSGI response.

The module also contains special handling for API-style fallback resolution when a `.psp` file is not found directly from the incoming path.

# METHODS #

* **new(%options)**

    Construct a PSGI application wrapper. Options include `root`, `index`, `test`, `filename`, and related runtime settings.

    The `filename` option is an explicit source-file override for the application. When supplied, it is passed to `WebDyne::Request::PSGI` for every request and always wins over normal filename derivation from the PSGI environment, including `PATH_INFO`, `SCRIPT_FILENAME`, `DOCUMENT_ROOT`, and default document handling. This is useful for helper tools or deliberate single-file PSGI applications; do not set it for normal multi-page applications that should dispatch from the request path.

* **to_app()**

    Return the PSGI application code reference.

* **handler($env, @param)**

    Main PSGI entry point. Builds request and response objects, dispatches to WebDyne, and returns the PSGI response.

* **psgi_error(...)**

    Helper for PSGI-side error handling and conversion.

# NOTES #

The module relies on `WebDyne::Request::PSGI` for normalized request handling and on `WebDyne::PSGI::Constant` for middleware and environment defaults.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 WebDyne::PSGI


=head1 NAME

WebDyne::PSGI - PSGI application wrapper for WebDyne


=head1 SYNOPSIS


 use WebDyne::PSGI;
 
 my $app = WebDyne::PSGI->new(
     root  => '.',
     index => 1,
 )->to_app;
 
 my $single_file_app = WebDyne::PSGI->new(
     root     => '.',
     filename => 'app.psp',
 )->to_app;

=head1 DESCRIPTION

C<WebDyne::PSGI> wraps the core WebDyne handler in a PSGI application. It translates PSGI environment data into a C<WebDyne::Request::PSGI> object, dispatches to the main WebDyne handler, and converts the result back into a PSGI response.

The module also contains special handling for API-style fallback resolution when a C<.psp> file is not found directly from the incoming path.


=head1 METHODS

=over

=item *

B<new(%options)>

Construct a PSGI application wrapper. Options include C<root>, C<index>, C<test>, C<filename>, and related runtime settings.

The C<filename> option is an explicit source-file override for the application. When supplied, it is passed to C<WebDyne::Request::PSGI> for every request and always wins over normal filename derivation from the PSGI environment, including C<PATH_INFO>, C<SCRIPT_FILENAME>, C<DOCUMENT_ROOT>, and default document handling. This is useful for helper tools or deliberate single-file PSGI applications; do not set it for normal multi-page applications that should dispatch from the request path.



=item *

B<to_app()>

Return the PSGI application code reference.



=item *

B<handler($env, @param)>

Main PSGI entry point. Builds request and response objects, dispatches to WebDyne, and returns the PSGI response.



=item *

B<psgi_error(...)>

Helper for PSGI-side error handling and conversion.



=back


=head1 NOTES

The module relies on C<WebDyne::Request::PSGI> for normalized request handling and on C<WebDyne::PSGI::Constant> for middleware and environment defaults.


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
