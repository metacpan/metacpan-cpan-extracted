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

package WebDyne::Request::Apache;


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


#  mod_perl 2 modules
#
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::Connection ();
use Apache2::Const ();
use Apache2::ServerUtil ();
use APR::Table ();


#  WebDyne modules
#
use WebDyne::Util;
use WebDyne::Constant;
use WebDyne::Request::Common qw(handler_methods_init);
use WebDyne::Request::Fake;


#  Version information
#
$VERSION='3.008';


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

    #  Setup request handler abstraction methods
    #
    my %method=(
        accept_encoding     => undef,
        accept_language     => undef,
        accept              => undef,
        args                => 'args',
        as_string           => undef,
        authority           => undef,
        authorization       => undef,
        auth_type           => \&auth_type,
        base                => undef,
        base_url            => undef,
        body_handle         => \&body_handle,
        body                => \&body,
        cache_control       => undef,
        charset             => undef,
        cleanup_register    => undef,
        client_address      => \&remote_address,
        content             => \&body,
        content_encoding    => \&content_encoding,
        content_length      => \&content_length,
        content_type        => \&content_type,
        cookies             => undef,
        cookie              => undef,
        custom_response     => undef,
        cwd                 => undef,
        dir_config          => undef,
        document_root       => 'document_root',
        env                 => \&env,
        etag                => undef,
        #filename            => 'filename',
        filename            => \&filename,
        finalize            => undef,
        finfo               => undef,
        form_parameters     => undef,
        forwarded_for       => undef,
        fragment            => undef,
        handler             => 'handler',
        header              => \&headers_in,
        headers             => \&headers_in,
        header_only         => 'header_only',
        headers_in          => \&headers_in,
        headers_out         => \&headers_out,
        hostname            => 'hostname',
        host                => \&host,
        https               => \&https,
        http_version        => 'protocol',
        id                  => \&id,
        if_modified_since   => undef,
        if_none_match       => undef,
        input               => \&body_handle,
        is_ajax             => undef,
        is_main             => undef,
        location            => undef,
        log_error           => undef,
        lookup_file         => 'lookup_file',
        lookup_uri          => 'lookup_uri',
        main                => undef,
        media_type          => undef,
        method              => 'method',
        mtime               => undef,
        multipart_parameters=> undef,
        next                => undef,
        notes               => 'notes',
        origin              => undef,
        output_filters      => undef,
        path_info           => sub { shift()->uri->path },
        #path_info           => 'path_info',
        path_parameters     => undef,
        path                => \&path_info,
        pool                => 'pool',
        preferred_charset   => undef,
        preferred_encoding  => undef,
        preferred_language  => undef,
        preferred_media_type=> undef,
        prev                => undef,
        print               => 'print',
        protocol            => 'protocol',
        query_parameters    => undef,
        query_string        => 'args',
        redirect            => undef,
        referer             => undef,
        register_cleanup    => undef,
        remote_address      => \&remote_address,
        remote_host         => \&remote_host,
        remote_port         => \&remote_port,
        remote_user         => 'user',
        request_time        => 'request_time',
        route               => undef,
        run                 => undef,
        scheme              => \&scheme,
        script_name         => undef,
        secure              => \&https,
        sendfile            => undef,
        send_http_header    => undef,
        server_name         => \&server_name,
        server_port         => \&server_port,
        session_id          => undef,
        session             => undef,
        set_handlers        => 'set_handlers',
        status_line         => 'status_line',
        status              => 'status',
        unparsed_uri        => 'unparsed_uri',
        uploads             => undef,
        uri                 => \&uri,
        url                 => \&uri,
        user_agent          => undef,
        user                => 'user',
        write               => undef,
        err_html            => undef,
        DESTROY             => \&DESTROY
    );


    #  Make handler methods
    #
    foreach my $handler (qw(req res)) {
        *{$handler}=sub { return shift()->{$handler} };
    }
    
    
    #  Now create everything and check
    #
    return handler_methods_init(__PACKAGE__, 'Apache2::RequestRec', \%method);
    
}


sub new {


    #  New Apache request
    #
    my ($class, $r, %opt)=@_;
    debug("$class, r: %s, opt:%s, calller:%s", Dumper($r, \%opt, [caller(0)]));


    #  Require Apache request record
    #
    $r || return err('no Apache request supplied');


    #  Finished, pass back
    #
    return bless { req => $r, %opt }, $class;

}


sub filename {

    #  Can be overridden by DOCUMENT_ROOT environment var
    #
    return $ENV{'DOCUMENT_ROOT'} || shift()->{'req'}->filename();
    
}


