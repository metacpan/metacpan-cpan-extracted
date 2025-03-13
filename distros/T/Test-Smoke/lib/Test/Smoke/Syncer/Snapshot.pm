package Test::Smoke::Syncer::Snapshot;
use warnings;
use strict;

our $VERSION = '0.029';

use base 'Test::Smoke::Syncer::Base';

=head1 Test::Smoke::Syncer::Snapshot

This handles syncing from an HTTP snapshot (Porting/make_snapshot.pl)
It should only be visible from the "parent-package" so no direct
user-calls on this.

=cut

use Cwd;
use File::Path;
use Test::Smoke::Util qw( whereis clean_filename );

=head2 Test::Smoke::Syncer::Snapshot->new( %args )

This crates the new object. Keys for C<%args>:

  * ddir:      destination directory ( ./perl-current )
  * snapurl:   the server to get the download from
  * snaptar:   howto untar ( Archive::Tar or 'gzip -d -c %s | tar x -' )
  * v:         verbose

=cut

=head2 $syncer->sync( )

Fetch the file. Remove the current source-tree
and extract the tarball or zip.

=cut

sub sync {
    my $self = shift;

    $self->pre_sync;
    # we need to have {ddir} before we can save the snapshot
    -d $self->{ddir} or mkpath( $self->{ddir} );

    $self->{archive} = $self->_fetch_archive or return undef;

    $self->_clear_source_tree;

    $self->_extract_archive;


    my $plevel = $self->check_dot_git_patch;

    if (not defined $plevel) {
        $self->check_dot_patch;
    }

    $self->post_sync;
    return $plevel;
}

=head2 $syncer->_fetch_archive( )

C<_fetch_archive()> downloads the archive

=cut

sub _fetch_archive {
    my $self = shift;

    require LWP::Simple;

    unless ( $self->{snapurl} ) {
        require Carp;
        Carp::carp( "No URL specified for $self->{snapurl}" );
        return undef;
    }

    my @pieces = split "/", $self->{snapurl};
    my $snapfile = pop @pieces;


    my $local_archive = File::Spec->catfile( $self->{ddir}, File::Spec->updir, $snapfile );
    $local_archive = File::Spec->canonpath( $local_archive );

    my $remote_archive = "$self->{snapurl}";

    $self->{v} and print "LWP::Simple::mirror($remote_archive)";
    my $result = LWP::Simple::mirror( $remote_archive, $local_archive );
    if ( LWP::Simple::is_success( $result ) ) {
        $self->{v} and print " OK\n";
        return $local_archive;
    } elsif ( LWP::Simple::is_error( $result ) ) {
        $self->{v} and print " not OK\n";
        return undef;
    } else {
        $self->{v} and print " skipped\n";
        return $local_archive;
    }
}


=head2 $syncer->_extract_archive( )

C<_extract_archive()> checks the B<tar> attribute to find out how to
extract the archive. This could be an external command or the
B<Archive::Tar>/B<Comperss::Zlib> modules.

=cut

sub _extract_archive {
    my $self = shift;

    unless ( $self->{archive} && -f $self->{archive} ) {
        require Carp;
        Carp::carp( "No archive to be extracted!" );
        return undef;
    }

    my $cwd = cwd();

    # Files in the archive are relative to the 'perl/' directory,
    # they may need to be moved and that is not easy when you've
    # extracted them in the target directory! so we go updir()
    my $ddir = $^O eq 'VMS' ? $self->{vms_ddir} : $self->{ddir};
    my $extract_base = File::Spec->catdir( $ddir, File::Spec->updir );
    chdir $extract_base or do {
        require Carp;
        Carp::croak( "Can't chdir '$extract_base': $!" );
    };

    my $archive_base;
    EXTRACT: {
        local $_ = $self->{snaptar} || 'Archive::Tar';

        /^Archive::Tar$/ && do {
            $archive_base = $self->_extract_with_Archive_Tar;
            last EXTRACT;
        };

        # assume a commandline template for $self->{tar}
        $archive_base = $self->_extract_with_external;
    }

    $self->_relocate_tree( $archive_base );

    chdir $cwd or do {
        require Carp;
        Carp::croak( "Can't chdir($extract_base) back: $!" );
    };

    1 while unlink $self->{archive};
}

=head2 $syncer->_extract_with_Archive_Tar( )

C<_extract_with_Archive_Tar()> uses the B<Archive::Tar> and
B<Compress::Zlib> modules to extract the archive.
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

    $self->{v} and printf "Extracting '$self->{archive}' (%s) ", cwd();
    $archive->read( $self->{archive}, 1 );
    $Archive::Tar::error and do {
        require Carp;
        Carp::carp("Error reading '$self->{archive}': ".$Archive::Tar::error);
        return undef;
    };
    my @files = $archive->list_files;
    $archive->extract( @files );
    $self->{v} and printf "%d items OK.\n", scalar @files;

    ( my $prefix = $files[0] ) =~ s|^([^/]+).+$|$1|;
    my $base_dir = File::Spec->canonpath(File::Spec->catdir( cwd(), $prefix ));
    $self->{v} and print "Archive prefix: '$base_dir'\n";
    return $base_dir;
}

=head2 $syncer->_extract_with_external( )

C<_extract_with_external()> uses C<< $self->{snaptar} >> as a sprintf()
template to build a command. Yes that might be dangerous!

=cut

sub _extract_with_external {
    my $self = shift;

    my @dirs_pre = __get_directory_names();

    if ( $^O ne 'VMS' ) {
        my $command = sprintf $self->{snaptar}, $self->{archive};
        $command .= " $self->{archive}" if $command eq $self->{snaptar};

        $self->{v} and print "$command ";
        if ( system $command ) {
            my $error = $? >> 8;
            require Carp;
            Carp::carp( "Error in command: $error" );
            return undef;
        };
        $self->{v} and print "OK\n";
    } else {
        __vms_untargz( $self->{snaptar}, $self->{archive}, $self->{v} );
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
    $self->{v} and print "Archive prefix: '$base_dir'\n";
    return $base_dir;
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
