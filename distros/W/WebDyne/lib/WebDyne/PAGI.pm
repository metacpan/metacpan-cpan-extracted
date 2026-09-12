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
use Scalar::Util qw(blessed reftype);


#  PAGI modules
#
use PAGI::Request;
use PAGI::Response;


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
$VERSION='3.029';


#==================================================================================================

sub new {


    #  Get options
    #
    my ($class, %opt)=@_;

    foreach my $phase (qw(startup shutdown)) {
        die "PAGI $phase callback must be a coderef\n"
            if (defined($opt{$phase})&&((reftype($opt{$phase}) || '') ne 'CODE'));
    }
    
    
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


    #  Load local config if requested. Keep the default off so direct
    #  WebDyne::PAGI->new()->to_app callers preserve existing behaviour.
    #
    if ($opt{'conf'}) {
        $class->local_constant_load($opt{'root'}, $opt{'conf'});
    }


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


    #  Wrap with configured PAGI middleware.
    #
    $app_cr=$self->build($app_cr);
    
    
    #  Done
    #
    return $app_cr;
    
}


sub build {


    #  Wrap a PAGI app code ref in configured middleware.
    #
    my ($self, $app_cr)=@_;


    #  Static service can be overridden per instance without changing the
    #  package default for later apps in the same interpreter.
    #
    my $static_fg=$WEBDYNE_PAGI_STATIC;
    $static_fg=$self->{'static'} if exists($self->{'static'});


    #  Build list of active middleware.
    #
    my @middleware;
    foreach my $middleware_ar (@{$WEBDYNE_PAGI_MIDDLEWARE}) {
        my ($middleware, $middleware_opt_hr)=@{$middleware_ar};

        #  Skip static if not wanted
        #
        if ($middleware eq 'Static') {
            next unless $static_fg;
        }


        #  And code refs are run and given self as first param
        #
        if (ref($middleware_opt_hr) eq 'CODE') {
            $middleware_opt_hr=$middleware_opt_hr->($self);
        }


        #  Save it for wrapping below
        #
        push @middleware, [$middleware, $middleware_opt_hr];
    }


    #  No active middleware, preserve bare app behaviour and avoid requiring
    #  PAGI::Middleware::Builder for direct WebDyne::PAGI use.
    #
    return $app_cr unless @middleware;


    #  Build middleware stack
    #
    require PAGI::Middleware::Builder;
    my $builder_or=PAGI::Middleware::Builder->new();
    foreach my $middleware_ar (@middleware) {
        my ($middleware, $middleware_opt_hr)=@{$middleware_ar};
        $builder_or->add_middleware($middleware, %{$middleware_opt_hr});
    }


    #  Done
    #
    return $builder_or->to_app($app_cr);

}


sub local_constant_load {


    #  Read in local webdyne.conf.pl
    #
    my ($class, $root_dn, $conf)=@_;


    #  If root_dn is a file get dir name
    #
    if (-f $root_dn) {
        $root_dn=(File::Spec->splitpath($root_dn))[1];
    }


    #  Resolve conf option. 1 means root/.webdyne.conf.pl, otherwise use
    #  explicit path relative to root unless already absolute.
    #
    my $conf_fn;
    if ($conf eq '1') {
        $conf_fn=File::Spec->catfile($root_dn, sprintf('.%s', $WEBDYNE_CONF_FN));
    }
    else {
        $conf_fn=File::Spec->file_name_is_absolute($conf) ?
            $conf :
            File::Spec->catfile($root_dn, $conf);
    }


    #  Load via existing constant import path.
    #
    WebDyne::Constant->import($conf_fn);
    return $conf_fn;

}


