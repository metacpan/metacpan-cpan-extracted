#line 1
package Test::Mock::LWP::Conditional;

use 5.008001;
use strict;
use warnings;
use LWP::UserAgent;
use Scalar::Util qw(blessed refaddr);
use Sub::Install qw(install_sub);
use Class::Method::Modifiers qw(install_modifier);
use Test::Mock::LWP::Conditional::Stubs;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

our $Stubs = +{ __GLOBAL__ => +{} };

sub _set_stub {
    my ($key, $uri, $res) = @_;

    $Stubs->{$key} ||= +{};
    $Stubs->{$key}->{$uri} ||= Test::Mock::LWP::Conditional::Stubs->new;

    $Stubs->{$key}->{$uri}->add($res);
}

sub _get_stub {
    my ($key, $uri) = @_;

    if (exists $Stubs->{$key} && exists $Stubs->{$key}->{$uri}) {
        return $Stubs->{$key}->{$uri};
    }
    elsif (exists $Stubs->{__GLOBAL__}->{$uri}) {
        return $Stubs->{__GLOBAL__}->{$uri};
    }
}

sub stub_request {
    my ($self, $uri, $res) = @_;
    my $key = blessed($self) ? refaddr($self) : '__GLOBAL__';
    _set_stub($key, $uri, $res);
}

sub reset_all {
    $Stubs = +{ __GLOBAL__ => +{} };
}

{ # LWP::UserAgent injection
    install_modifier('LWP::UserAgent', 'around', 'simple_request', sub {
        my $orig = shift;
        my ($self, $req, @rest) = @_;

        my $stub = _get_stub(refaddr($self), $req->uri);
        return $stub ? $stub->execute($req) : $orig->(@_);
    });

    install_sub({
        code => __PACKAGE__->can('stub_request'),
        into => 'LWP::UserAgent',
        as   => 'stub_request',
    });
}

1;

#line 129
