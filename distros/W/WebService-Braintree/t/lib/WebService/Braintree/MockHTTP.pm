# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::MockHTTP;

use 5.010_001;
use strictures 1;

use Moo;

has method => (is => 'rw');
has result => (is => 'rw');
has path => (is => 'rw');
has params => (is => 'rw');

sub post {
    my $self = shift;
    $self->path(shift);
    $self->params(shift);
    $self->method('post');
    return $self->result;
}

sub put {
    my $self = shift;
    $self->path(shift);
    $self->params(shift);
    $self->method('put');
    return $self->result;
}

sub get {
    my $self = shift;
    $self->path(shift);
    $self->params(shift);
    $self->method('get');
    return $self->result;
}

sub delete {
    my $self = shift;
    $self->path(shift);
    $self->params(shift);
    $self->method('delete');
    return $self->result;
}

__PACKAGE__->meta->make_immutable;;

1;
__END__
