package Pfacter::fqdn;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    if ( $p->{'hostname'} && $p->{'domain'} ) {
        return( $p->{'hostname'} . '.' . $p->{'domain'} );
    }
    else {
        return( 0 );
    }
}

1;
