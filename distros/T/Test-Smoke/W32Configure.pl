#! /usr/bin/perl -w
use strict;
$| = 1;
# BEGIN { die "You must be on MSWin32 for this!\n" unless $^O eq 'MSWin32' }

# $Id$
use vars qw( $VERSION );
$VERSION = '0.007';

use File::Spec;
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use lib $FindBin::Bin;
use Test::Smoke;
use Test::Smoke::Util qw( Configure_win32 do_pod2usage );
require Test::Smoke::SysInfo;

use Getopt::Long;
Getopt::Long::Configure( 'pass_through' );
my %opt = (
    ddir   => '',
    maker  => '',
    v      => 0,

    config => undef,
    help   => 0,
    man    => 0,
);

=head1 NAME

W32Configure.pl - Configure a Makefile for the Windows port of perl

=head1 SYNOPSIS

  S:\Smoke>W32Configure -c <config> [Configure options]

=head1 OPTIONS

=over 4

=item * B<Configuration file>

  -c | --config <configfile> Use the settings from the configfile

F<W32Configure.pl> can use the configuration file created by F<configsmoke.pl>.
Other options can override the settings from the configuration file.

=item * B<General options>

  --ddir|-d    <builddir>     Specify the build directory
  --w32make|-m <nmake|dmake>  Specify the make program

  --verbose|-v <0..2>         Verbosity level
  --help|-h                   Show help
  --man                       Show the full perldoc

=item * B<Configure options>

All configure options can just be specified on the command-line. When
using a configuration file, you may ommit the '-DCCTYPE=' argument.

For a list of configuration options please see L<Test::Smoke::Util>.

=back

=head1 DESCRIPTION

B<This is still an alpha interface, anything could change>

This is a raw interface to C<Test::Smoke::Util::Configure_win32()>.
Just pass it options for the F<Makefile> on the command-line.
See L<Test::Smoke::Util/Configure_win32> for options you can pass!

The result is B<[builddir]\win32\smoke.mk> a makefile that has all
the configure options you passed worked into it. 

This could help debugging.

=cut

my $my_usage = "Usage: $0 -m <maker> -d <directory> [Configure-options]";
GetOptions( \%opt,
    'ddir|d=s', 'maker|w32make|m=s', 'v|verbose=i',

    'man', 'help|h',

    'config|c:s',
) or do_pod2usage( verbose => 1, myusage => $my_usage );

$opt{ man} and do_pod2usage(verbose => 2, exitval => 0, myusage => $my_usage);
$opt{help} and do_pod2usage(verbose => 1, exitval => 0, myusage => $my_usage);

if ( defined $opt{config} ) {
    $opt{config} eq "" and $opt{config} = 'smokecurrent';
    read_config( $opt{config} ) or do {
        my $config_name = File::Spec->catfile( $FindBin::Bin, $opt{config} );
        read_config( $config_name );
    };

    unless ( Test::Smoke->config_error ) {
        foreach my $option ( keys %opt ) {
            if ( $option eq 'maker' ) {
                $opt{maker} ||= $conf->{w32make};
            } elsif ( exists $conf->{ $option } ) {
                $opt{ $option } ||= $conf->{ $option }
            }
        }
    } else {
        warn "WARNING: Could not process '$opt{config}': " . 
             Test::Smoke->config_error . "\n";
    }
}

$opt{maker} ||= 'nmake';
$opt{ddir} && -d $opt{ddir} or
    do_pod2usage( message => "'$opt{ddir}' does not exist!", 
                  verbose => 0, myusage => $my_usage );

push @ARGV, "-DCCTYPE=$conf->{w32cc}" unless grep /^-DCCTYPE=/ => @ARGV;
my $c_args = join " ", @ARGV;
my @w32args = @{ $conf->{w32args} };
@w32args = @w32args[4 .. $#w32args];
my @cfgvars = @w32args ? @w32args : ( 'osvers=' . get_Win_version() );

$opt{v} and print "./Configure [$c_args] $opt{maker} '@cfgvars'\n";

chdir $opt{ddir} or die "Cannot chdir($opt{ddir}): $!";
Configure_win32( "./Configure $c_args", $opt{maker}, @cfgvars );

sub get_Win_version {
    ( my $win_version = Test::Smoke::SysInfo::__get_os() ) =~ s/^[^-]*- //;
    return $win_version;
}

=head1 SEE ALSO

L<Test::Smoke::Util>

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
