package Test::Smoke::Syncer::Snapshot;
use warnings;
use strict;

use base 'Test::Smoke::Syncer::Base';

=head1 Test::Smoke::Syncer::Snapshot

This handles syncing from a snapshot with the B<Net::FTP> module.
It should only be visible from the "parent-package" so no direct
user-calls on this.

=cut

use Cwd;
use File::Path;
use Test::Smoke::Util qw( whereis clean_filename );

=head2 Test::Smoke::Syncer::Snapshot->new( %args )

This crates the new object. Keys for C<%args>:

  * ddir:    destination directory ( ./perl-current )
  * server:  the server to get the snapshot from ( public.activestate.com )
  * sdir:    server directory ( /pub/apc/perl-current-snap )
  * snapext: the extension used for snapdhots ( tgz )
  * tar:     howto untar ( Archive::Tar or 'gzip -d -c %s | tar x -' )
  * v:       verbose

=cut

=head2 $syncer->sync( )

Make a connection to the ftp server, change to the {sdir} directory.
Get the list of snapshots (C<< /^perl@\d+\.tgz$/ >>) and determin the
highest patchlevel. Fetch this file.  Remove the current source-tree
and extract the snapshot.

=cut

sub sync {
    my $self = shift;

    $self->pre_sync;
    # we need to have {ddir} before we can save the snapshot
    -d $self->{ddir} or mkpath( $self->{ddir} );

    $self->{snapshot} = $self->_fetch_snapshot or return undef;

    $self->_clear_source_tree;

    $self->_extract_snapshot;

    $self->patch_a_snapshot if $self->{patchup};

    my $plevel = $self->check_dot_patch;
    $self->post_sync;
    return $plevel;
}

=head2 $syncer->_fetch_snapshot( )

C<_fetch_snapshot()> checks to see if
C<< S<< $self->{server} =~ m|^https?://| >> && $self->{sfile} >>.
If so let B<LWP::Simple> do the fetching else do the FTP thing.

=cut

sub _fetch_snapshot {
    my $self = shift;

    return $self->_fetch_snapshot_HTTP if $self->{server} =~ m|^https?://|i;

    require Net::FTP;
    my $ftp = Net::FTP->new($self->{server}, Debug => 0, Passive => 1) or do {
        require Carp;
        Carp::carp( "[Net::FTP] Can't open $self->{server}: $@" );
        return undef;
    };

    my @login = ( $self->{ftpusr}, $self->{ftppwd} );
    $ftp->login( @login ) or do {
        require Carp;
        Carp::carp( "[Net:FTP] Can't login( @login )" );
        return undef;
    };

    $self->{v} and print "Connected to $self->{server}\n";
    $ftp->cwd( $self->{sdir} ) or do {
        require Carp;
        Carp::carp( "[Net::FTP] Can't chdir '$self->{sdir}'" );
        return undef;
    };

    my $snap_name = $self->{sfile} ||
                    __find_snap_name( $ftp, $self->{snapext}, $self->{v} );

    unless ( $snap_name ) {
        require Carp;
        Carp::carp("Couldn't find a snapshot at $self->{server}$self->{sdir}");
        return undef;
    }

    $ftp->binary(); # before you ask for size!
    my $snap_size = $ftp->size( $snap_name );
    my $ddir_var = $self->{vms_ddir} ? 'vms_ddir' : 'ddir';
    my $local_snap = File::Spec->catfile( $self->{ $ddir_var },
                                          File::Spec->updir,
                                          clean_filename( $snap_name ) );
    $local_snap = File::Spec->canonpath( $local_snap );

    if ( -f $local_snap && $snap_size == -s $local_snap ) {
        $self->{v} and print "Skipping download of '$snap_name'\n";
    } else {
        $self->{v} and print "get ftp://$self->{server}$self->{sdir}/" .
                             "$snap_name\n as $local_snap ";
        my $l_file = $ftp->get( $snap_name, $local_snap );
        my $ok = $l_file eq $local_snap && $snap_size == -s $local_snap;
        $ok or printf "Error in get(%s) [%d]\n", $l_file || "",
                                                 (-s $local_snap);
        $ok && $self->{v} and print "[$snap_size] OK\n";
    }
    $ftp->quit;

    return $local_snap;
}

