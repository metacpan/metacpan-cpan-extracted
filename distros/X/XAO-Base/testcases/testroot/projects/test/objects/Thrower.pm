package XAO::DO::Thrower;
use strict;
use base qw(XAO::DO::Atom);

sub method ($) {
    '<Test2>' . (shift) . '</Test2>';
}

sub eat ($$) {
    my ($self,$food)=@_;
    throw $self "($food) - not edible";
}

sub drink ($$) {
    my ($self,$food)=shift;
    throw $self "- drunk already";
}

1;
