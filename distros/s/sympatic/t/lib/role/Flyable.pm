package Flyable;
use Sympatic::Role;

method fly () { $self->altitude += 10 }

1;