=head2 $syncer->_fetch_snapshot_HTTP( )

C<_fetch_snapshot_HTTP()> simply invokes C<< LWP::Simple::mirror() >>.

=cut

sub _fetch_snapshot_HTTP {
    my $self = shift;

    require LWP::Simple;
    my $snap_name = $self->{server} eq 'http://perl5.git.perl.org'
        ? 'perl-current.tar.gz'
        : $self->{sfile};

    print "$self->{server}/$self->{sdir} => $snap_name\n" if $self->{v} > 1;
    unless ( $snap_name ) {
        require Carp;
        Carp::carp( "No snapshot specified for $self->{server}$self->{sdir}" );
        return undef;
    }

    my $local_snap = File::Spec->catfile( $self->{ddir},
                                          File::Spec->updir, $snap_name );
    $local_snap = File::Spec->canonpath( $local_snap );

    my $remote_snap = "$self->{server}$self->{sdir}/$self->{sfile}";

    $self->{v} and print "LWP::Simple::mirror($remote_snap)";
    my $result = LWP::Simple::mirror( $remote_snap, $local_snap );
    if ( LWP::Simple::is_success( $result ) ) {
        $self->{v} and print " OK\n";
        return $local_snap;
    } elsif ( LWP::Simple::is_error( $result ) ) {
        $self->{v} and print " not OK\n";
        return undef;
    } else {
        $self->{v} and print " skipped\n";
        return $local_snap;
    }
}

=head2 __find_snap_name( $ftp, $snapext[, $verbose] )

[Not a method!]

Get a list with all the B<perl@\d+> files, use an ST to sort these and
return the one with the highes number.

=cut

