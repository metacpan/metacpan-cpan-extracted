package Pfacter::processor;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            if ( -e '/usr/sbin/lsattr' ) {
                open( F, '/usr/sbin/lsattr -El proc0 |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) { if ( /type\s+(.+?)\s/ ) { $r = $1; last; } }

                $r =~ s/\s+$//;
            }
        };

        /Darwin/ && do {
            if ( -e '/usr/bin/hostinfo' ) {
                open( F, '/usr/bin/hostinfo |' );
                my ( @F )  = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /Processor\stype:\s(.*)/ ) { $r = $1; last; }
                }
            }
        };

        /Linux/ && do {
            if ( -e '/proc/cpuinfo' ) {
                open( F, '/proc/cpuinfo' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /model name\s+:\s+(.+?)$/ ) { $r = $1; last; }
                }

                $r =~ s/\s+$//;
            }
        };

        /SunOS/ && do {
            if ( -e '/usr/sbin/prtdiag' ) {
                open( F, '/usr/sbin/prtdiag |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /SUNW,(.+?)\s+\d+/ ) { $r = $1; last; }
                }
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
