# lib/Trickster/Middleware/CORS.pm
package Trickster::Middleware::CORS;

use strict;
use warnings;
use v5.14;

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(
    origins methods headers credentials max_age expose_headers
);

sub prepare_app {
    my $self = shift;

    $self->origins(['*'])       unless $self->origins;
    $self->methods(['GET','POST','PUT','PATCH','DELETE','OPTIONS'])
                                unless $self->methods;
    $self->headers(['Content-Type','Authorization','X-Requested-With'])
                                unless $self->headers;
    $self->max_age(86400)       unless defined $self->max_age;
    $self->credentials(0)       unless defined $self->credentials;
}

sub call {
    my ($self, $env) = @_;

    # Always handle preflight
    if ($env->{REQUEST_METHOD} eq 'OPTIONS') {
        return $self->_preflight_response($env);
    }

    my $res = $self->app->($env);

    # Add CORS headers to normal responses
    return $self->response_cb($res, sub {
        my $r = shift;
        return unless ref($r) eq 'ARRAY' && ref($r->[1]) eq 'ARRAY';
        $self->_add_cors_headers($r->[1], $env);
    });
}

sub _preflight_response {
    my ($self, $env) = @_;
    my @headers = ('Content-Length' => 0);
    $self->_add_cors_headers(\@headers, $env, 1);  # 1 = preflight
    return [200, \@headers, []];
}

sub _add_cors_headers {
    my ($self, $headers, $env, $is_preflight) = @_;
    my $origin = $env->{HTTP_ORIGIN} || '';
    my $allowed = $self->_origin_allowed($origin) or return;

    push @$headers,
        'Access-Control-Allow-Origin' => $allowed;

    push @$headers, 'Access-Control-Allow-Credentials' => 'true'
        if $self->credentials;

    if ($is_preflight) {
        push @$headers,
            'Access-Control-Allow-Methods' => join(', ', @{$self->methods}),
            'Access-Control-Allow-Headers' => join(', ', @{$self->headers}),
            'Access-Control-Max-Age'       => $self->max_age;
    }

    if ($self->expose_headers && @{$self->expose_headers}) {
        push @$headers,
            'Access-Control-Expose-Headers' => join(', ', @{$self->expose_headers});
    }
}

sub _origin_allowed {
    my ($self, $origin) = @_;
    return '' unless $origin;

    for my $allowed (@{$self->origins}) {
        if ($allowed eq '*') {
            return $origin eq 'null' ? '*' : $origin;
        }
        if (ref($allowed) eq 'Regexp') {
            return $origin if $origin =~ $allowed;
        }
        return $origin if $origin eq $allowed;
    }
    return '';
}

1;