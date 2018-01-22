package WebService::BitFlyer;
use strict;
use warnings;
use Carp qw/croak/;
use HTTP::Tiny;
use URI::Query;
use Digest::SHA qw/hmac_sha256_hex/;
use JSON qw//;
use Class::Accessor::Lite (
    ro  => [qw/
        api_base
        access_key
        secret_key
    /],
    rw  => [qw/
        client
        sign
        timestamp
        decode_json
        api
    /],
);

use WebService::BitFlyer::API;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my %args  = @_;

    if (!$args{access_key} || !$args{secret_key}) {
        croak "require 'access_key' and 'secret_key'.";
    }

    my $self = bless {
        decode_json => 0,
        api_base    => 'https://api.bitflyer.jp',
        %args,
    }, $class;

    $self->_initialize($args{client_opt});

    return $self;
}

sub _initialize {
    my ($self, $client_opt) = @_;

    $self->client(
        HTTP::Tiny->new(
            agent   => __PACKAGE__ . "/$VERSION",
            default_headers => {
                'Content-Type' => 'application/json',
                'ACCESS-KEY'   => $self->access_key,
            },
            timeout => 15,
            verify_SSL => 1,
            %{$client_opt || {}},
        )
    );

    $self->api(WebService::BitFlyer::API->new($self));
}

sub set_sign {
    my ($self, $method, $req_path, $body) = @_;

    $self->timestamp(time);
    $self->sign(hmac_sha256_hex($self->timestamp . $method . $req_path . ($body || ''), $self->secret_key));
}

sub request {
    my ($self, $method, $req_path, $query) = @_;

    $method = uc $method;

    my $res;

    if ($method eq 'GET') {
        my $query_string = URI::Query->new($query)->stringify;
        $query_string = $query_string ? "?$query_string" : '';
        $self->set_sign($method, $req_path . $query_string);
        my $req_url = join '', $self->api_base, $req_path, $query_string;
        $res = $self->client->get(
            $req_url,
            {
                headers => {
                    'ACCESS-TIMESTAMP' => $self->timestamp,
                    'ACCESS-SIGN'      => $self->sign,
                },
            },
        );
    }
    elsif ($method =~ m!^(?:POST|DELETE)$!) {
        my $content = $query ? JSON::encode_json($query) : '';
        $self->set_sign($method, $req_path, $content);
        my $req_url = join '', $self->api_base, $req_path;
        $res = $self->client->request(
            $method,
            $req_url,
            {
                content => $content,
                headers => {
                    'ACCESS-TIMESTAMP' => $self->timestamp,
                    'ACCESS-SIGN'      => $self->sign,
                },
            },
        );
    }

    unless ($res->{success}) {
        croak "Error:" . join "\t", map { $res->{$_} } (qw/url status reason content/);
    }

    if ($self->decode_json) {
        return JSON::decode_json($res->{content});
    }
    else {
        return $res->{content};
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

WebService::BitFlyer - one line description


=head1 SYNOPSIS

    use WebService::BitFlyer;

    my $bf = WebService::BitFlyer->new(
        access_key => 'ACCESS_KEY',
        secret_key => 'SECRET_KEY',
    );

    $bf->api->markets;

    $bf->api->order(
      child_order_type => 'LIMIT',
      side             => 'BUY',
      price            => 1000000,
      size             => 0.001,
    );

    $bf->api->cancel_order(
      child_order_acceptance_id => 'JRF*****',
    );


=head1 DESCRIPTION

WebService::BitFlyer is the Perl libraries for L<https://bitflyer.jp/> API


=head1 METHODS

=head2 new

the constructor

=head2 set_sign

generate signature

=head2 request

calling API


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/WebService-BitFlyer"><img src="https://secure.travis-ci.org/bayashi/WebService-BitFlyer.png"/></a>

=end html

WebService::BitFlyer is hosted on github: L<http://github.com/bayashi/WebService-BitFlyer>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<https://bitflyer.jp/>

L<https://lightning.bitflyer.jp/docs>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
