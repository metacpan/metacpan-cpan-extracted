package WebService::Mocean::Report;

use Moo;
use Types::Standard qw(InstanceOf);

our $VERSION = '0.05';

has client => (
    is => 'rw',
    isa => InstanceOf['WebService::Mocean::Client'],
    required => 1,
);

sub get_message_status {
    my ($self, $params) = @_;

    return $self->client->request('report/message', $params, 'get');
}

1;
