package lib::archive;

use strict;
use warnings;

use 5.010001;

use Carp qw(croak);
use Archive::Tar;
use Cwd qw(abs_path);
use File::Basename qw(fileparse);

our $VERSION = "0.3";

=pod

=head1 NAME

lib::archive - load pure-Perl modules directly from TAR archives

=head1 SYNOPSIS

  use FindBin qw($Bin);
  use lib::archive ("$Bin/external/*.tgz", "$Bin/extra.tar");

  use MyModule; # the given tar archives will be searched first

or

  use lib::archive qw(
    https://www.cpan.org/modules/by-module/JSON/JSON-PP-2.97001.tar.gz
    CPAN://YAML-PP-0.007.tar.gz
  );

  use JSON::PP;
  use YAML::PP;

=head1 DESCRIPTION

Specify TAR archives to directly load modules from. The TAR files will be
searched like include dirs. Globs are expanded, so you can use wildcards
(not for URLs). If modules are present in more than one TAR archive, the
first one will be used.

B<The module will not create any files, not even temporary. Everything is
extracted on the fly>.

You can use every file format Archive::Tar supports.

If the archive contains a toplevel directory 'lib' the module search path
will start there. Otherwise it will start from the root of the archive.

If the archive is a gzipped TAR archive with the extension '.tar.gz' and the
archive contains a toplevel directory matching the archive name without the
extension the module search path starts with this directory. The above
rule for the subdirectory 'lib' applies from there. This means that e.g. for
'JSON-PP-2.97001.tar.gz' the modules will only be included from
'JSON-PP-2.97001/lib'.

You can use URLs for loading modules directly from CPAN. Either specify the
complete URL like:

  use lib::archive 'https://www.cpan.org/modules/by-module/JSON/JSON-PP-2.97001.tar.gz';

or use a shortcut like:

  use lib::archive 'CPAN://JSON-PP-2.97001.tar.gz';

which will do exactly the same thing (at least in most cases: there seem to
be modules without an entry under 'modules/by-module/<toplevel>'; in that
case you have to use an URL pointing to the file under 'authors/id').

If the environment variable CPAN_MIRROR is set, it will be used instead of
'https://www.cpan.org'.

=head1 WHY

There are two use cases that motivated the creation of this module:

=over

=item 1. bundling various self written modules as a versioned release

=item 2. quickly switching between different versions of a module for debugging purposes

=back

=head1 AUTHOR

Thomas Kratz E<lt>tomk@cpan.orgE<gt>

=cut

my $cpan   = $ENV{CPAN_MIRROR} || 'https://www.cpan.org';
my $is_url = qr!^(?:CPAN|https?)://!;
my $tar    = Archive::Tar->new();

sub import {
    my $class = shift;
    my %cache;

    for my $entry ( @_ ) {
        my $arcs = $entry =~ /$is_url/
                 ? _get_url($entry)
                 : _get_files($entry);
        for my $arc ( @$arcs ) {
            my %tmp;
            my $mod = 0;
            my $lib = 0;
            for my $f ( $tar->read($arc->[0]) ) {
                next unless (my $full = $f->full_path) =~ /\.pm$/;
                my @parts = split('/', $full);
                ++$mod && shift @parts if $parts[0] eq $arc->[1];
                ++$lib && shift @parts if $parts[0] eq 'lib';
                my $rel = join('/', @parts);
                $tmp{$rel}{$full} = $f->get_content_by_ref;
            }
            for my $rel ( keys %tmp ) {
                my @parts = (
                    $mod ? $arc->[1] : (),
                    $lib ? 'lib'     : (),
                    $rel
                );
                my $full = join('/', @parts);
                $cache{$rel} //= {
                    path    => ref($arc->[0]) ? $entry : $arc->[0],
                    content => $tmp{$rel}{$full},
                };
            }
        }
    }
    unshift @INC, sub {
        my($cref, $rel) = @_;
        my $rec = $cache{$rel} or $cache{"lib/$rel"} or return;
        my $root = $rec->{path} =~ /$is_url/
                 ? $rec->{path}
                 : abs_path($rec->{path});
        $root =~ s!\\!/!g;
        $INC{$rel} =  "$root/$rel";
        return $rec->{content};
    };
}


sub _get_files {
    my($glob) = @_;
    ( my $glob_ux = $glob) =~ s!\\!/!g;
    my @files;
    for my $f ( sort glob($glob_ux) ) {
        my($module, $dirs, $suffix) = fileparse($f, qr/\.tar\.gz/);
        push @files, [$f, $module];
    }
    return \@files;
}


sub _get_url {
    my($url) = @_;

    my($module) = $url =~ m!/([^/]+)\.tar\.gz$!;
    my($top) = split(/-/, $module);

    $url =~ s!^CPAN://!$cpan/modules/by-module/$top/!;

    require HTTP::Tiny;
    require IO::Uncompress::Gunzip;

    my $rp = HTTP::Tiny->new->get($url);

    my @zips;
    if ( $rp->{success} ) {
        my $z = IO::Uncompress::Gunzip->new(\$rp->{content});
        push @zips, [$z, $module];
    } else {
        croak "GET '$url' failed with status:", $rp->{status};
    }
    return \@zips;
}


1;