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

package WebDyne::Request::PAGI;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use File::Spec;
use File::Spec::Unix;
use HTTP::Status qw(status_message HTTP_OK HTTP_NOT_FOUND HTTP_FOUND);
use URI;
use Data::Dumper;
use HTTP::Headers::Fast;
use Future::AsyncAwait;
use PAGI::Request;
use File::Temp qw(tempfile);


#  WebDyne modules
#
use WebDyne::Util;
use WebDyne::Constant;
use WebDyne::PAGI::Constant;
use WebDyne::Request::Common qw(handler_methods_init);
use WebDyne::Request::Fake;


#  Version information
#
$VERSION='3.019';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Init
#
&init() unless defined(&method);


#  All done. Positive return
#
1;


#==================================================================================================


sub init {

    #  Setup pass through methods
    #
    my %method=(
        accept              => undef,
        accept_encoding     => undef,
        accept_language     => undef,
        args                => 'query_string',
        as_string           => undef,
        authority           => undef,
        authorization       => undef,
        auth_type           => undef,
        base                => \&base,
        base_url            => \&base_url,
        body_handle         => \&body_handle,
        body                => \&body,
        cache_control       => undef,
        charset             => undef,
        cleanup_register    => undef,
        client_address      => sub { shift()->{'req'}->client()->[0] },
        content             => \&body,
        content_encoding    => undef,
        content_length      => undef,
        content_type        => undef,,
        cookies             => 'cookies',
        cookie              => 'cookies',
        custom_response     => undef,
        cwd                 => undef,
        dir_config          => undef,
        document_root       => undef,
        env                 => \&env,
        etag                => undef,
        filename            => undef,
        finalize            => undef,
        finfo               => undef,
        form_parameters     => 'form_params',
        forwarded_for       => undef,
        fragment            => undef,
        handler             => undef,
        header              => \&headers_in,
        headers             => \&headers_in,
        header_only         => \&header_only,
        headers_in          => \&headers_in,
        headers_out         => \&headers_out,
        hostname            => 'host',
        host                => 'host',
        https               => \&https,
        http_version        => 'http_version',
        id                  => \&id,
        if_modified_since   => undef,
        if_none_match       => undef,
        input               => \&body_handle,
        is_ajax             => undef,
        is_main             => undef,
        location            => undef,
        log_error           => undef,
        lookup_file         => undef,
        lookup_uri          => undef,
        main                => undef,
        media_type          => undef,
        method              => 'method',
        mtime               => undef,
        multipart_parameters=> 'form_params',
        next                => undef,
        notes               => undef,
        origin              => undef,
        output_filters      => undef,
        path_info           => 'path',
        path_parameters     => undef,
        path                => 'path',
        pool                => undef,
        preferred_charset   => undef,
        preferred_encoding  => undef,
        preferred_language  => undef,
        preferred_media_type=> undef,
        prev                => undef,
        print               => undef,
        protocol            => sub { 'HTTP/'. shift()->{'req'}->http_version() },
        query_parameters    => 'query_params',
        query_string        => 'query_string',
        redirect            => undef,
        referer             => undef,
        register_cleanup    => undef,
        remote_address      => 'client',
        remote_host         => 'client',
        remote_port         => undef,
        remote_user         => undef,
        request_time        => \&request_time,
        route               => undef,
        run                 => undef,
        scheme              => 'scheme',
        script_name         => undef,
        secure              => \&secure,
        sendfile            => undef,
        send_http_header    => undef,
        server_name         => \&server_name,
        server_port         => \&server_port,
        session_id          => undef,
        session             => undef,
        set_handlers        => undef,
        status_line         => undef,
        status              => undef,
        unparsed_uri        => \&uri,
        uploads             => 'uploads',
        uri                 => undef,
        url                 => undef,
        user_agent          => undef,
        user                => undef,
        write               => undef,
        err_html            => undef,
        DESTROY             => undef
    );
    
    
    #  Implement and return
    #
    foreach my $handler (qw(req res sse ws)) {
        *{$handler}=sub { return shift()->{$handler} };
    }
    return handler_methods_init(__PACKAGE__, 'PAGI::Request', \%method);

    
}


