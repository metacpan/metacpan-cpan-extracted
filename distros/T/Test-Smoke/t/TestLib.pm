package TestLib;
use strict;

our $VERSION = '0.06';

use Test::Smoke::Util qw( whereis );

use base 'Exporter';
our @EXPORT = qw(
    &whereis
    &find_a_patch
    &find_unzip &do_unzip
    &find_untargz &do_untargz
    &manify_path
    &get_dir &get_file &put_file
    &rmtree &mkpath
);

=head1 NAME

TestLib - Stuff to help the test-suite

=head1 SYNOPSIS

    use TestLib;

=head1 DESCRIPTION

What is in here?

=over 4

=cut

use Config;
use File::Find;
use File::Spec::Functions qw( :DEFAULT abs2rel rel2abs
                              splitdir splitpath catpath);
require File::Path;
use Cwd;
use Carp;

=item manify_path( $path )

Do a OS-specific split on the path, and join with '/' for MANIFEST
format.

=cut

sub manify_path($) {
    my $path = shift or return;
    # There should be no volume on these file_paths
    $path = File::Spec->canonpath( $path );
    my( undef, $dirs, $file ) = File::Spec->splitpath( $path );

    my @subdirs = grep $_ && length $_ => File::Spec->splitdir( $dirs );
    $^O eq 'VMS' and $file =~ s/\.$//;

    push @subdirs, $file;

    return join '/', @subdirs;
}

=item get_dir( $path )

Returns a list of filenames (no directory-names) in C<$path>.

=cut

sub get_dir($) {
    my( $path ) = @_;
    my $cwd = cwd();
    chdir $path or die "Cannot chdir($path): $!";
    my @files;
    find sub {
        -f or return;
        my $cname = File::Spec->canonpath( $File::Find::name );
        push @files, $cname;
    }, '.';

    chdir $cwd or die "Cannot chdir($cwd) back: $!";
    return @files;
}

=item get_file( @path )

The contents of C<@path> are passed to B<< File::Spec->catfile() >>

Returns the contents of a file, takes note of context (scalar/list).

=cut

sub get_file {
    my $filename = File::Spec->catfile( @_ );

    local *MYFILE;
    my @content;
    if ( open MYFILE, "< $filename" ) {
        @content = <MYFILE>;
        close MYFILE;
    } else {
        Carp::carp("(@{[cwd]})$filename: $!");
    }

    return wantarray ? @content : join "", @content;
}

=item put_file( $content, @path )

The contents of C<@path> are passed to B<< File::Spec->catfile() >>

Writes C<$content> to that file and returns the success/failure.

=cut

sub put_file {
    my $contents = shift;
    my $filename = File::Spec->catfile( @_ );

    local *MYFILE;
    if ( open MYFILE, "> $filename" ) {
        print MYFILE $contents;
        close MYFILE or do {
            warn "Cannot close (@{[cwd]})$filename: $!";
            return;
        };
    } else {
        warn "Cannot create (@{[cwd]})$filename: $!";
        return;
    }

    return 1;
}

=item rmtree( @_ )

This is B<< File::Path::rmtree() >>.

=cut

sub rmtree { File::Path::rmtree( @_ ) }

=item mkpath( @_ )

This is B<< File::Path::mkpath() >>.

=cut

sub mkpath { File::Path::mkpath( @_ ) }

=item find_a_patch()

Loop over some known names for gnu-patch and see if they know about --version.

=cut

sub find_a_patch {

    my $patch_bin;
    foreach my $patch (qw( gpatch npatch patch )) {
        $patch_bin = whereis( $patch ) or next;
        my $version = `$patch_bin --version 2>&1`;
        $? or return $patch_bin;
    }
}

=item find_unzip()

Check C<< wheris( 'gzip' ) >> or C<< eval{ require Compress::Zlib } >>.

=cut

sub find_unzip {
    my $unzip = whereis( 'gzip' );

    my $dounzip = $unzip ? "$unzip -cd " : "";

    unless ( $dounzip ) {
        eval { require Compress::Zlib };
        $dounzip = 'Compress::Zlib' unless $@;
    }

    return $dounzip;
}

=item do_unzip( $unzip, $uzfile )

Returns the gunzipped contents of C<$uzfile>.

=cut

