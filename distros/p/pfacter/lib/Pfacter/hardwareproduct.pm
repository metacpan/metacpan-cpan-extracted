package Pfacter::hardwareproduct;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /Darwin/ && do {
            if ( -e '/usr/sbin/system_profiler' ) {
                open( F, '/usr/sbin/system_profiler SPHardwareDataType |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /Machine Name\:\s+(.+?)$/ ) { $r = $1; last; }
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
                        if ( /Product Name:\s+(.*)\s+/ ) {
                            $r = $1;

                            $r =~ s/\s+/ /g;
                            $r =~ s/\s+$//g;
                        }
                    }
                }
            }
        };

        /SunOS/ && do {
            if ( -e '/usr/bin/uname' ) {
                $r = qx( /bin/uname -i );
                $r = $1 if /^.+?,(.*)$/;
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