sub _headers {

    my ($r, $direction, @param)=@_;
    debug("r: $r, direction: $direction: param: %s", Dumper(\@param));
    my $table=$r->{'req'}->$direction();
    if (@param == 1) {
        #return  $table->get($param[0]);
        return $table->{$param[0]};
    }
    elsif (@param > 1) {
         while (my ($k, $v) = splice(@param, 0, 2)) {
            $table->set($k => $v);
        }
        return $r;
    }
    else {
        my $headers_or=HTTP::Headers::Fast->new();
        $table->do(sub { $headers_or->header($_[0] => $_[1]); return 1; });
        return $headers_or;
    }
}
 

sub headers_in {
    shift()->_headers('headers_in', @_);
}   


sub headers_out {
    shift()->_headers('headers_out', @_);
}   


sub content_type {
    my $r=shift();
    return @_ ? $r->{'req'}->content_type(@_) : $r->{'req'}->content_type();
}


sub content_length {
    my $r=shift();
    return @_ ? $r->headers_out('Content-Length', shift()) : $r->headers_in('Content-Length');
}


sub content_encoding {
    my $r=shift();
    return @_ ? $r->headers_out('Content-Encoding', shift()) : $r->headers_in('Content-Encoding');
}


sub host {
    my $r=shift();
    return $r->headers_in('Host');
}


sub server_name {
    my $r=shift();
    return $r->{'req'}->can('get_server_name') ? $r->{'req'}->get_server_name() : $r->{'req'}->hostname();
}


sub server_port {
    my $r=shift();
    if ($r->{'req'}->can('get_server_port')) {
        return $r->{'req'}->get_server_port();
    }
    if (my $conn=$r->{'req'}->connection()) {
        return $conn->local_addr->port if $conn->can('local_addr');
    }
    return undef;
}


sub remote_address {
    my $r=shift();
    my $req=$r->{'req'};
    if (my $conn=$req->connection()) {
        return $conn->client_ip if $conn->can('client_ip');
        return $conn->remote_ip if $conn->can('remote_ip');
        if ($conn->can('remote_addr')) {
            my $addr=$conn->remote_addr;
            return $addr->ip_get if ($addr && $addr->can('ip_get'));
        }
    }
    return $req->subprocess_env('REMOTE_ADDR') if $req->can('subprocess_env');
}


sub remote_host {
    my $r=shift();
    my $req=$r->{'req'};
    if ($req->can('get_remote_host')) {
        return $req->get_remote_host(Apache2::Const::REMOTE_NAME());
    }
    return $r->remote_address();
}


sub remote_port {
    my $r=shift();
    my $req=$r->{'req'};
    if (my $conn=$req->connection()) {
        return $conn->client_port if $conn->can('client_port');
        if ($conn->can('client_addr')) {
            my $addr=$conn->client_addr;
            return $addr->port if ($addr && $addr->can('port'));
        }
        return $conn->remote_port if $conn->can('remote_port');
        if ($conn->can('remote_addr')) {
            my $addr=$conn->remote_addr;
            return $addr->port if ($addr && $addr->can('port'));
        }
    }
    return $req->subprocess_env('REMOTE_PORT') if $req->can('subprocess_env');
    return undef;
}


sub auth_type {
    my $r=shift();
    return $r->{'req'}->can('ap_auth_type') ? $r->{'req'}->ap_auth_type() : $r->{'req'}->auth_type();
}


sub https {
    my $r=shift();
    return (($r->headers_in('HTTPS') || $r->{'req'}->subprocess_env('HTTPS') || '') eq 'on');
}


sub scheme {
    my $r=shift();
    return $r->{'req'}->subprocess_env('REQUEST_SCHEME') ||
        ($r->https() ? 'https' : 'http');
}


sub id {
    return shift()->{'req'}->subprocess_env('UNIQUE_ID')
}


sub env {
    my $r=shift();
    my $table=$r->{'req'}->subprocess_env();
    my %env;
    $table->do(sub { $env{$_[0]}=$_[1]; return 1; });
    return \%env;
}


sub body {
    my $r=shift();
    return $r->{'body'} if exists $r->{'body'};
    my $len=$r->content_length() || 0;
    return $r->{'body'}='' unless $len;
    my $buf='';
    my $read=0;
    while ($read < $len) {
        my $chunk='';
        my $n=$r->{'req'}->read($chunk, $len-$read);
        last unless $n;
        $read += $n;
        $buf.=$chunk;
    }
    return $r->{'body'}=$buf;
}


sub body_handle {

    my $r=shift();
    unless ($r->{'input'}) {
        no warnings qw(once);
        #$r->{'input'}=tie *BODY, WebDyne::Request::Apache::Body_Handle, $r->{'req'};
        tie *BODY, WebDyne::Request::Apache::Body, $r->{'req'};
        $r->{'input'}=*BODY;
        
    }
    return $r->{'input'};
}



