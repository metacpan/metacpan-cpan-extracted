package WebService::Coincheck::Withdraw;
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
        bank_account_id => $params{bank_account_id},
        amount          => $params{amount},
        currency        => $params{currency} || 'JPY',
    };

    my $res = $self->client->request(
        'POST' => 'api/withdraws',
        $req_params,
    );

    return $res;
}

sub all {
    my ($self, %params) = @_;

    my $req_params;

    my $res = $self->client->request(
        'GET' => 'api/withdraws',
        $req_params,
    );

    return $res;
}

sub cancel {
    my ($self, %params) = @_;

    my $req_params = {
        id => $params{id},
    };

    my $res = $self->client->request(
        'DELETE' => "api/withdraws/$req_params->{id}",
        $req_params,
    );

    return $res;
}

1;