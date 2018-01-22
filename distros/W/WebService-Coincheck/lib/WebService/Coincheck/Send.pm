package WebService::Coincheck::Send;
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

sub create {
    my ($self, %params) = @_;

    my $req_params = {
        address => $params{address},
        amount  => $params{amount},
    };

    my $res = $self->client->request(
        'POST' => 'api/send_money',
        $req_params,
    );

    return $res;
}

sub all {
    my ($self, %params) = @_;

    my $req_params = {
        currency => $params{currency},
    };

    my $res = $self->client->request(
        'GET' => 'api/send_money',
        $req_params,
    );

    return $res;
}

1;