sub handler_sse {

    my $self=shift();
    return async sub {
        my ($scope, $receive, $send)=@_;
        my ($size, $disconnected)=(0, 0);
        my $req_or=PAGI::Request->new($scope, async sub {
            my $event_hr=await $receive->();
            if ($event_hr->{'type'} eq 'sse.disconnect') {
                $disconnected=1;
                return {%{$event_hr}, type => 'http.disconnect'};
            }
            die "unexpected event while reading SSE form" unless $event_hr->{'type'} eq 'sse.request';
            $size += length(defined($event_hr->{'body'}) ? $event_hr->{'body'} : '');
            die "SSE form exceeds upload limit" if $size > $WEBDYNE_CGI_POST_MAX;
            return $event_hr;
        });

        #  Only URL-encoded forms need staging here. EventSource GETs keep
        #  their existing path; multipart SSE submissions are not supported.
        #  Use PAGI's buffered helper so CGI can read synchronously below.
        #
        if ($req_or->content_type() eq 'application/x-www-form-urlencoded') {
            my $length=$req_or->content_length();
            $size=$length if defined($length) && $length =~ /\A[0-9]+\z/;
            unless ($size > $WEBDYNE_CGI_POST_MAX) {
                $size=0;
                my $read=eval { await $req_or->body(); 1 };
                die $@ unless $read || $size > $WEBDYNE_CGI_POST_MAX;
            }
            if ($size > $WEBDYNE_CGI_POST_MAX) {
                await $send->({type => 'sse.http.response.start', status => HTTP_REQUEST_ENTITY_TOO_LARGE,
                    headers => [['content-type', 'text/plain']]});
                await $send->({type => 'sse.http.response.body', body => "Request body exceeds upload limit\n", more => 0});
                return;
            }
            return if $disconnected;
        }

        my ($sse_cr, $status);
        {
            #  Start page setup with clean diagnostics after body buffering.
            #
            errclr();

            #  Confine localized process state to synchronous page setup.
            #  POST fields are buffered before CGI builds the parameter hash.
            #
            local *ENV=\%ENV_BASE;
            my $res_or=PAGI::Response->new($scope);
            require PAGI::SSE;
            my $sse_or=PAGI::SSE->new($scope, $receive, $send);
            my $r=WebDyne::Request::PAGI->new(
                document_root => $self->{'root'}, document_default => $self->{'index'},
                scope => $scope, req => $req_or, res => $res_or, sse => $sse_or,
                receive => $receive, send => $send,
            ) || return err('unable to create SSE request');
            $status=WebDyne->handler($r);
            $sse_cr=$r->custom_response($status) if $status eq HTTP_CONTINUE;
        }

        #  Decline before starting a stream. Preserve HTTP error statuses;
        #  other results without an SSE callback indicate a setup failure.
        #  Send outside the localized environment and await both events.
        #
        unless (ref($sse_cr) eq 'CODE') {
            $status=HTTP_INTERNAL_SERVER_ERROR
                unless defined($status) && $status =~ /\A[45][0-9]{2}\z/;
            my $message=HTTP::Status::status_message($status) || 'Request failed';
            await $send->({
                type => 'sse.http.response.start', status => $status,
                headers => [['content-type', 'text/plain']],
            });
            await $send->({
                type => 'sse.http.response.body',
                body => "$status $message\n", more => 0,
            });
            return;
        }
        await $sse_cr->($scope, $receive, $send);
    };

}


