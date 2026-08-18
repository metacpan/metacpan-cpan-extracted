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
package WebDyne::PAGI;


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
use Future::AsyncAwait;
use Sub::Util qw(set_subname);
use File::Basename;
use File::Spec;


#  PAGI modules
#
use PAGI::Request;
use PAGI::Response;
use PAGI::SSE;
use PAGI::WebSocket;


#  WebDyne Modules
#
use WebDyne;
use WebDyne::Constant;
use WebDyne::Util;
use WebDyne::PAGI::Constant;
use WebDyne::Request::PAGI;


#  Environment
#
my %ENV_BASE=(
    %{$WEBDYNE_PAGI_ENV_SET}, 
    (map { $_=>$ENV{$_}  } (
        grep { defined($ENV{$_}) }
        qw(DOCUMENT_DEFAULT DOCUMENT_ROOT),
        @{$WEBDYNE_PAGI_ENV_KEEP},
        grep {/WEBDYNE/i} keys %ENV
    ))
);


#  Version information
#
$VERSION='3.018';


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


    #  Dispatch table
    #
    my %handler=(
        http        => sub { shift()->handler_http(@_) },
        sse         => sub { shift()->handler_sse(@_) },
        ws          => sub { shift()->handler_ws(@_) },
        websocket   => sub { shift()->handler_ws(@_) },
        lifespan    => sub { shift()->handler_lifespan(@_) }
    );
        

    # Main application
    #
    my $app_cr = async sub {

        my ($scope, $receive, $send) = @_;
        if (my $handler_cr=$handler{my $type=$scope->{type}}) {
            #  Supported type, dispatch
            #
            return await $handler_cr->($self, $scope, $receive, $send)->($scope, $receive, $send);
        }
        else {
            #  Unsupported type
            #
            die "Unsupported scope type: $type";
        }

    };
    
    
    #  Done
    #
    return $app_cr;
    
}


sub handler_sse {


    #  Get request
    #
    my ($self, $scope, $receive, $send)=@_;
    debug('in handler_sse, scope:%s receive:%s, send:%s', Dumper($scope, $receive, $send));


    #  Setup %ENV
    #
    local *ENV=\%ENV_BASE;


    #  Create helper objects
    #
    my $req_or=PAGI::Request->new($scope, $receive) ||
        return err('unable to get PAGI::Request object');
    my $res_or=PAGI::Response->new($scope) ||
        return err('unable to get PAGI::Response object');
    my $sse_or=PAGI::SSE->new($scope, $receive, $send) ||
        return err('unable to get PAGI::SSE object');
    debug("req_or: $req_or, res_or: $res_or, sse_or: $sse_or");


    #  Get main WebDyne handler request object
    #
    my $r=WebDyne::Request::PAGI->new( document_root => $self->{'root'}, document_default => $self->{'index'}, scope=>$scope, req=>$req_or, res=>$res_or, sse=>$sse_or,
        receive => $receive, send=> $send) ||
            return err('unable to create new WebDyne::Request::PAGI object: %s', 
                $@ || errclr() || 'unknown error');
    debug("r: $r");
    
    
    #  Call handler. No point error checking but log errors
    #
    debug('calling WebDyne handler');
    my $status=WebDyne->handler($r);
    debug("status: $status");
    if ($status eq HTTP_CONTINUE) {
        my $sse_cr=$r->custom_response($status);
        return $sse_cr;
    }
    else {
        return err();
    }

}


sub handler_sse_error {

    return async sub {
    

        #  Get request
        #
        my ($scope, $receive, $send)=@_;
        debug('in handler_sse_error, scope:%s receive:%s, send:%s', Dumper($scope, $receive, $send));


        #  Create helper objects
        #
        my $sse_or=PAGI::SSE->new($scope, $receive, $send) ||
            return err('unable to get PAGI::SSE object');
        debug("sse_or: $sse_or");
        
        
        #  Send error
        #
        await $sse_or->send('SSE error - see logs');
        
    }
    
}


