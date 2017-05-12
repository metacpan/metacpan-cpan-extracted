package Test::Mock::LWP::Conditional;

use 5.008001;
use strict;
use warnings;
use LWP::UserAgent;
use Scalar::Util qw(blessed refaddr);
use Sub::Install qw(install_sub);
use Class::Method::Modifiers qw(install_modifier);
use Math::Random::Secure qw(irand);
use Test::Mock::LWP::Conditional::Stubs;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

our $Stubs = +{ __GLOBAL__ => +{} };
our $Regex = +{ __GLOBAL__ => +{} };

sub _set_stub {
    my ($key, $uri, $res) = @_;

    $Stubs->{$key} ||= +{};

    if (ref $uri eq 'Regexp') {
        my $rng = irand('9999999999999999');
        $Regex->{$key}->{$rng} = $uri;
        $uri = $rng;
    }

    $Stubs->{$key}->{$uri} ||= Test::Mock::LWP::Conditional::Stubs->new;
    $Stubs->{$key}->{$uri}->add($res);
}

sub _get_stub {
    my ($key, $uri) = @_;

    if (exists $Stubs->{$key}) {
        if (exists $Stubs->{$key}->{$uri}) {
            return $Stubs->{$key}->{$uri};
        }
        return _check_regex($key, $uri);
    }
    elsif (exists $Stubs->{__GLOBAL__}->{$uri}) {
        return $Stubs->{__GLOBAL__}->{$uri};
    } else {
        return _check_regex("__GLOBAL__", $uri);
    }
}

sub _check_regex {
    my ($key, $uri) = @_;

    foreach my $marker (keys %{$Regex->{$key}}) {
        if ($uri =~ $Regex->{$key}->{$marker}) {
            return $Stubs->{$key}->{$marker};
        }
    }
}

sub stub_request {
    my ($self, $uri, $res) = @_;
    my $key = blessed($self) ? refaddr($self) : '__GLOBAL__';
    _set_stub($key, $uri, $res);
}

sub reset_all {
    $Stubs = +{ __GLOBAL__ => +{} };
    $Regex = +{ __GLOBAL__ => +{} };
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

=head1 NAME

Test::Mock::LWP::Conditional - stubbing on LWP request

=head1 SYNOPSIS

    use LWP::UserAgent;
    use HTTP::Response;

    use Test::More
    use Test::Mock::LWP::Conditional;

    my $uri = 'http://example.com/';

    # global
    Test::Mock::LWP::Conditional->stub_request($uri => HTTP::Response->new(503));
    is LWP::UserAgent->new->get($uri)->code => 503;

    # lexical
    my $ua = LWP::UserAgent->new;
    $ua->stub_request($uri => sub { HTTP::Response->new(500) });
    is $ua->get($uri)->code => 500;
    is LWP::UserAgent->new->get($uri)->code => 503;

    # reset
    Test::Mock::LWP::Conditional->reset_all;
    is $ua->get($uri)->code => 200;
    is LWP::UserAgent->new->get($uri)->code => 200;

=head1 DESCRIPTION

This module stubs out LWP::UserAgent's request.

=head1 METHODS

=over 4

=item * stub_request($uri, $res)

Sets stub response for requesed URI.

=item * reset_all

Clear all stub requests.

=back

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Mock::LWP>, L<Test::Mock::LWP::Dispatch>, L<Test::MockHTTP>, L<Test::LWP::MockSocket::http>

L<LWP::UserAgent>

L<https://github.com/bblimke/webmock>, L<https://github.com/chrisk/fakeweb>

=cut
