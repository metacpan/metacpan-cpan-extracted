package WebService::Coincheck::Leverage;
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

sub info {
    my ($self, $params) = @_;

    my $req_params;

    my $res = $self->client->request(
        'GET' => 'api/exchange/leverage/positions',
        $req_params,
    );

    return $res;
}

1;