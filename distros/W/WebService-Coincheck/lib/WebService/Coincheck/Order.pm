package WebService::Coincheck::Order;
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
    my ($self, $params) = @_;

    my $req_params;

    my $res = $self->client->request(
        'POST' => 'api/exchange/orders',
        $req_params,
    );

    return $res;
}

sub cancel {
    my ($self, $params) = @_;

    my $req_params = {
        id => $params->{id},
    };

    my $res = $self->client->request(
        'DELETE' => "api/exchange/orders/$req_params->{id}",
        $req_params,
    );

    return $res;
}

sub opens {
    my ($self, $params) = @_;

    my $req_params;

    my $res = $self->client->request(
        'GET' => 'api/exchange/orders/opens',
        $req_params,
    );

    return $res;
}

sub transactions {
    my ($self, $params) = @_;

    my $req_params;

    my $res = $self->client->request(
        'GET' => 'api/exchange/orders/transactions',
        $req_params,
    );

    return $res;
}

1;
