package ZeroMQ::Raw::Context;
use strict;
use warnings;
use Carp qw(confess);

sub new {
    my ($class, %args) = @_;
    confess 'ZeroMQ::Raw::Context::new must be passed a "threads" parameter!'
        unless exists $args{threads};

    my $self = bless {}, $class;
    $self->init($args{threads});
    return $self;
}

sub DESTROY {
    my $self = shift;
    if($self->has_valid_context){
        $self->term;
    }
}

1;
