package ZeroMQ::Raw::Message;
use strict;
use warnings;
use Carp qw(confess);

sub _new {
    my $class = shift;
    return bless {}, $class;
}

sub new {
    my ($class) = @_;
    my $self = $class->_new;
    $self->init;
    return $self;
}

sub new_from_size {
    my ($class, $size) = @_;
    confess "size must be greater than zero, not '$size'"
        unless $size > 0;

    my $self = $class->_new;
    $self->init_size($size);
    return $self;
}

sub new_from_scalar {
    my $class = shift;
    my $self = $class->_new;
    $self->init_data($_[0]);
    return $self;
}

sub DESTROY {
    my $self = shift;
    if($self->is_allocated){
        $self->close;
    }
}

1;
