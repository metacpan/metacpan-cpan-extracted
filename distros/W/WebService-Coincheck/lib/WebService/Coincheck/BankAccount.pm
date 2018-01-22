package WebService::Coincheck::BankAccount;
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
        bank_name   => $params{bank_name},
        branch_name => $params{branch_name},
        number      => $params{number},
        name        => $params{name},
    };

    my $res = $self->client->request(
        'POST' => 'api/bank_accounts',
        $req_params,
    );

    return $res;
}

sub all {
    my ($self, %params) = @_;

    my $req_params;

    my $res = $self->client->request(
        'GET' => 'api/bank_accounts',
        $req_params,
    );

    return $res;
}

sub delete {
    my ($self, %params) = @_;

    my $req_params = {
        id => $params{id},
    };

    my $res = $self->client->request(
        'DELETE' => "api/bank_accounts/$req_params->{id}",
        $req_params,
    );

    return $res;
}

1;
