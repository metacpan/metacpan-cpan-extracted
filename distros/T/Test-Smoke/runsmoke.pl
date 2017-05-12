#! /usr/bin/perl -w
use strict;
$| = 1;

# $Id$
use vars qw( $VERSION );
$VERSION = '0.002';

use Cwd;
use File::Spec;
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use lib $FindBin::Bin;
use Config;
use Test::Smoke::Smoker;
use Test::Smoke;
use Test::Smoke::Util qw( calc_timeout do_pod2usage );

use Getopt::Long;
my %opt = (
    config         => undef,
    ddir           => undef,
    fdir           => undef,
    run            => undef,
    dry_run        => undef,
    locale         => undef,
    force_c_locale => undef,
    is56x          => undef,
    defaultenv     => undef,
    continue       => undef,

    w32make        => undef,
    w32cc          => undef,
    v              => undef,
);

my $defaults = Test::Smoke::Smoker->config( 'all_defaults' );

=head1 NAME

runsmoke.pl - Configure, build and test bleading edge perl

=head1 SYNOPSIS

    $ ./runsmoke.pl [options] <buildcfg>

=head1 OPTIONS

Most of the F<mktest.pl> switches are implemented for backward 
compatibility, but some had to go in faviour of the new regime of 
front-ends.

=over 4

=item Configuration file

    --config|-c <configfile>  Use the settings from the configfile

F<runsmoke.pl> can use the configuration file created by
F<configsmoke.pl>.  Other options can override the settings 
from the configuration file. If the config-filename is ommited 
B<smokecurrent_config> is assumed.

=item Overridable options

These options will also override the values in the configfile 
(if the C<--config> switch is used).

    --fdir|--forest|-f <dir>  Set the basedir for forest
    --locale|-l <somelocale>  Set the UTF-8 for special testrun
    --[no]force-c-locale      Force (or not) $ENV{LC_ALL}="C"
    --[no]is56x               This is (not) a perl 5.6.x smoke
    --[no]defaultenv          This is (not) a non $ENV{PERLIO} smoke

    --ddir|-d <dir>           Set the build directory
    --cfg <buildcfg>
    --killtime|-k <killtime>  Set a killtime
    --verbose|-v <0..2>       Verbose level

=item Win32 options (overridable)

    --w32cc|--win32-cctype    <BORLAND|GCC|MSVC20|MSVC|MSVC60>
    --w32make|--win32-maker   <dmake|nmake>


=item General options

    --continue                Try to continue an aborted smoke
    --[no]run
    --dry-run|-n              dry run...
    --help|-h                 This message
    --man                     The full manpage

=back

=head1 DESCRIPTION

F<runsmoke.pl> is the replacement script for F<mktest.pl> (which is now 
depricated and will not be maintained).

=cut

my $myusage = "Usage: $0 [options] <buildcfg>";
GetOptions( \%opt,
    'config|c:s', 'ddir|d=s',
    'cfg=s',
    'fdir|forest|f=s',
    'locale|l=s',
    'force_c_locale|force-c-locale!',
    'defaultenv!', 'is56x!',
    'killtime|k=s',

    'w32make|win32-maker|m=s',
    'w32cc|win32-cctype=s',

    'dry_run|dry-run|n', 'run!',
    'continue!',
    'v|verbose=i',

    'help|h', 'man',
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
            if ( $option eq 'dry_run' ) {
                $opt{run} ||= ! $opt{dry_run};
            } elsif ( exists $conf->{ $option } ) {
                $opt{ $option } ||= $conf->{ $option }
            }
        }
    } else {
        warn "WARNING: Could not process '$opt{config}': " . 
             Test::Smoke->config_error . "\n";
    }
}

$opt{cfg} = shift @ARGV if ! $opt{cfg} && @ARGV && -f $ARGV[0];
$opt{run} = 0 if $opt{dry_run};
foreach ( keys %$defaults ) {
    next if defined $opt{ $_ };
    $opt{ $_ } = exists $conf->{ $_ } ? $conf->{ $_ } : $defaults->{ $_ };
}

# transfer %opt to %$conf
$conf->{ $_ } = $opt{ $_ } for keys %opt;
@ARGV and push @{ $conf->{w32args} }, @ARGV;

$conf->{ddir} and do {
    $conf->{v} and print "[$0] chdir($conf->{ddir})\n";
    chdir $conf->{ddir} or die "Cannot chdir($conf->{ddir}): $!";
};
my $timeout = 0;
if ( $Config{d_alarm} && $conf->{killtime} ) {
    $timeout = calc_timeout( $conf->{killtime} );
    $conf->{v} and printf "Setup alarm: %s\n",
			   scalar localtime( time() + $timeout );
}
$timeout and local $SIG{ALRM} = sub {
    warn "This smoke is aborted ($conf->{killtime})\n";
    exit;
};
$Config{d_alarm} and alarm $timeout;

run_smoke( $conf->{continue} );

=head1 SEE ALSO

L<Test::Smoke>, L<Test::Smoke::Smoker>

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