sub do_unzip {
    my( $unzip, $uzfile ) = @_;
    return undef unless -f $uzfile;

    my $content;
    if ( $unzip eq 'Compress::Zlib' ) {
        require Compress::Zlib;
        my $unzipper = Compress::Zlib::gzopen( $uzfile, 'rb' ) or do {
            require Carp;
            Carp::carp( "Can't open '$uzfile': $Compress::Zlib::gzerrno" );
            return undef;
        };

        my $buffer;
        $content .= $buffer while $unzipper->gzread( $buffer ) > 0;

        unless ( $Compress::Zlib::gzerrno == Compress::Zlib::Z_STREAM_END() ) {
            require Carp;
            Carp::carp( "Error reading '$uzfile': $Compress::Zlib::gzerrno" );
        }

        $unzipper->gzclose;
    } else {

        # this calls out for `$unzip $uzfile`
        # {unzip} could be like 'zcat', 'gunzip -c', 'gzip -dc'

        $content = `$unzip $uzfile`;
    }

    return $content;

}

=item find_untargz()

Find either B<gzip>/B<tar> or B<Compress::Zlib>/B<Archive::Tar>

=cut

sub find_untargz {
    my $tar = whereis( 'tar' );

    my $uncompress = '';
    if ( $tar ) {
        my $zip = whereis( 'gzip' );
        $uncompress = "$zip -cd %s | $tar -xf -" if $zip;
    }

    unless ( $uncompress ) {
        eval { require Archive::Tar; };
        unless ( $@ ) {
            if ( $Archive::Tar::VERSION >= 0.99 ) {
                eval { require IO::Zlib };
            } else {
                eval { require Compress::Zlib };
            }
            $uncompress = 'Archive::Tar' unless $@;
        }
    }

    if ( $tar && !$uncompress ) { # try tar by it self
        $uncompress = "$tar -xzf %s";
    }

    return $uncompress;
}

=item do_untargz( $untargz, $tgzfile )

Gunzip and extract the archive in C<$tgzfile>.

=cut

sub do_untargz {
    my( $untgz, $tgzfile ) = @_;

    if ( $untgz eq 'Archive::Tar' ) {
        require Archive::Tar;

        my $archive = Archive::Tar->new() or do {
            warn "Can't Archive::Tar->new: " . $Archive::Tar::error;
            return undef;
        };

        $archive->read( $tgzfile, 1 );
        $Archive::Tar::error and do {
            warn "Error reading '$tgzfile': ".$Archive::Tar::error;
            return undef;
        };
        my @files = $archive->list_files;
        $archive->extract( @files );

    } else { # assume command
        $^O eq 'VMS' and return vms_untargz( $untgz, $tgzfile );

        my $command = sprintf $untgz, $tgzfile;
        $command .= " $tgzfile" if $command eq $untgz;

        if ( system $command ) {
            my $error = $? >> 8;
            warn "Error in command: $error";
            return undef;
        };
    }
    return 1;
}

=item vms_untargz( $untargz, $tgzfile )

Gunzip and extract the archive in C<$tgzfile>.

=cut

sub vms_untargz {
    my( $cmd, $file ) = @_;
    my( $vol, $path, $fname ) = splitpath( $file );
    my @parts = split /[.@#]/, $fname;
    if ( @parts > 1 ) {
        my $ext = ( pop @parts ) || '';
        $fname = join( "_", @parts ) . ".$ext";
    }
    $file = catpath( $vol, $path, $fname );

    my( $gzip_cmd, $tar_cmd ) = split /\s*\|\s*/, $cmd;
    my $gzip = $gzip_cmd =~ /^(\S+)/ ? $1 : 'GZIP';
    my $tar  = $tar_cmd  =~ /^(\S+)/
        ? $1 : (whereis( 'vmstar' ) || whereis( 'tar' ) );

    local *TMPCOM;
    open TMPCOM, "> TS-UNTGZ.COM" or return 0;
    print TMPCOM <<EO_UNTGZ; close TMPCOM or return 0;
\$ define/user sys\$output TS-UNTGZ.TAR
\$ $gzip "-cd" $file
\$ $tar "-xf" TS-UNTGZ.TAR
\$ delete TS-UNTGZ.TAR;*
EO_UNTGZ

    my $ret = system "\@TS-UNTGZ.COM";
    1 while unlink "TS-UNTGZ.COM";

    return ! $ret;
}

1;

=back

=head1 COPYRIGHT

(c) 2001-2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item  * L<http://www.perl.com/perl/misc/Artistic.html>

=item  * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