sub handler_sse_error {

    return async sub {
    

        #  Get request
        #
        my ($scope, $receive, $send)=@_;
        debug('in handler_sse_error, scope:%s receive:%s, send:%s', Dumper($scope, $receive, $send));


        #  Create helper objects
        #
        require PAGI::SSE;
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


    #  Start synchronous WebSocket setup with clean diagnostics.
    #
    errclr();


    #  Setup %ENV
    #
    local *ENV=\%ENV_BASE;


    #  Create helper objects
    #
    my $req_or=PAGI::Request->new($scope, $receive) ||
        return err('unable to get PAGI::Request object');
    my $res_or=PAGI::Response->new($scope) ||
        return err('unable to get PAGI::Response object');
    require PAGI::WebSocket;
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
        return $ws_cr if ref($ws_cr) eq 'CODE';
    }

    #  Reject before accepting the socket. The server converts this into
    #  an HTTP 403 handshake response; no optional extension is required.
    #
    return async sub {
        my ($scope, $receive, $send)=@_;
        await $send->({type => 'websocket.close'});
    };

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
        my ($r, $html, $html_fh, $status, $req_or, $res_or);

        #  WebDyne page code reads synchronously. Buffer HTTP bodies before
        #  dispatch, bounded by the existing 512 KiB default upload limit.
        #  Count actual bytes even when Content-Length is absent or inaccurate.
        #  Wrapping receive preserves PAGI's buffered body/json helpers; using
        #  body_stream for every request would disable those helpers.
        #
        my ($body_bytes, $body_oversize, $body_disconnected)=(0, 0, 0);
        my $bounded_receive_cr=async sub {
            my $event_hr=await $receive->();
            if ($event_hr->{'type'} eq 'http.disconnect') {
                $body_disconnected=1;
                return $event_hr;
            }
            die "unexpected event while reading HTTP body" unless $event_hr->{'type'} eq 'http.request';
            $body_bytes += length(defined($event_hr->{'body'}) ? $event_hr->{'body'} : '');
            if ($body_bytes > $WEBDYNE_CGI_POST_MAX) {
                $body_oversize=1;
                die "request body exceeds upload limit";
            }
            return $event_hr;
        };
        $req_or=PAGI::Request->new($scope, $bounded_receive_cr) ||
            return err('unable to get PAGI::Request object');
        $res_or=PAGI::Response->new($scope) ||
            return err('unable to get PAGI::Response object');

        #  Reject a declared oversize body before consuming any input. The
        #  receive counter remains authoritative for bodies we do accept.
        #
        my $content_length=$req_or->content_length();
        $body_oversize=1 if defined($content_length) && $content_length =~ /\A[0-9]+\z/
            && $content_length > $WEBDYNE_CGI_POST_MAX;
        unless ($body_oversize) {
            my $staged=eval {
                if (
                    ($req_or->content_type() || '') =~ m{\Aapplication/x-www-form-urlencoded\b}i
                    #  PAGI form data need not declare Content-Length.
                    # && $req_or->content_length()
                ) {
                    await $req_or->body();
                }
                elsif (
                    ($req_or->content_type() || '') =~ m{\Amultipart/form-data(?:\s*;|\z)}i
                    #  Stage chunked uploads too, with the independent limit.
                    # && $req_or->content_length()
                ) {
                    my $multipart_body='';
                    my $stream_or=$req_or->body_stream(max_bytes => $WEBDYNE_CGI_POST_MAX);
                    await $stream_or->stream_to(sub { $multipart_body .= shift() });
                    $scope->{'webdyne.pagi.multipart_body'}=\$multipart_body;
                }
                else {
                    await $req_or->body();
                }
                1;
            };
            die $@ unless $staged || $body_oversize;
        }
        if ($body_oversize) {
            return await $res_or
                ->status(HTTP_REQUEST_ENTITY_TOO_LARGE)
                ->send("Request body exceeds upload limit\n")
                ->respond($send);
        }

        #  PAGI's helpers may return partial bytes on disconnect. Never run
        #  page code with an incomplete upload or synthesize a response for it.
        #
        return if $body_disconnected;

        {
            #  Start page setup with clean diagnostics after body buffering.
            #
            errclr();

            #  Keep the request environment localized only while WebDyne is
            #  constructing and executing the request. Do not retain a
            #  localized global %ENV across an asynchronous response await.
            #
            local *ENV=\%ENV_BASE;
            @ENV{qw(PATH_INFO QUERY_STRING REQUEST_METHOD SCRIPT_NAME)}=(
                WebDyne::Request::PAGI::scope_path($scope),
                $scope->{'query_string'} || '',
                $scope->{'method'} || '',
                $scope->{'root_path'} || '',
            );

            #  If the requested path is not a file, an API PSP may own a path
            #  prefix such as /api.psp or /example/api.psp. Resolve that prefix
            #  before constructing the request so the normal WebDyne handler can
            #  process the PSP. The discovered API file path becomes the mount
            #  point, so /example/api.psp owning /example/api/foo passes /foo to
            #  Router::Simple.
            #
            my $api_fn=api_filename($self, $scope);
            if ($api_fn) {
                my $api_path=File::Spec->abs2rel($api_fn, File::Spec->rel2abs($self->{'root'}));
                $api_path=~s{\Q@{[WEBDYNE_PSP_EXT]}\E$}{};
                $ENV{'PATH_INFO'}=~s{^/\Q$api_path\E(?=/|$)}{}i;
            }

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
        my $cookie_seen;
        for (my $i=0; $i<@{$headers_ar}; $i+=2) {
            my ($header, $value)=@{$headers_ar}[$i, $i+1];
            if (lc($header) eq 'set-cookie') {
                $r->res->remove_header('set-cookie') unless $cookie_seen++;
                $r->res->header('set-cookie' => $value);
            }
            else {
                $r->res->header_try($header => $value);
            }
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

        #  Encode character strings, but preserve byte strings from files and R2.
        #
        my $send_method=utf8::is_utf8($body) ? 'send' : 'send_raw';
        my $respond_or=$r->res->$send_method($body)->respond(sub {

            #  PAGI requires lowercase names in response events. Normalize only
            #  the outgoing header pairs, preserving values, order and duplicates.
            #
            my $event_hr=shift();
            if ($event_hr->{'type'} eq 'http.response.start') {
                $event_hr={
                    %{$event_hr},
                    headers => [
                        map { [lc($_->[0]), $_->[1]] }
                            @{$event_hr->{'headers'} || []}
                    ],
                };
            }
            return $send->($event_hr);
        });

        #  Retain the response Future across await. Awaiting the temporary can
        #  crash Devel::Confess stack tracing on send failure with Perl 5.38.
        #
        my $respond_status=await $respond_or;
        $r->DESTROY();
        return $respond_status;


        
    })
    
}


