#! /usr/bin/perl -w
use strict;
$| = 1;

# $Id$
use vars qw( $VERSION );
$VERSION = '0.011';

use File::Spec;
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use lib $FindBin::Bin;
use Test::Smoke;
use Test::Smoke::Syncer;
use Test::Smoke::Util qw( do_pod2usage );

use Getopt::Long;
my %opt = (
    type   => undef,
    ddir   => undef,
    v      => undef,

    config => undef,
    help   => 0,
    man    => 0,
);

my $defaults = Test::Smoke::Syncer->config( 'all_defaults' );

my %valid_type = map { $_ => 1 } qw( rsync git snapshot copy hardlink forest ftp );

=head1 NAME

synctree.pl - Cleanup and sync the perl-current source-tree

=head1 SYNOPSIS

    $ ./synctree.pl -t rsync -d ../perl-current [--help | more options]

or

   $ ./synctree.pl -c [smokecurrent_config]

=head1 OPTIONS

Options depend on the B<type> option, exept for some.

=over 4

=item * B<Configuration file>

    -c | --config <configfile> Use the settings from the configfile

F<synctree.pl> can use the configuration file created by F<configsmoke.pl>.
Other options can override the settings from the configuration file.

=item * B<General options>

    -d | --ddir <directory>  Set the directory for the source-tree
    -t | --type <type>       'rsync', 'snapshot', 'copy', 'ftp' [mandatory]

    -v | --verbose <0..2>    Set verbose level
    -h | --help              Show help message (needs Pod::Usage)
    --man                    Show the perldoc  (needs Pod::Usage)

=item * B<options for> -t rsync

    --source <rsync-src>     (public.activestate.com::perl-current)
    --rsync <path/to/rsync>  (rsync)
    --opts <rsync-opts>      (-az --delete)

=item * B<options for> -t snapshot

    --server <ftp-server>    (public.activestate.com)
    --sdir <directory>       (/pub/apc/perl-current-snap)
    --sfile <file>           ('')
    --snapext <ext>          (tgz)
    --tar <un-tar-gz>        (gzip -dc %s | tar -xf -)

    --patchup                patch a snapshot [needs the patch program]
    --pserver <ftp-server>   (public.activestate.com)
    --pdir <directory>       (/pub/apc/perl-current-diffs)
    --unzip <command>        (gzip -dc)
    --patch <command>        (patch)
    --cleanup <level>        (0) none; (1) snapshot; (2) diffs; (3) both

=item * B<options for> -t copy

    --cdir <directory>       Source directory for copy_from_MANIFEST()

=item * B<options for> -t hardlink

    --hdir <directory>     Source directory to hardlink from

=item * B<options for> -t ftp

    --ftphost              Host with sources (public.activestate.com)
    --ftpsdir              Sourcedir to mirror (/pub/apc/perl-current)
    --ftpcdir              Diffs dir to get change (/pub/apc/perl-current-diffs)

=item * B<options for> -t forest

    --fsync <synctype>       Master sync-type (One of the above)
    --mdir <directory>       Master directory for primary sync
    --fdir <directory>       Intermediate directory (pass to mktest.pl)
    All options that are needed for the master sync-type

=back

=head1 DESCRIPTION

This is a small front-end for L<Test::Smoke::Syncer>.

=cut

my $myusage = "Usage: $0 -t rsync -d <destdir>";
GetOptions( \%opt,
    'type|t=s', 'ddir|d=s', 'v|verbose=i',

    'source=s', 'rsync=s', 'opts',

    'server=s', 'sdir=s', 'sfile=s', 'snapext=s', 'tar=s',
    'patchup!',  'pserver=s', 'pdir=s', 'unzip=s', 'patch=s', 'cleanup=i',

    'cdir=s',

    'ftype=s', 'fdir=s', 'hdir=s',

    'help|h', 'man|m',

    'config|c:s',
) or do_pod2usage( verbose => 1, myusage => $myusage );

$opt{ man} and do_pod2usage( verbose => 2, exitval => 0, myusage => $myusage );
$opt{help} and do_pod2usage( verbose => 1, exitval => 0, myusage => $myusage );

if ( defined $opt{config} ) {
    $opt{config} eq "" and $opt{config} = 'smokecurrent_config';
    read_config( $opt{config} ) or do {
        my $config_name = File::Spec->catfile( $FindBin::Bin, $opt{config} );
        read_config( $config_name );
    };

    unless ( Test::Smoke->config_error ) {
        foreach my $option ( keys %opt ) {
            next if defined $opt{ $option };
            if ( $option eq 'type' ) {
                $opt{type} ||= $conf->{sync_type};
            } elsif ( exists $conf->{ $option } ) {
                $opt{ $option } ||= $conf->{ $option }
            }
        }
    } else {
        warn "WARNING: Could not process '$opt{config}': " . 
             Test::Smoke->config_error . "\n";
    }
}

foreach ( keys %$defaults ) {
    next if defined $opt{ $_ };
    $opt{ $_ } = exists $conf->{ $_ } ? $conf->{ $_ } : $defaults->{ $_ };
}

exists $valid_type{ $opt{type} } or do_pod2usage( verbose => 0 );
$opt{ddir} or do_pod2usage( verbose => 0 );

my $patchlevel;

my $syncer = Test::Smoke::Syncer->new( $opt{type} => \%opt );

$patchlevel = $syncer->sync;

$opt{v} and print "$opt{ddir} now up to patchlevel $patchlevel\n";

=head1 SEE ALSO

L<perlhack/"Keeping in sync">, L<Test::Smoke::Syncer>

=head1 COPYRIGHT

(c) 2002-2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
