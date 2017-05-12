package Log::Message::Handlers;
use strict;

sub log { 1 }

sub carp {
    my $self = shift;
    warn join " ", $self->message, $self->shortmess, 'at', $self->when, "\n";
}

sub croak {
    my $self = shift;
    die join " ", $self->message, $self->shortmess, 'at', $self->when, "\n";
}

sub cluck {
    my $self = shift;
    warn join " ", $self->message, $self->longmess, 'at', $self->when, "\n";
}

sub confess {
    my $self = shift;
    die join " ", $self->message, $self->longmess, 'at', $self->when, "\n";
}

sub die  { die  shift->message; }


sub warn { warn shift->message; }


sub trace {
    my $self = shift;

    for my $item( $self->parent->retrieve( chrono => 0 ) ) {
        $item->cluck;
    }
}

1;

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