sub api_filename {

    my ($self, $scope)=@_;
    return unless WEBDYNE_API_ENABLE;

    my $path=WebDyne::Request::PAGI::scope_path($scope);
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

        my ($scope_hr, $receive_cr, $send_cr)=@_;
        while (1) {
            my $event_hr=await $receive_cr->();
            my $phase=$event_hr->{'type'} eq 'lifespan.startup' ? 'startup'
                : $event_hr->{'type'} eq 'lifespan.shutdown' ? 'shutdown' : undef;
            next unless defined($phase);

            #  Own the protocol acknowledgement; callbacks only perform work.
            #  Keep send failures outside the callback exception boundary.
            #
            my $ok=eval { await $self->lifespan_callback($phase, $scope_hr); 1 };
            unless ($ok) {
                my $error=$@;
                await $send_cr->({type => "lifespan.$phase.failed", message => "$error"});
                last;
            }
            if ($phase eq 'startup') {
                printf STDERR "[lifespan] WebDyne PAGI handler startup. DOCUMENT_ROOT: %s, DOCUMENT_DEFAULT: %s\n", $self->{'root'}, basename($self->{'index'} || $DOCUMENT_DEFAULT);
            }
            else {
                print STDERR "[lifespan] WebDyne PAGI handler shutdown.\n";
            }
            await $send_cr->({type => "lifespan.$phase.complete"});
            last if $phase eq 'shutdown';
        }
    })
}