sub handler_ws {


    #  Get request
    #
    my ($self, $scope, $receive, $send)=@_;
    debug('in handler_ws, scope:%s receive:%s, send:%s', Dumper($scope, $receive, $send));


    #  Setup %ENV
    #
    local *ENV=\%ENV_BASE;


    #  Create helper objects
    #
    my $req_or=PAGI::Request->new($scope, $receive) ||
        return err('unable to get PAGI::Request object');
    my $res_or=PAGI::Response->new($scope) ||
        return err('unable to get PAGI::Response object');
    my $ws_or=PAGI::WebSocket->new($scope, $receive, $send) ||
        return err('unable to get PAGI::WebSocket object');
    debug("req_or: $req_or, res_or: $res_or, ws_or: $ws_or");


    #  Get main WebDyne handler request object
    #
    my $r=WebDyne::Request::PAGI->new( document_root => $self->{'root'}, document_default => $self->{'index'}, scope=>$scope, req=>$req_or, res=>$res_or, ws=>$ws_or,
        receive => $receive, send=> $send) ||
            return err('unable to create new WebDyne::Request::PAGI object: %s', 
                $@ || errclr() || 'unknown error');
    debug("r: $r");
    
    
    #  Call handler. No point error checking but log errors
    #
    debug('calling WebDyne handler');
    my $status=WebDyne->handler($r);
    debug("status: $status");
    if ($status eq HTTP_CONTINUE) {
        my $ws_cr=$r->custom_response($status);
        return $ws_cr;
    }
    else {
        return err();
    }

}

sub handler_http {

    
    #  Self ref contains things like document_root, dcoument_default
    #
    my $self=shift();


    #  Return async sub for handling WebDyne requests
    #
    return set_subname('handler_http_anon', async sub {


        #  Get request
        #
        my ($scope, $receive, $send)=@_;
        debug('in handler, scope:%s receive:%s, send:%s', Dumper($scope, $receive, $send));
        

        #  Restrict local env and expose the PAGI request path to WebDyne's
        #  shared Router::Simple based API implementation.
        #
        my ($r, $html, $html_fh, $status);
        {
            #  Keep the request environment localized only while WebDyne is
            #  constructing and executing the request. Do not retain a
            #  localized global %ENV across an asynchronous response await.
            #
            local *ENV=\%ENV_BASE;
            @ENV{qw(PATH_INFO QUERY_STRING REQUEST_METHOD)}=(
                $scope->{'path'} || '',
                $scope->{'query_string'} || '',
                $scope->{'method'} || '',
            );

            #  If the requested path is not a file, an API PSP may own a path
            #  prefix such as /api.psp or /example/api.psp. Resolve that prefix
            #  before constructing the request so the normal WebDyne handler can
            #  process the PSP and retain the original PATH_INFO for routing.
            #
            my $api_fn=api_filename($self, $scope);

            #  Only need request and response helper objects
            #
            my $req_or=PAGI::Request->new($scope, $receive) ||
                return err('unable to get PAGI::Request object');
            my $res_or=PAGI::Response->new($scope) ||
                return err('unable to get PAGI::Response object');

            #  Create new WebDyne Request object, optionally using the API
            #  prefix resolved above as its PSP filename.
            #
            $html_fh=IO::String->new($html);
            my %request_opt=(select => $html_fh, document_root => $self->{'root'}, document_default => $self->{'index'}, scope=>$scope, req=>$req_or, res=>$res_or,
                receive => $receive, send=> $send, no_head_insert=>$self->{'no_head_insert'}, filename=>$self->{'filename'});
            $request_opt{'filename'} ||= do {$api_fn if $api_fn};
            $r=WebDyne::Request::PAGI->new(%request_opt) ||
                    return err('unable to create new WebDyne::Request::PAGI object: %s',
                        $@ || errclr() || 'unknown error');
            debug("r: $r");

            #  Call handler and evaluate results
            #
            $status=WebDyne->handler($r);
            debug("handler returned status: $status");
            $r->status($status);
        }


        #  Can close html file handle now
        #
        $html_fh->close();
        debug("html returned:\n$html");


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
                
                    
                    #  If get here nothing found, send 404 error
                    #
                    debug("status: $status, fn:$fn, setting HTTP_NOT_FOUND");
                    $r->status(HTTP_NOT_FOUND);
                    my $error=errdump() || "File not found, status ($status)"; errclr();
                    $html=$r->err_html($status, $error)
                }
                elsif (is_error($status) ) {
                
                    #  Some other error besides 404
                    #
                    debug("returning custom error: $status");
                    $r->status($status);
                    $html=$r->custom_response($status) || errstr() || do {
                        $r->content_type($WEBDYNE_CONTENT_TYPE_TEXT);
                        "Error: $status with no content - try server error logs ?";
                    };

                }
                else {
                
                    #  Weird non HTTP status code, something has gone wrong along way
                    #
                    debug('undefined status returned, looking for error handler');
                    my $error=errdump() || $@; errclr();
                    $error ||=  "Unexpected return status ($status) from handler";
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
        my $final_status=$r->status() || $status || HTTP_OK;
        debug("final handler status: %s, content_type: %s, html:%s", $final_status, $r->content_type(), $html);
        
        
        #  Send headers unless already sent
        #
        $r->res->status($final_status);
        my $headers_ar=$r->headers_out->psgi_flatten_without_sort();
        debug('sending headers: %s', Dumper($headers_ar));
        for (my $i=0; $i<@{$headers_ar}; $i+=2) {
            my ($header, $value)=@{$headers_ar}[$i, $i+1];
            $r->res->header_try($header => $value);
        }
        
        
        #  If html is defined set header content type unless already set during
        #  handler execution, then always send the response. An API page with
        #  no matching route legitimately returns an empty 200 response; PAGI
        #  still requires response.start to be emitted in that case.
        #
        my $body=$html || '';
        if ($body) {
            debug('sending html to client via await()');
            $r->res->content_type($r->content_type() || $WEBDYNE_CONTENT_TYPE_HTML);
        }
        my $respond_status=await $r->res->send($body)->respond($send);
        $r->DESTROY();
        return $respond_status;


        
    })
    
}


