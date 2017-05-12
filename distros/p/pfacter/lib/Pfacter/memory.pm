package Pfacter::memory;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            if ( -e '/usr/sbin/lscfg' ) {
                local $/;
                $/ = /Memory DIMM/;

                open( F, '/usr/sbin/lscfg -vp mem0 2>/dev/null |' );
                my ( @F ) = <F>;
                close( F );

                my ( @i );

                foreach ( @F ) {
                    if ( /DIMM/ ) {
                        my ( $l, $m );
                        
                        if ( /Size\.+(\d+)/ ) { $m = $1; }
                        if ( /Location:\s.*-C(.*)/ ) { $l = $1 }

                        $m .= 'm';

                        push @i, "$l=$m";
                    }
                }

                $r = join ' ', sort { $a <=> $b } @i;
            }
        };

        /Darwin/ && do {
            if ( -e '/usr/sbin/system_profiler') {
                open( F, '/usr/sbin/system_profiler SPMemoryDataType |' );
                my ( @F ) = <F>;
                close( F );

                my ( $l, $m, @i );

                foreach ( @F ) {
                    if ( /DIMM(\d+)\// )     { $l = $1; }
                    if ( /Size:\s+(.*)\s+/ ) { $m = $1; }

                    if ( defined( $l ) && defined( $m ) ) {
                        $m =~ s/MB/m/;
                        $m =~ s/GB/g/;

                        $m =~ s/\s+//g;

                        push @i, "$l=$m";

                        undef( $l );
                        undef( $m );
                    }
                }

                $r = join ' ', sort { $a <=> $b } @i;
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

                my ( @i );

                foreach ( @F ) {
                    my ( $l, $m );

                    if ( /Size:\s+(.*)\s+/ ) { $m = $1; }
                    if ( /Locator:.*(\d+)/ ) { $l = $1; }

                    next unless ( ( $l gt -1 ) && ( $m =~ /\d/ ) );

                    $m =~ s/MB/m/;
                    $m =~ s/GB/g/;

                    $m =~ s/\s+//g;

                    push @i, "$l=$m";
                }

                $r = join ' ', sort { $a <=> $b } @i;
            }
        };

        /SunOS/ && do {
            if ( -e '/usr/sbin/prtdiag' ) {
                open( F, '/usr/sbin/prtdiag 2>/dev/null |' );
                my ( @F ) = <F>;
                close( F );

                my ( @i );

                foreach ( @F ) {
                    if ( /^(\d+)\s{6,8}(0|1)\s+(0|1)\s+(.+?)\s+/ ) {
                        my $l = $1;
                        my $m = $4;

                        $m =~ s/MB/m/;
                        $m =~ s/GB/g/;

                        push @i, "$l=$m";
                    }
                }

                $r = join ' ', sort { $a <=> $b } @i;
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
