package WebService::Coincheck::Account;
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

sub balance {
    my ($self, $params) = @_;

    my $req_params;

    my $res = $self->client->request(
        'GET' => 'api/accounts/balance',
        $req_params,
    );

    return $res;
}

sub leverage_balance {
    my ($self, $params) = @_;

    my $req_params;

    my $res = $self->client->request(
        'GET' => 'api/accounts/leverage_balance',
        $req_params,
    );

    return $res;
}

sub info {
    my ($self, $params) = @_;

    my $req_params;

    my $res = $self->client->request(
        'GET' => 'api/accounts',
        $req_params,
    );

    return $res;
}

1;
