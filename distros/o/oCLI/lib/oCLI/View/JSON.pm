package oCLI::View::JSON;

sub render {
    my ( $self, $c ) = @_;

    print $c->stash->{json};
}

1;
