package WebService::Coincheck::Trade;
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
    my ($self, $params) = @_;

    my $req_params = {
        pair => 'btc_jpy',
        %{$params || {}},
    };

    my $res = $self->client->request(
        'GET' => 'api/trades',
        $req_params,
    );

    return $res;
}

1;
