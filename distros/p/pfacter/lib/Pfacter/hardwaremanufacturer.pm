package Pfacter::hardwaremanufacturer;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            if ( -e '/usr/sbin/lsattr' ) {
                open( F, '/usr/sbin/lsattr -l sys0 -E -a modelname 2>/dev/null |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /modelname\s(.*),/ ) { $r = $1; last; }
                }
            }
        };

        /Linux/ && do {
            if ( -e '/usr/sbin/dmidecode' ) {
                local $/;
                $/ = /^Handle \d+x/;

                open( F, '/usr/sbin/dmidecode 2>/dev/null |' );
                my ( @F ) = <F>;
                close( F );

                # Multi-version dmidecode compat
                if ( @F == 1 ) { @F = split( /Handle/, $F[0] ); }

                foreach ( @F ) {
                    if ( /type 1,/ ) {
                        if ( /Manufacturer:\s+(.*)\s+/ ) {
                            $r = $1;

                            $r =~ s/\s+/ /g;
                            $r =~ s/\s+$//g;
                        }
                    }
                }
            }
        };

        /SunOS/ && do {
            if ( -e '/usr/bin/showrev' ) {
                open( F, '/usr/bin/showrev 2>/dev/null |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /Hardware provider:\s+(.*)/ ) {
                        $r = $1; last;
                    }
                }
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