sub __find_snap_name {
    my( $ftp, $snapext, $verbose ) = @_;
    $snapext ||= 'tgz';
    $verbose ||= 0;
    $verbose > 1 and print "Looking for /$snapext\$/\n";

    my @list = $ftp->ls();

    my $snap_name = ( map $_->[0], sort { $a->[1] <=> $b->[1] } map {
        my( $p_level ) = /^perl[@#_](\d+)/;
        $verbose > 1 and print "Kept: $_ ($p_level)\n";
        [ $_, $p_level ]
    } grep {
    	/^perl[@#_]\d+/ &&
    	/$snapext$/
    } map { $verbose > 1 and print "Found snapname: $_\n"; $_ } @list )[-1];

    return $snap_name;
}

=head2 $syncer->_extract_snapshot( )

C<_extract_snapshot()> checks the B<tar> attribute to find out how to
extract the snapshot. This could be an external command or the
B<Archive::Tar>/B<Comperss::Zlib> modules.

=cut

sub _extract_snapshot {
    my $self = shift;

    unless ( $self->{snapshot} && -f $self->{snapshot} ) {
        require Carp;
        Carp::carp( "No snapshot to be extracted!" );
        return undef;
    }

    my $cwd = cwd();

    # Files in the snapshot are relative to the 'perl/' directory,
    # they may need to be moved and that is not easy when you've
    # extracted them in the target directory! so we go updir()
    my $ddir = $^O eq 'VMS' ? $self->{vms_ddir} : $self->{ddir};
    my $extract_base = File::Spec->catdir( $ddir, File::Spec->updir );
    chdir $extract_base or do {
        require Carp;
        Carp::croak( "Can't chdir '$extract_base': $!" );
    };

    my $snap_base;
    EXTRACT: {
        local $_ = $self->{tar} || 'Archive::Tar';

        /^Archive::Tar$/ && do {
            $snap_base = $self->_extract_with_Archive_Tar;
            last EXTRACT;
        };

        # assume a commandline template for $self->{tar}
        $snap_base = $self->_extract_with_external;
    }

    $self->_relocate_tree( $snap_base );

    chdir $cwd or do {
        require Carp;
        Carp::croak( "Can't chdir($extract_base) back: $!" );
    };

    if ( $self->{cleanup} & 1 ) {
        1 while unlink $self->{snapshot};
    }
}

=head2 $syncer->_extract_with_Archive_Tar( )

C<_extract_with_Archive_Tar()> uses the B<Archive::Tar> and
B<Compress::Zlib> modules to extract the snapshot.
(This tested verry slow on my Linux box!)

=cut

sub _extract_with_Archive_Tar {
    my $self = shift;

    require Archive::Tar;

    my $archive = Archive::Tar->new() or do {
        require Carp;
        Carp::carp( "Can't Archive::Tar->new: " . $Archive::Tar::error );
        return undef;
    };

    $self->{v} and printf "Extracting '$self->{snapshot}' (%s) ", cwd();
    $archive->read( $self->{snapshot}, 1 );
    $Archive::Tar::error and do {
        require Carp;
        Carp::carp("Error reading '$self->{snapshot}': ".$Archive::Tar::error);
        return undef;
    };
    my @files = $archive->list_files;
    $archive->extract( @files );
    $self->{v} and printf "%d items OK.\n", scalar @files;

    ( my $prefix = $files[0] ) =~ s|^([^/]+).+$|$1|;
    my $base_dir = File::Spec->canonpath(File::Spec->catdir( cwd(), $prefix ));
    $self->{v} and print "Snapshot prefix: '$base_dir'\n";
    return $base_dir;
}

=head2 $syncer->_extract_with_external( )

C<_extract_with_external()> uses C<< $self->{tar} >> as a sprintf()
template to build a command. Yes that might be dangerous!

=cut

sub _extract_with_external {
    my $self = shift;

    my @dirs_pre = __get_directory_names();

    if ( $^O ne 'VMS' ) {
        my $command = sprintf $self->{tar}, $self->{snapshot};
        $command .= " $self->{snapshot}" if $command eq $self->{tar};

        $self->{v} and print "$command ";
        if ( system $command ) {
            my $error = $? >> 8;
            require Carp;
            Carp::carp( "Error in command: $error" );
            return undef;
        };
        $self->{v} and print "OK\n";
    } else {
        __vms_untargz( $self->{tar}, $self->{snapshot}, $self->{v} );
    }

    # Yes another process can also create directories here!
    # Be careful.
    my %dirs_post = map { ($_ => 1) } __get_directory_names();
    exists $dirs_post{ $_ } and delete $dirs_post{ $_ }
        foreach @dirs_pre;
    # I'll pick the first one that has 'perl' in it
    my( $prefix ) = grep /\bperl/ || /perl\b/ => keys %dirs_post;
    my $ddir = $^O eq 'VMS' ? $self->{vms_ddir} : $self->{ddir};
    $prefix ||= File::Spec->abs2rel( $ddir, cwd() );

    my $base_dir = File::Spec->canonpath(File::Spec->catdir( cwd(), $prefix ));
    $self->{v} and print "Snapshot prefix: '$base_dir'\n";
    return $base_dir;
}

=head2 __vms_untargz( $untargz, $tgzfile, $verbose )

Gunzip and extract the archive in C<$tgzfile> using a small DCL script

=cut

sub __vms_untargz {
    my( $cmd, $file, $verbose ) = @_;
    my( $gzip_cmd, $tar_cmd ) = split /\s*\|\s*/, $cmd;
    my $gzip = $gzip_cmd =~ /^((?:MCR )?\S+)/ ? $1 : 'GZIP';
    my $tar  = $tar_cmd  =~ /^((?:MCR )?\S+)/
        ? $1 : (whereis( 'vmstar' ) || whereis( 'tar' ) );
    my $tar_sw = $verbose ? '-xvf' : '-xf';

    $verbose and print "Writing 'TS-UNTGZ.COM'";
    local *TMPCOM;
    open TMPCOM, "> TS-UNTGZ.COM" or return 0;
    print TMPCOM <<EO_UNTGZ; close TMPCOM or return 0;
\$! TS-UNTGZ.COM - Generated by Test::Smoke::Syncer
\$  define/user sys\$output TS-UNTGZ.TAR
\$  $gzip "-cd" $file
\$  $tar $tar_sw TS-UNTGZ.TAR
\$  delete TS-UNTGZ.TAR;*
EO_UNTGZ
    $verbose and print " OK\n";

    my $ret = system "\@TS-UNTGZ.COM";
    1 while unlink "TS-UNTGZ.COM";

    return ! $ret;
}

=head2 $syncer->patch_a_snapshot( $patch_number )

C<patch_a_snapshot()> tries to fetch all the patches between
C<$patch_number> and C<perl-current> and apply them.
This requires a working B<patch> program.

You should pass this extra information to
C<< Test::Smoke::Syncer::Snapshot->new() >>:

  * patchup:  should we do this? ( 0 )
  * pserver:  which FTP server? ( public.activestate.com )
  * pdir:     directory ( /pub/apc/perl-current-diffs )
  * unzip:    ( gzip ) [ Compress::Zlib ]
  * patchbin: ( patch )
  * cleanup:  remove patches after applied? ( 1 )

=cut

sub patch_a_snapshot {
    my( $self, $patch_number ) = @_;

    $patch_number ||= $self->check_dot_patch;

    my @patches = $self->_get_patches( $patch_number );

    $self->_apply_patches( @patches );

    return $self->check_dot_patch;
}

=head2 $syncer->_get_patches( [$patch_number] )

C<_get_patches()> sets up the FTP connection and gets all patches
beyond C<$patch_number>. Remember that patch numbers  do not have to be
consecutive.

=cut

sub _get_patches {
    my( $self, $patch_number ) = @_;

    my $ftp = Net::FTP->new($self->{pserver}, Debug => 0, Passive => 1) or do {
        require Carp;
        Carp::carp( "[Net::FTP] Can't open '$self->{pserver}': $@" );
        return undef;
    };

    my @user_info = ( $self->{ftpusr}, $self->{ftppwd} );
    $ftp->login( @user_info ) or do {
        require Carp;
        Carp::carp( "[Net::FTP] Can't login( @user_info )" );
        return undef;
    };

    $ftp->cwd( $self->{pdir} ) or do {
        require Carp;
        Carp::carp( "[Net::FTP] Can't cd '$self->{pdir}'" );
        return undef;
    };

    $self->{v} and print "Connected to $self->{pserver}\n";
    my @patch_list;

    $ftp->binary;
    foreach my $entry ( $ftp->ls ) {
        next unless $entry =~ /^(\d+)\.gz$/;
        my $patch_num = $1;
        next unless $patch_num > $patch_number;

        my $local_patch = File::Spec->catfile( $self->{ddir},
					       File::Spec->updir, $entry );
        my $patch_size = $ftp->size( $entry );
        my $l_file;
        if ( -f $local_patch && -s $local_patch == $patch_size ) {
            $self->{v} and print "Skip $entry $patch_size\n";
            $l_file = $local_patch;
        } else {
            $self->{v} and print "get $entry ";
            $l_file = $ftp->get( $entry, $local_patch );
            $self->{v} and printf "%d OK\n", -s $local_patch;
        }
        push @patch_list, $local_patch if $l_file;
    }
    $ftp->quit;

    @patch_list = map $_->[0] => sort { $a->[1] <=> $b->[1] } map {
        my( $patch_num ) = /(\d+).gz$/;
        [ $_, $patch_num ];
    } @patch_list;

    return @patch_list;
}

=head2 $syncer->_apply_patches( @patch_list )

C<_apply_patches()> calls the B<patch> program to apply the patch
and updates B<.patch> accordingly.

C<@patch_list> is a list of filenames of these patches.

Checks the B<unzip> attribute to find out how to unzip the patch and
uses the B<Test::Smoke::Patcher> module to apply the patch.

=cut

sub _apply_patches {
    my( $self, @patch_list ) = @_;

    my $cwd = cwd();
    chdir $self->{ddir} or do {
        require Carp;
        Carp::croak( "Cannot chdir($self->{ddir}): $!" );
    };

    require Test::Smoke::Patcher;
    foreach my $file ( @patch_list ) {

        my $patch = $self->_read_patch( $file ) or next;

        my $patcher = Test::Smoke::Patcher->new( single => {
            ddir     => $self->{ddir},
            patchbin => $self->{patchbin},
            pfile    => \$patch,
            v        => $self->{v},
        });
        eval { $patcher->patch };
        if ( $@ ) {
             require Carp;
	     Carp::carp( "Error while patching:\n\t$@" );
             next;
        }

        $self->_fix_dot_patch( $1 ) if $file =~ /(\d+)\.gz$/;

        if ( $self->{cleanup} & 2 ) {
            1 while unlink $file;
        }
    }
    chdir $cwd or do {
        require Carp;
        Carp::croak( "Cannot chdir($cwd) back: $!" );
    };
}

=head2 $syncer->_read_patch( $file )

C<_read_patch()> unzips the patch and returns the contents.

=cut

sub _read_patch {
    my( $self, $file ) = @_;

    return undef unless -f $file;

    my $content;
    if ( $self->{unzip} eq 'Compress::Zlib' ) {
        require Compress::Zlib;
        my $unzip = Compress::Zlib::gzopen( $file, 'rb' ) or do {
            require Carp;
            Carp::carp( "Can't open '$file': $Compress::Zlib::gzerrno" );
            return undef;
        };

        my $buffer;
        $content .= $buffer while $unzip->gzread( $buffer ) > 0;

        unless ( $Compress::Zlib::gzerrno == Compress::Zlib::Z_STREAM_END() ) {
            require Carp;
            Carp::carp( "Error reading '$file': $Compress::Zlib::gzerrno" );
        }

        $unzip->gzclose;
    } else {

        # this calls out for `$self->{unzip} $file`
        # {unzip} could be like 'zcat', 'gunzip -c', 'gzip -dc'

        $content = `$self->{unzip} $file`;
    }

    return $content;
}

=head2 $syncer->_fix_dot_patch( $new_level );

C<_fix_dot_patch()> updates the B<.patch> file with the new patch level.

=cut

sub _fix_dot_patch {
    my( $self, $new_level ) = @_;

    return $self->check_dot_patch
        unless defined $new_level && $new_level =~ /^\d+$/;

    my $dot_patch = File::Spec->catfile( $self->{ddir}, '.patch' );

    local *DOTPATCH;
    if ( open DOTPATCH, "> $dot_patch" ) {
        print DOTPATCH "$new_level\n";
        return close DOTPATCH ? $new_level : $self->check_dot_patch;
    }

    return $self->check_dot_patch;
}

=head2 __get_directory_names( [$dir] )

[This is B<not> a method]

C<__get_directory_names()> retruns all directory names from
C<< $dir || cwd() >>. It does not look at symlinks (there should
not be any in the perl source-tree).

=cut

sub __get_directory_names {
    my $dir = shift || cwd();

    local *DIR;
    opendir DIR, $dir or return ();
    my @dirs = grep -d File::Spec->catfile( $dir, $_ ) => readdir DIR;
    closedir DIR;

    return @dirs;
}

1;

=head1 COPYRIGHT

(c) 2002-2013, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

  * <http://www.perl.com/perl/misc/Artistic.html>,
  * <http://www.gnu.org/copyleft/gpl.html>

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
