package WWW::Suffit::Plugin::CommonHelpers;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Plugin::CommonHelpers - Common helpers plugin for Suffit API servers

=head1 SYNOPSIS

    # in your startup
    $self->plugin('WWW::Suffit::Plugin::CommonHelpers');

=head1 DESCRIPTION

This plugin is a collection of common helpers for Suffit API servers

=head1 HELPERS

This plugin implements the following helpers

=head2 base_url

    my $url = $c->base_url;

Returns the base URL from request

=head2 client_ip

    my $ip = $c->client_ip;
    my $ip = $c->client_ip([ ..trusted_proxies ...]);

Returns the client IP address

=head2 remote_ip

See L</client_ip>

=head2 reply.error

    return $c->reply->error(); # 500, E0500, "Internal server error"
    return $c->reply->error("Error message"); # 500, E0500, "Error message"
    return $c->reply->error(501 => "Error message");
    return $c->reply->error(501 => "Error code" => "Error message");

The method returns error in client request format

B<NOTE!>: This method with HTML format requires the 'error' template

=head2 reply.json_error

    return $c->reply->json_error(); # 500, E0500, "Internal server error"
    return $c->reply->json_error("Error message"); # 500, E0500, "Error message"
    return $c->reply->json_error(501 => "Error message");
    return $c->reply->json_error(501 => "Error code" => "Error message");

    {
      "code": "Error code",
      "message": "Error message",
      "status": false
    }

The method returns API error as JSON response

=head2 reply.json_ok

    return $c->reply->json_ok(); # 200, ""
    return $c->reply->json_ok("Ok."); # 200, "Ok."
    return $c->reply->json_ok(201 => "Ok."); # 201, "Ok."

    {
      "code": "E0000",
      "message": "Ok.",
      "status": true
    }

    return $c->reply->json_ok({foo => "bar"}); # 200, {...}

    {
      "code": "E0000",
      "foo": "bar",
      "status": true
    }

    return $c->reply->json_ok(201 => {foo => "bar"}); # 201, {...}

    # 201
    {
      "code": "E0000",
      "foo": "bar",
      "status": true
    }

The method returns API success status as JSON response

=head2 reply.noapi

    return $c->reply->noapi(
        status  => 501, # HTTP status code (default: 200)
        code    => "E0501", # The Suffit error code
        message => "Error message",
        data    => {...}, # Payload data
        html    => { template => "error" }, # HTML options
    );

The method returns data in client request format

=head1 METHODS

Internal methods

=head2 register

Do not use directly. It is called by Mojolicious.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '1.00';

use WWW::Suffit::RefUtil qw/ is_array_ref is_hash_ref isnt_void is_int8 /;

sub register {
    my ($self, $app, $opts) = @_; # $self = $plugin
    $opts //= {};

    # JSON API responses
    $app->helper('reply.json_error',    => \&_reply_json_error);
    $app->helper('reply.json_ok'        => \&_reply_json_ok);

    # No JSON API responses
    $app->helper('reply.error'          => \&_reply_error);
    $app->helper('reply.noapi'          => \&_reply_noapi);

    # Get Client/Remote IP address
    $app->helper('client_ip'            => \&_client_ip);
    $app->helper('remote_ip'            => \&_client_ip);

    # Get base URL
    $app->helper('base_url'             => \&_base_url);
}

sub _reply_json_error {
    my $self = shift;
    my $err = pop(@_) // "Internal Server Error";
    my $stt = shift(@_) || 500;
    my $cod = shift(@_);

    # Correct code and message
    unless ($cod) {
        if ($err =~ s/^(E[0-9]{4})[:]?\s+//) {
            $cod = $1;
        }
        $cod ||= "E0$stt";
    }

    # Log
    $self->log->error(sprintf("[%s] %s", $cod, $err)) if length $err;

    # Clean message
    $err =~ s/^(E[0-9]{4})[:]?\s+//;

    # Render
    return $self->render(
        json => {
            status => \0,
            code => $cod,
            length $err ? (message => $err) : (),
        },
        status => $stt,
    );
}
sub _reply_json_ok {
    my $self = shift;
    my $e = pop(@_) // "";
    my $s = pop(@_) // 200;
    my %j = (status => \1, code => 'E0000');
    my %d = ();
    if (is_hash_ref($e)) {
        %d = %$e;
    } elsif($e ne "") {
        $j{message} = $e;
    }
    return $self->render(json => {%j, %d}, status => $s);
}
sub _reply_error {
    my $self = shift;
    my $err = pop(@_) // "Internal Server Error";
    my $stt = shift(@_) // 500;
    my $cod = shift(@_) // undef;
    my $format = $self->helpers->can("exception_format") ? $self->helpers->exception_format : 'html';
    return _reply_noapi($self,
            status  => $stt, # HTTP status code
            code    => $cod, # The Suffit error code
            error   => $err, # Error message
            $format eq 'html' ? (html => {template => 'error', format => 'html'}) : (),
        );
}
sub _reply_noapi {
    my $self = shift;
    my %args = @_;
    my $status  = $args{status} || 200;         # HTTP status code
    my $code    = $args{code} || "E0$status";   # The Suffit error code
    my $message = $args{error} // $args{message} // ''; # Error message
    my $data    = $args{data}; # Payload data
    my $html    = $args{html}; # HTML options

    # Correct code and message
    unless ($args{code}) {
        if ($message =~ s/^(E[0-9]{4})[:]?\s+//) {
            $code = $1;
        }
    }

    # Log
    if ($status >= 400) {
        $self->log->error(sprintf("[%s] %s", $code, $message)) if length $message;
    }

    # Clean message
    $message =~ s/^(E[0-9]{4})[:]?\s+//;

    # Respond (extended render)
    return $self->respond_to(
        json    => {
                    json    => {
                            status => $status < 400 ? \1 : \0,
                            length $message ? (message => $message) : (),
                            code => $code,
                            defined $data ? (is_hash_ref($data) ? (%$data) : is_array_ref($data) ? (data => $data) : ()) : (),
                        },
                    status  => $status,
                },
        html    => {
                    message => $message // '',
                    code    => $code,
                    http_status => $status,
                    defined $html ? (is_hash_ref($html) ? (%$html) : ()) : (),
                    defined $data ? (is_hash_ref($data) ? (%$data) : is_array_ref($data) ? (data => $data) : ()) : (),
                    status  => $status,
                },
        text    => {
                    text    => length $message ? $message : defined $data ? $self->dumper($data) : '',
                    status  => $status,
                },
        any     => {
                    text    => length $message ? $message : defined $data ? $self->dumper($data) : '',
                    status  => $status,
                },
    )
}
sub _client_ip {
    my $self = shift;
    my $trustedproxies = shift;
    $self->req->trusted_proxies($trustedproxies)
        if defined($trustedproxies) && is_array_ref($trustedproxies) && $self->req->can("trusted_proxies");
    return $self->tx->remote_address; # X-Forwarded-For
}
sub _base_url {
    my $self = shift;
    my $base_url = $self->req->url->base->path_query('/')->to_string // '';
       $base_url =~ s/\/+$//;
    return $base_url;
}

1;

__END__
