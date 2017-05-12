package Pfacter::cfclasses;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX|Linux/ && do {
            my ( $d, @i );

            if ( -e '/var/cfengine/bin/cfagent' ) {
                my ( @C );

                open( F, '/var/cfengine/bin/cfagent -pv |' );
                foreach ( <F> ) { push @C, $_ if /classes/i; }
                close( F );

                foreach ( @C ) {
                    my ( @classes );

                    chomp();
                    my $classes = $1 if /.+?\(\s(.+?)\s\)$/i;

                    foreach ( split( / /, $classes ) ) {
                        next if (
                            /^entropy/
                         || /^Day[0-9]*|^Hr[0-9]*|^Min[0-9]*|^Yr[0-9]*|^Q[1-4]/
                         || /^Sun|^Mon|^Tue|^Wed|^Thu|^Fri|^Sat/
                         || /_Sun|_Mon|_Tue|_Wed|_Thu|_Fri|_Sat/
                         || /^Jan|^Feb|^Mar|^Apr|^May|^Jun|^Jul|^Aug|^Sep|^Oct|^Nov|^Dec/
                        );

                        push @classes, $_;
                    }

                    $r = join ' ', sort @classes; last;
                }
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
