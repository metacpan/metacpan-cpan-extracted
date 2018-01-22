package WebService::Coincheck::Deposit;
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

sub all {
    my ($self, %params) = @_;

    my $req_params = {
        currency => 'BTC',
        %params,
    };

    my $res = $self->client->request(
        'GET' => 'api/deposit_money',
        $req_params,
    );

    return $res;
}

sub fast {
    my ($self, %params) = @_;

    my $req_params = {
        id => $params{id},
    };

    my $res = $self->client->request(
        'POST' => "api/deposit_money/$req_params->{id}/fast",
        $req_params,
    );

    return $res;
}

1;
