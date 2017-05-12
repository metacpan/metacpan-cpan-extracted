#! /usr/bin/perl -w
use strict;
$| = 1;

# $Id$
use vars qw( $VERSION );
$VERSION = '0.008';

use Cwd;
use File::Spec;
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use lib $FindBin::Bin;
use Test::Smoke;
use Test::Smoke::Patcher;
use Test::Smoke::Util qw( do_pod2usage );

my $myusage = "Usage: $0 -f <patchesfile> -d <destdir> [options]";
use Getopt::Long;
my %opt = (
    type    => 'multi',
    ddir    => undef,
    pfile   => undef,
    v       => undef,

    config  => undef,
    help    => 0,
    man     => 0,
);

my $defaults = Test::Smoke::Patcher->config( 'all_defaults' );

my %valid_type = map { $_ => 1 } qw( single multi );

=head1 NAME

patchtree.pl - Patch the sourcetree

=head1 SYNOPSIS

    $ ./patchtree.pl -f patchfile -d ../perl-current [--help | more options]

or

    $ ./patchtree.pl -c [smokecurrent_config]

=head1 OPTIONS

=over 4

=item * B<Configuration file>

    -c | --config <configfile> Use the settings from the configfile

F<patchtree.pl> can use the configuration file created by F<configsmoke.pl>.
Other options can override the settings from the configuration file.

=item * B<General options>

    -d | --ddir <directory>  Set the directory for the source-tree (cwd)
    -f | --pfile <patchfile> Set the resource containg patch info

    -v | --verbose <0..2>    Set verbose level
    -h | --help              Show help message (needs Pod::Usage)
    --man                    Show the perldoc  (needs Pod::Usage)

=back

=head1 DESCRIPTION

This is a small front-end for L<Test::Smoke::Patcher>.

=cut

GetOptions( \%opt,
    'pfile|f=s', 'ddir|d=s', 'v|verbose=i',

    'popts=s',

    'help|h', 'man',

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
                $opt{type} ||= $conf->{patch_type};
            } elsif ( exists $conf->{ $option } ) {
                $opt{ $option } ||= $conf->{ $option }
            }
        }
    } else {
        warn "WARNING: Could not process '$opt{config}': " . 
             Test::Smoke->config_error . "\n";
    }
}

foreach( keys %$defaults ) {
    next if defined $opt{ $_ };
    $opt{ $_ } = defined $conf->{ $_ } ? $conf->{ $_ } : $defaults->{ $_ };
}

exists $valid_type{ $opt{type} } or do_pod2usage( verbose => 0 );

$opt{ddir} && -d $opt{ddir} or do_pod2usage( verbose => 0 );
$opt{pfile} && -f $opt{pfile} or do_pod2usage( verbose => 0 );

my $patcher = Test::Smoke::Patcher->new( $opt{type} => \%opt );
eval{ $patcher->patch };

=head1 SEE ALSO

L<Test::Smoke::Patcher>

=head1 COPYRIGHT

(c) 2002-2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

item * L<http://www.perl.com/perl/misc/Artistic.html>

item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