sub new {


    #  New PAGI request
    #
    my ($class, %r)=@_;
    debug("$class, r: %s, calller:%s", Dumper(\%r, [caller(0)]));


    #  Require scope
    #
    #$r{'scope'} || return err('no PAGI scope object supplied');
    #$r{'req'}   || return err('no PAGI::Request object supplied');


    #  Try to figure out filename user wants
    #
    unless ($r{'filename'}) {

        #  Not supplied - need to work out
        #
        debug('filename not supplied, determining from request');

        my $fn;
        my $invalid_path;
        if (my $dn=($r{'document_root'} || $ENV{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT)) {

            #  Get from URI and location
            #
            my $uri=$r{'uri'} || $r{'req'}->path();
            debug("uri: $uri");
            my @uri_part=grep { length($_) } split(m{/+}, $uri);
            if (grep { $_ eq '..' } @uri_part) {
                debug("rejecting path traversal attempt in uri: $uri");
                $fn=undef;
                $invalid_path=1;
            }
            else {
                $fn=File::Spec->rel2abs(File::Spec->catfile($dn, @uri_part));
            }
            debug("fn: $fn from dn: $dn, uri: $uri");

        }

        #  Need to add default psp file ?
        #
        unless ($invalid_path || ($fn=~WEBDYNE_PSP_EXT_RE)) { # fastest

            #  Is it a directory that exists ? Only append default document if that is the case, else let the api code
            #  handle it
            #
            if  (($fn=~/\/$/) || ((-d $fn) || !$fn)) {

                #  Append default doc to path, which appears at moment to be a directory ?
                #
                my $document_default=$r{'document_default'} || $DOCUMENT_DEFAULT;
                debug("appending document default $document_default to fn:$fn");

                #  If absolute path just use it
                #
                if (File::Spec->file_name_is_absolute($document_default)) {

                    #  Yep - absolute path
                    #
                    $fn=$document_default
                }
                else {

                    #  Otherwise append to existing path
                    #
                    $fn=File::Spec->catfile($fn, split m{/+}, $document_default); #/
                    $fn=File::Spec->rel2abs($fn);
                }
            }
            else {

                #  Not .psp file, do not want
                #
                debug("fn: $fn does not end with /, leaving undef");
                $fn=undef;
            }
        }

        #  Final sanity check
        #
        debug("final fn: $fn");
        $r{'filename'}=$fn;

    }


    #  Finished, pass back
    #
    return bless \%r, $class;

}


sub env {

    return shift()->{'scope'}
    
}


sub id {
    return shift()->{'scope'}{'request_id'};
}


sub https {
    return (shift()->scheme() || '') eq 'https';
}


sub secure {
    return (shift()->scheme() || '') eq 'https';
}


sub server_name {
    my $r=shift();
    if (my $server_ar=$r->{'scope'}{'server'}) {
        return $server_ar->[0];
    }
    return undef;
}


sub server_port {
    my $r=shift();
    if (my $server_ar=$r->{'scope'}{'server'}) {
        return $server_ar->[1];
    }
    return undef;
}


sub body {

    my $r=shift();
    my $body;
    if (my $body_or=$r->{'req'}->body()) {
        $body=$body_or->get;
    }
    
}

sub body_handle {

    #  Try to munge streamed IO into file handle
    #
    my $r=shift();
    debug($r);
    local $SIG{__DIE__};
    my ($fh, $fn) = tempfile();
    if (my $stream_or=eval{ $r->{'req'}->body_stream() }) {
        
        my $future_or=$stream_or->stream_to_file($fn);
        my $loop =
            $r->{'scope'}{'pagi.connection'}
              {'_connection'}
              {'idle_timer'}
              {'IO_Async_Notifier__loop'};
        debug("loop: $loop, awaiting end");
        $loop->await($future_or) if $loop;
        debug("loop completed on fn: $fn, fh: $fh, size: %s", (-s $fn));
        seek($fh,0,0);
    }
    eval {} if $@;
    return $fh;

}


sub headers_in {

    my $r=shift();
    debug("r: $r, param: %s", Dumper(\@_));
    my $headers_in_or=$r->{'headers_in'} ||= do {
        my $headers_pagi_or=$r->{'req'}->headers();
        debug('headers_pagi_or: %s', Dumper($headers_pagi_or));
        my @header;
        #foreach my $header ($headers_pagi_or->keys) {
        foreach my $header ($headers_pagi_or->names) {
            my @value=$headers_pagi_or->get_all($header);
            $header=~s{(^|-)([a-z])}{$1\u$2}g;
            map { push @header, ($header, $_) } @value;
        }
        debug('header_fast: %s', Dumper(\@header));
        HTTP::Headers::Fast->new(@header)
    };
    debug('headers_in now: %s', Dumper($headers_in_or));
    
    #  Now run
    #
    #return $r->SUPER::headers_in(@_);
    return $r->WebDyne::Request::Fake::headers_in(@_);
    
}


sub headers_out {
    my $r=shift();
    my $headers_or=$r->{'headers_out'}
        ||= HTTP::Headers::Fast->new(map { @{$_} } @{$r->{'res'}->headers()});
    if (@_) {
        $r->{'res'}->header(@_);
        return $headers_or->header(@_);
    }
    return $headers_or;
}


sub header_only {
    return (shift()->method() eq 'HEAD');
}


sub request_time {
    return shift()->{'scope'}{'start_time'};
}


sub base {
    return URI->new(shift()->_uri_base())->canonical();
}


sub base_url {
    return URI->new(shift()->_uri_base())->canonical();
}


1;

__END__

=begin markdown

# WebDyne::Request::PAGI #

# NAME #

WebDyne::Request::PAGI - PAGI request adapter for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Request::PAGI;

my $wr = WebDyne::Request::PAGI->new(
    scope => $scope,
    req   => $pagi_request,
    res   => $pagi_response,
);
```

# DESCRIPTION #

`WebDyne::Request::PAGI` adapts PAGI request state to the normalized request API expected by WebDyne.

Like the PSGI adapter, it can derive a target filename from the request path, configured document root, and default document settings. It also exposes PAGI-specific request information such as scope-based protocol details, body access, form/query parameters, and request timing through the common WebDyne request surface.

# METHODS #

* **new(%options)**

    Construct a PAGI-backed request adapter.

* **env()**

    Return the normalized environment view used by the adapter.

* **id()**

    Return the request identifier if present.

* **https() / secure()**

    Return HTTPS/security state derived from the PAGI request.

* **server_name() / server_port()**

    Return server identity details.

* **body() / body_handle()**

    Read or stream the request body.

* **headers_in() / headers_out()**

    Access request and response headers.

* **header_only()**

    Return whether the current request should emit headers only.

* **request_time()**

    Return request start timing metadata when available.

* **base() / base_url()**

    Return URI base information for the current request.

# NOTES #

This adapter also supports WebDyne’s SSE and WebSocket-aware PAGI flows because the parent PAGI runtime passes through `sse` and `ws` helper objects when present.

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


=head1 WebDyne::Request::PAGI


=head1 NAME

WebDyne::Request::PAGI - PAGI request adapter for WebDyne


=head1 SYNOPSIS


 use WebDyne::Request::PAGI;
 
 my $wr = WebDyne::Request::PAGI->new(
     scope => $scope,
     req   => $pagi_request,
     res   => $pagi_response,
 );

=head1 DESCRIPTION

C<WebDyne::Request::PAGI> adapts PAGI request state to the normalized request API expected by WebDyne.

Like the PSGI adapter, it can derive a target filename from the request path, configured document root, and default document settings. It also exposes PAGI-specific request information such as scope-based protocol details, body access, form/query parameters, and request timing through the common WebDyne request surface.


=head1 METHODS

=over

=item *

B<new(%options)>

Construct a PAGI-backed request adapter.



=item *

B<env()>

Return the normalized environment view used by the adapter.



=item *

B<id()>

Return the request identifier if present.



=item *

B<https() / secure()>

Return HTTPS/security state derived from the PAGI request.



=item *

B<server_name() / server_port()>

Return server identity details.



=item *

B<body() / body_handle()>

Read or stream the request body.



=item *

B<headers_in() / headers_out()>

Access request and response headers.



=item *

B<header_only()>

Return whether the current request should emit headers only.



=item *

B<request_time()>

Return request start timing metadata when available.



=item *

B<base() / base_url()>

Return URI base information for the current request.



=back


=head1 NOTES

This adapter also supports WebDyne’s SSE and WebSocket-aware PAGI flows because the parent PAGI runtime passes through C<sse> and C<ws> helper objects when present.


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