sub api_filename {

    my ($self, $scope)=@_;
    return unless WEBDYNE_API_ENABLE;

    my $path=$scope->{'path'} || '';
    return unless length($path);

    my @part=grep { length($_) } split(m{/+}, $path);
    return if grep { $_ eq '.' || $_ eq '..' } @part;

    my $root=File::Spec->rel2abs($self->{'root'});
    my $API_fn=$self->{'API_fn'};
    for my $ix (0 .. $#part) {
        my $candidate=File::Spec->catfile($root, @part[0 .. $ix]);
        $candidate .= WEBDYNE_PSP_EXT unless $candidate =~ WEBDYNE_PSP_EXT_RE;

        my $relative=File::Spec->abs2rel($candidate, $root);
        next if $relative eq '..' || $relative =~ /^\.\.(?:[\\\/]|$)/;
        if ($API_fn->{$candidate} || (-f $candidate)) {
            debug("found api file name: $candidate, %s, dispatching", Dumper($API_fn));
            $API_fn->{$candidate}++; # Cache so not stat()ing on file system
            return $candidate;
        }
    }

    return;
}


sub handler_lifespan {

    my $self=shift();
    
    return set_subname('handler_lifespan_anon', async sub {

        my ($scope, $receive, $send) = @_;
        while (1) {
            my $event_hr = await $receive->();
            if ($event_hr->{'type'} eq 'lifespan.startup') {
                printf STDERR "[lifespan] WebDyne PAGI handler startup. DOCUMENT_ROOT: %s, DOCUMENT_DEFAULT: %s\n", $self->{'root'}, basename($self->{'index'} || $DOCUMENT_DEFAULT);
                await $send->({ type => 'lifespan.startup.complete' });
                
            }
            elsif ($event_hr->{'type'} eq 'lifespan.shutdown') {
                print STDERR "[lifespan] WebDyne PAGI handler shutdown.\n";
                await $send->({ type => 'lifespan.shutdown.complete' });
                last;
            }
        }
    })
}


