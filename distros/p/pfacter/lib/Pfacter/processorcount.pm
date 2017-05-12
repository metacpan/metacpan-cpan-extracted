package Pfacter::processorcount;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            if ( -e '/usr/sbin/lsdev' ) {
                open( F, '/usr/sbin/lsdev -Cc processor |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) { $r++ if /Available/; }
            }
        };

        /FreeBSD/ && do {
            if ( -e '/sbin/dmesg' ) {
                open( F, '/sbin/dmesg |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) { $r++ if /^CPU/; }
            }
        };

        /Linux/ && do {
            if ( -e '/proc/cpuinfo' ) {
                open( F, '/proc/cpuinfo' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) { $r++ if /processor\s+:\s+(\d+)/; }
            }
        };

        /SunOS/ && do {
            if ( -e '/usr/sbin/psrinfo' ) {
                open( F, '/usr/sbin/psrinfo |' );
                my ( @F ) = <F>;
                close( F );

                $r = scalar @F;
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
