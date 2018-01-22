package WebService::Coincheck::Transfer;
use strict;
use warnings;
use Class::Accessor::Lite (
    ro  => [qw/
        client
    /],
);

sub new {
    my $class  = shift;
    my $client = shift;

    bless {
        client => $client,
    }, $class;
}

sub to_leverage {
    my ($self, %params) = @_;

    my $req_params = {
        amount   => $params{amount},
        currency => $params{currency},
    };

    my $res = $self->client->request(
        'POST' => 'api/exchange/transfers/to_leverage',
        $req_params,
    );

    return $res;
}

sub from_leverage {
    my ($self, %params) = @_;

    my $req_params = {
        amount   => $params{amount},
        currency => $params{currency},
    };

    my $res = $self->client->request(
        'POST' => 'api/exchange/transfers/from_leverage',
        $req_params,
    );

    return $res;
}

1;
