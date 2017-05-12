package YAML::Perl::Processor;
use YAML::Perl::Base -base;

field 'opened' => 0;
field 'closed' => 0;

# Every class in the stack should have an open and close method.
# They should only allow an object to be opened once.
sub open {
    my $self = shift;
    my $class = ref($self);
    throw "Can't open an already opened $class object"
      if $self->opened;
    throw "Can't open an already closed $class object"
      if $self->closed;
    my $next_layer = $self->next_layer;
    $self->$next_layer->open(@_)
      if $next_layer;
    $self->opened(1);
    return $self;
}

sub close {
    my $self = shift;
    my $class = ref($self);
    throw "Can't close an unopened $class object"
      unless $self->opened;
    throw "Can't close an already closed $class object"
      if $self->closed;
    my $next_layer = $self->next_layer;
    $self->$next_layer->close(@_)
      if $next_layer;
    $self->closed(1);
    return 1;
}

1;
