package oCLI::View::Text;
use Moo;

sub render {
    my ( $self, $c ) = @_;

    print $c->stash->{text};
}

1;
