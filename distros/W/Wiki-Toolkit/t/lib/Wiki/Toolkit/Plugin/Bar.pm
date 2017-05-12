package Wiki::Toolkit::Plugin::Bar;
use base qw( Wiki::Toolkit::Plugin );

sub on_register {
    my $self = shift;
    die unless $self->datastore;
}

1;