async sub lifespan_callback {

    my ($self, $phase, $scope_hr)=@_;
    die "Unknown PAGI lifespan phase\n" unless (($phase eq 'startup')||($phase eq 'shutdown'));
    my $callback_cr=$self->{$phase};
    return unless defined($callback_cr);
    my $result_ref=$callback_cr->($self, $scope_hr);
    await $result_ref if (blessed($result_ref)&&$result_ref->isa('Future'));
    return;
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
    root   => '.',
    index  => 1,
    static => 1,
    conf   => 1,
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

    Construct a PAGI application wrapper. Options include `root`, `index`, `test`, `filename`, `static`, `conf`, and related runtime settings.

    The `filename` option is an explicit source-file override for the application. When supplied, it is passed to `WebDyne::Request::PAGI` for every HTTP request and always wins over normal filename derivation from the PAGI request scope, including path-based dispatch, document-root resolution, default document handling, and API-style fallback resolution. This is useful for helper tools or deliberate single-file PAGI applications; do not set it for normal multi-page applications that should dispatch from the request path.

    The `static` option enables or disables the configured PAGI static-file middleware for this app instance. Static middleware is disabled by the package default, but wrapper scripts such as `webdyne.pagi` may pass `static => 1`.

    The `conf` option loads local WebDyne constants during app construction. A true value of `1` loads `$root/.webdyne.conf.pl`; any other true value is treated as an explicit config filename, relative to `root` unless already absolute.

* **to_app()**

    Return the PAGI application code reference, wrapped in configured PAGI middleware.

* **handler_http()**

    Handle normal HTTP requests. Outgoing response header names are normalized to lowercase for PAGI, preserving values, order, and duplicates without changing the stored header collections.

* **handler_sse()**

    Handle server-sent event requests. URL-encoded form bodies are buffered before CGI parameter setup, subject to `WEBDYNE_CGI_POST_MAX`. Oversized forms receive status 413 through SSE HTTP denial events; disconnects during buffering skip page execution. Normal EventSource GETs do not wait for body data. Multipart SSE form submissions are outside this handler's supported scope. When page setup returns an HTTP error status instead of a stream callback, send a plain-text SSE HTTP denial response with that status. Other results without a valid callback produce status 500. Custom error headers and redirects are not forwarded by this fallback.

* **handler_ws()**

    Handle WebSocket requests. If page setup does not provide a valid WebSocket callback, reject the handshake with `websocket.close`. This uses the standard HTTP 403 rejection without requiring the optional HTTP denial-response extension.

* **handler_lifespan()**

    Handle PAGI lifespan startup and shutdown events.

* **handler_sse_error()**

    Helper for reporting SSE-side failures.

# NOTES #

HTTP, SSE and WebSocket handlers clear WebDyne's shared diagnostic stack before synchronous page setup. HTTP and SSE body buffering completes before this reset, so errors from another request processed during buffering do not contaminate the resumed render. Diagnostics raised during page setup remain available to its error-response handling.

This is a synchronous request boundary, not per-session diagnostic storage. Asynchronous callbacks must not rely on `errstr()` or `errdump()` retaining their diagnostics across an `await`; use exceptions or Future failures to propagate asynchronous errors. Caught exceptions within one render can still populate the shared stack.

The module relies on `WebDyne::Request::PAGI` for normalized request handling and on `WebDyne::PAGI::Constant` for middleware and environment defaults.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

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
     root   => '.',
     index  => 1,
     static => 1,
     conf   => 1,
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

Construct a PAGI application wrapper. Options include C<root>, C<index>, C<test>, C<filename>, C<static>, C<conf>, and related runtime settings.

The C<filename> option is an explicit source-file override for the application. When supplied, it is passed to C<WebDyne::Request::PAGI> for every HTTP request and always wins over normal filename derivation from the PAGI request scope, including path-based dispatch, document-root resolution, default document handling, and API-style fallback resolution. This is useful for helper tools or deliberate single-file PAGI applications; do not set it for normal multi-page applications that should dispatch from the request path.

The C<static> option enables or disables the configured PAGI static-file middleware for this app instance. Static middleware is disabled by the package default, but wrapper scripts such as C<webdyne.pagi> may pass C<<< static => 1 >>>.

The C<conf> option loads local WebDyne constants during app construction. A true value of C<1> loads C<$root/.webdyne.conf.pl>; any other true value is treated as an explicit config filename, relative to C<root> unless already absolute.



=item *

B<to_app()>

Return the PAGI application code reference, wrapped in configured PAGI middleware.



=item *

B<handler_http()>

Handle normal HTTP requests. Outgoing response header names are normalized to lowercase for PAGI, preserving values, order, and duplicates without changing the stored header collections.



=item *

B<handler_sse()>

Handle server-sent event requests. URL-encoded form bodies are buffered before CGI parameter setup, subject to C<WEBDYNE_CGI_POST_MAX>. Oversized forms receive status 413 through SSE HTTP denial events; disconnects during buffering skip page execution. Normal EventSource GETs do not wait for body data. Multipart SSE form submissions are outside this handler's supported scope. When page setup returns an HTTP error status instead of a stream callback, send a plain-text SSE HTTP denial response with that status. Other results without a valid callback produce status 500. Custom error headers and redirects are not forwarded by this fallback.



=item *

B<handler_ws()>

Handle WebSocket requests. If page setup does not provide a valid WebSocket callback, reject the handshake with C<websocket.close>. This uses the standard HTTP 403 rejection without requiring the optional HTTP denial-response extension.



=item *

B<handler_lifespan()>

Handle PAGI lifespan startup and shutdown events.



=item *

B<handler_sse_error()>

Helper for reporting SSE-side failures.



=back


=head1 NOTES

HTTP, SSE and WebSocket handlers clear WebDyne's shared diagnostic stack before synchronous page setup. HTTP and SSE body buffering completes before this reset, so errors from another request processed during buffering do not contaminate the resumed render. Diagnostics raised during page setup remain available to its error-response handling.

This is a synchronous request boundary, not per-session diagnostic storage. Asynchronous callbacks must not rely on C<errstr()> or C<errdump()> retaining their diagnostics across an C<await>; use exceptions or Future failures to propagate asynchronous errors. Caught exceptions within one render can still populate the shared stack.

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
