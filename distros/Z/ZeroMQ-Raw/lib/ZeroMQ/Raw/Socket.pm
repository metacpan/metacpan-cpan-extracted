package ZeroMQ::Raw::Socket;
use strict;
use warnings;
use Carp qw(confess);

sub _new {
    my $class = shift;
    return bless {}, $class;
}

sub new {
    my ($class, $context, $type) = @_;
    my $self = $class->_new;
    $self->init_socket($context, $type);
    $self->{context} = $context;
    $self->{type}    = $type;
    return $self;
}

sub DESTROY {
    my $self = shift;
    if($self->is_allocated){
        $self->close;
    }
}

1;
