package Pfacter::filesystems;

# List mounted filesystems

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            my ( @l, @fs );

            foreach my $fstype ( qw/ jfs2 / ) {
                if ( -e '/usr/sbin/lsfs' ) {
                    open( F, "/usr/sbin/lsfs -c -v $fstype |" );
                    foreach ( <F> ) {
                        next if /^#/;

                        @l = split( /:/, $_ );
                        push @fs, "$l[1]=$l[0]";
                    }
                    close( F );
                }
            }
            $r = join ( ' ', sort @fs );
        };

        /Darwin/ && do {
            my ( @l, @fs );

            foreach my $fstype ( qw / hfs ufs / ) {
                if ( -e '/sbin/mount' ) {
                    open( F, "/sbin/mount -t $fstype |" );
                    foreach ( <F> ) {
                        @l = split( / /, $_ );
                        push @fs, "$l[0]=$l[2]";
                    }
                    close( F );
                }
            }

            $r = join ( ' ', sort @fs );
        };

        /Linux/ && do {
            my ( @l, @fs );

            foreach my $fstype ( qw/ ext2 ext3 reiserfs xfs / ) {
                if ( -e '/bin/mount' ) {
                    open( F, "/bin/mount -t $fstype |" );
                    foreach ( <F> ) { 
                        @l = split( / /, $_ );
                        push @fs, "$l[0]=$l[2]";
                    }
                    close( F );
                }
            }
            $r = join ( ' ', sort @fs );
        };

        /SunOS/ && do {
            my ( @l, @fs );

            if ( -e '/sbin/mount' ) {
                open( F, '/sbin/mount -p |' );
                foreach ( <F> ) {
                    @l = split( / /, $_ );
                    push @fs, "$l[0]=$l[2]" if $l[3] eq 'ufs';
                }
                close( F );
            }
            $r = join ( ' ', sort @fs );
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