sub uri {
    #return URI->new(shift()->{'req'}->uri);
    my $r=shift();
    my $uri_or=URI->new();
    $uri_or->scheme($r->scheme);
    $uri_or->host($r->server_name);
    $uri_or->port($r->server_port);
    $uri_or->path($r->{'req'}->uri);
    $uri_or->query($r->{'req'}->args);
    return $uri_or->canonical;
}


sub DESTROY {

    my $r=shift();
    untie $r->{'input'} if $r->{'input'};
    
}

1;


#  TieHandle package to link mod_perl body to a handle
#
package WebDyne::Request::Apache::Body;

sub TIEHANDLE {
    my ($class, $r) = @_;
    bless {
        req    => $r,
        buffer => '',
        eof    => 0,
    }, $class;
}

sub READ {
    my ($self, undef, $len, $offset) = @_;
    my $buf = '';
    my $read = $self->{req}->read($buf, $len);
    return 0 unless $read;
    substr($_[1], $offset || 0) = $buf;
    return $read;
}

sub READLINE {
    my ($self) = @_;
    return undef if $self->{eof};
    my $line = '';
    while (1) {

        # check existing buffer
        if ($self->{buffer} =~ s/(.*?\n)//s) {
            return $1;
        }

        # read more data
        my $chunk = '';
        my $n = $self->{req}->read($chunk, 8192);

        unless ($n) {
            $self->{eof} = 1;
            return length($self->{buffer})
                ? delete $self->{buffer}
                : undef;
        }

        $self->{buffer} .= $chunk;
    }
}

sub EOF {
    my ($self) = @_;
    return $self->{eof} && $self->{buffer} eq '';
}

sub CLOSE {
    return 1;
}

1;

__END__

=begin markdown

# WebDyne::Request::Apache #

# NAME #

WebDyne::Request::Apache - Apache mod_perl request adapter for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Request::Apache;

my $wr = WebDyne::Request::Apache->new($apache_request_rec);
```

# DESCRIPTION #

`WebDyne::Request::Apache` adapts an `Apache2::RequestRec` object to the normalized request interface expected by the main WebDyne handler.

It maps Apache request data into WebDyne-style methods and provides body-handle support, environment access, header accessors, URI handling, and selected convenience wrappers over mod_perl request record methods.

# METHODS #

* **new($r, %options)**

    Wrap an Apache request record.

* **filename()**

    Return the effective filename for the request. This honors the `DOCUMENT_ROOT` environment override used by some WebDyne flows.

* **headers_in() / headers_out()**

    Access request and response headers through the adapter.

* **content_type() / content_length() / content_encoding()**

    Access common content metadata.

* **host() / server_name() / server_port()**

    Access host and server details.

* **remote_address() / remote_host() / remote_port()**

    Access client network details.

* **body() / body_handle()**

    Read request body content or return a handle-like interface for streaming reads.

* **uri()**

    Return a `URI` object for the current request.

# NOTES #

The module initializes many additional normalized methods by delegating through `WebDyne::Request::Common`. Methods not implemented directly are filled by adapter dispatch or inherited fallback behavior.

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


=head1 WebDyne::Request::Apache


=head1 NAME

WebDyne::Request::Apache - Apache mod_perl request adapter for WebDyne


=head1 SYNOPSIS


 use WebDyne::Request::Apache;
 
 my $wr = WebDyne::Request::Apache->new($apache_request_rec);

=head1 DESCRIPTION

C<WebDyne::Request::Apache> adapts an C<Apache2::RequestRec> object to the normalized request interface expected by the main WebDyne handler.

It maps Apache request data into WebDyne-style methods and provides body-handle support, environment access, header accessors, URI handling, and selected convenience wrappers over mod_perl request record methods.


=head1 METHODS

=over

=item *

B<new($r, %options)>

Wrap an Apache request record.



=item *

B<filename()>

Return the effective filename for the request. This honors the C<DOCUMENT_ROOT> environment override used by some WebDyne flows.



=item *

B<headers_in() / headers_out()>

Access request and response headers through the adapter.



=item *

B<content_type() / content_length() / content_encoding()>

Access common content metadata.



=item *

B<host() / server_name() / server_port()>

Access host and server details.



=item *

B<remote_address() / remote_host() / remote_port()>

Access client network details.



=item *

B<body() / body_handle()>

Read request body content or return a handle-like interface for streaming reads.



=item *

B<uri()>

Return a C<URI> object for the current request.



=back


=head1 NOTES

The module initializes many additional normalized methods by delegating through C<WebDyne::Request::Common>. Methods not implemented directly are filled by adapter dispatch or inherited fallback behavior.


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
