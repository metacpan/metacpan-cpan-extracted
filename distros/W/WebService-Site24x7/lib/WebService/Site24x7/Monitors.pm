package WebService::Site24x7::Monitors;

use Moo;

has client => (is => 'rw', required => 1, handles => [qw/get/]);

sub list {
    my ($self) = @_;
    return $self->get('/monitors')->data;
}

1;
