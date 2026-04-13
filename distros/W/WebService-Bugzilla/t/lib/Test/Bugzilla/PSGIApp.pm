#!perl
# ABSTRACT: PSGI mock server for Bugzilla API testing

package Test::Bugzilla::PSGIApp;

use v5.24;
use strict;
use warnings;
use HTTP::Response;
use JSON::MaybeXS qw(encode_json decode_json);

sub new {
    my ($class, %opts) = @_;
    return bless {routes => {}, default_response => [200, ['Content-Type' => 'application/json'], ['{}']]}, $class;
}

sub set_route {
    my ($self, $method, $path, $response) = @_;
    $self->{routes}{"$method:$path"} = $response;
}

sub set_error {
    my ($self, $method, $path, $code, $message) = @_;
    $self->{routes}{"$method:$path"} = {
        error   => 1,
        code    => $code,
        message => $message,
    };
}

sub set_default {
    my ($self, $code, $body) = @_;
    $self->{default_response} = [$code, ['Content-Type' => 'application/json'], [$body // '{}']];
}

sub clear_routes {
    my ($self) = @_;
    $self->{routes} = {};
}

sub _handle_request {
    my ($self) = @_;

    return sub {
        my ($env) = @_;

        my $method = $env->{REQUEST_METHOD};
        my $path   = $env->{PATH_INFO};
        my $key    = "$method:$path";
        my $route  = $self->{routes}{$key};

        if (!$route) {
            for my $pattern (keys %{$self->{routes}}) {
                if (my @matches = ($key =~ /$pattern/)) {
                    $route = $self->{routes}{$pattern};
                    last;
                }
            }
        }

        if (!$route) {
            return $self->{default_response};
        }

        if ($route->{error}) {
            my $code = $route->{code};
            my $msg  = $route->{message} // 'Error';
            my $body = encode_json({error => 1, message => $msg});
            return [$code, ['Content-Type' => 'application/json'], [$body]];
        }

        if ($route->{empty}) {
            return [200, ['Content-Type' => 'application/json'], ['']];
        }

        if ($route->{invalid_json}) {
            return [200, ['Content-Type' => 'application/json'], ['{not valid json}']];
        }

        my $body = ref $route eq 'CODE' ? $route->($env) : $route;
        return [200, ['Content-Type' => 'application/json'], [encode_json($body)]];
    };
}

sub app {
    my ($self) = @_;
    return $self->_handle_request;
}

1;

__END__

=head1 SYNOPSIS

    use t::lib::PSGIApp;
    use LWP::Protocol::PSGI;

    my $mock = PSGIApp->new;
    $mock->set_route('GET', '/rest/bug/123', { bugs => [{ id => 123, summary => 'Test' }] });
    $mock->set_error('GET', '/rest/bug/999', 404, 'Bug not found');

    LWP::Protocol::PSGI->register($mock->app);

    my $bz = WebService::Bugzilla->new(base_url => 'http://localhost/rest', api_key => 'test');
    my $bug = $bz->bug->get(123);

=head1 DESCRIPTION

PSGI application that simulates Bugzilla API responses for testing.

=cut
