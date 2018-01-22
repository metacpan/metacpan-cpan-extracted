package WebService::Coincheck::Borrow;
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
        amount   => $params{amount},
        currency => $params{currency},
    };

    my $res = $self->client->request(
        'POST' => 'api/lending/borrows',
        $req_params,
    );

    return $res;
}

sub matches {
    my ($self, %params) = @_;

    my $req_params;

    my $res = $self->client->request(
        'GET' => 'api/lending/borrows/matches',
        $req_params,
    );

    return $res;
}

sub repay {
    my ($self, %params) = @_;

    my $req_params = {
        id => $params{id},
    };

    my $res = $self->client->request(
        'POST' => "api/lending/borrows/$req_params->{id}/repay",
        $req_params,
    );

    return $res;
}

1;