sub normalize_dn {

    #  Normal dir, normally document_root
    #
    my $rel_dn=shift();
    my $abs_dn=File::Spec->rel2abs($rel_dn);
    $abs_dn =~ s{/$}{} unless $abs_dn eq '/';
    return $abs_dn;
    
}

1;
__END__

=begin markdown

# WebDyne::PAGI #

# NAME #

WebDyne::PAGI - PAGI application wrapper for WebDyne

# SYNOPSIS #

```perl
use WebDyne::PAGI;

my $app = WebDyne::PAGI->new(
    root  => '.',
    index => 1,
)->to_app;

my $single_file_app = WebDyne::PAGI->new(
    root     => '.',
    filename => 'app.psp',
)->to_app;
```

# DESCRIPTION #

`WebDyne::PAGI` wraps the core WebDyne handler in a PAGI application. It supports multiple PAGI scope types, including normal HTTP requests, server-sent events, WebSocket connections, and lifespan startup or shutdown events.

# METHODS #

* **new(%options)**

    Construct a PAGI application wrapper. Options include `root`, `index`, `test`, `filename`, and related runtime settings.

    The `filename` option is an explicit source-file override for the application. When supplied, it is passed to `WebDyne::Request::PAGI` for every HTTP request and always wins over normal filename derivation from the PAGI request scope, including path-based dispatch, document-root resolution, default document handling, and API-style fallback resolution. This is useful for helper tools or deliberate single-file PAGI applications; do not set it for normal multi-page applications that should dispatch from the request path.

* **to_app()**

    Return the PAGI application code reference.

* **handler_http()**

    Handle normal HTTP requests.

* **handler_sse()**

    Handle server-sent event requests.

* **handler_ws()**

    Handle WebSocket requests.

* **handler_lifespan()**

    Handle PAGI lifespan startup and shutdown events.

* **handler_sse_error()**

    Helper for reporting SSE-side failures.

# NOTES #

The module relies on `WebDyne::Request::PAGI` for normalized request handling and on `WebDyne::PAGI::Constant` for middleware and environment defaults.

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


=head1 WebDyne::PAGI


=head1 NAME

WebDyne::PAGI - PAGI application wrapper for WebDyne


=head1 SYNOPSIS


 use WebDyne::PAGI;
 
 my $app = WebDyne::PAGI->new(
     root  => '.',
     index => 1,
 )->to_app;
 
 my $single_file_app = WebDyne::PAGI->new(
     root     => '.',
     filename => 'app.psp',
 )->to_app;

=head1 DESCRIPTION

C<WebDyne::PAGI> wraps the core WebDyne handler in a PAGI application. It supports multiple PAGI scope types, including normal HTTP requests, server-sent events, WebSocket connections, and lifespan startup or shutdown events.


=head1 METHODS

=over

=item *

B<new(%options)>

Construct a PAGI application wrapper. Options include C<root>, C<index>, C<test>, C<filename>, and related runtime settings.

The C<filename> option is an explicit source-file override for the application. When supplied, it is passed to C<WebDyne::Request::PAGI> for every HTTP request and always wins over normal filename derivation from the PAGI request scope, including path-based dispatch, document-root resolution, default document handling, and API-style fallback resolution. This is useful for helper tools or deliberate single-file PAGI applications; do not set it for normal multi-page applications that should dispatch from the request path.



=item *

B<to_app()>

Return the PAGI application code reference.



=item *

B<handler_http()>

Handle normal HTTP requests.



=item *

B<handler_sse()>

Handle server-sent event requests.



=item *

B<handler_ws()>

Handle WebSocket requests.



=item *

B<handler_lifespan()>

Handle PAGI lifespan startup and shutdown events.



=item *

B<handler_sse_error()>

Helper for reporting SSE-side failures.



=back


=head1 NOTES

The module relies on C<WebDyne::Request::PAGI> for normalized request handling and on C<WebDyne::PAGI::Constant> for middleware and environment defaults.


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
