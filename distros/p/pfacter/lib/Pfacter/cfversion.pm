package Pfacter::cfversion;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX|Linux/ && do {
            if ( -e '/var/cfengine/bin/cfagent' ) {
                open( F, '/var/cfengine/bin/cfagent -V |' );
                foreach ( <F> ) { $r = $1 if /GNU cfengine (\d.*)$/; last; }
                close( F );
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
