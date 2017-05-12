#! /usr/bin/perl -w
use strict;
$| = 1;

# $Id$
use vars qw( $VERSION );
$VERSION = '0.005';

use Cwd;
use File::Spec::Functions;
use File::Path;
use File::Copy;
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use lib $FindBin::Bin;
use Test::Smoke;
use Test::Smoke::Util qw( get_patch do_pod2usage );

my $myusage = "Usage: $0 -d <builddir> -a <archivedir> -l <logfile> [options]";
use Getopt::Long;
my %opt = (
    ddir    => undef,
    adir    => undef,
    lfile   => undef,
    force   => undef,
    v       => undef,

    config  => undef,
    help    => 0,
    man     => 0,
);

=head1 NAME

archiverpt.pl - Patch the sourcetree

=head1 SYNOPSIS

    $ ./archiverpt.pl -a archive -d ../perl-current -l smokecurrent.log

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
    -a | --adir <directory>  Set the direcory for the archive
    -l | --lfile <logfile>   Set the (optional) logfile
    --[no]force              Overwrite existsing archives

    -v | --verbose <0..2>    Set verbose level
    -h | --help              Show help message (needs Pod::Usage)
    --man                    Show the perldoc  (needs Pod::Usage)

=back

=head1 DESCRIPTION

This is a small program that archives the smokereport and logfile like:

    report  -> <adir>/rpt<patchlevel>.rpt
    logfile -> <adir>/log<patchlevel>.log

=cut

GetOptions( \%opt,
    'adir|a=s', 'ddir|d=s', 'lfile|l=s',

    'force!', 'v|verbose=i',

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

$opt{ddir} && -d $opt{ddir} or do_pod2usage(verbose => 0, myusage => $myusage);
$opt{adir} && -d $opt{adir} or do {
    mkpath( $opt{adir}, 0, 0775 ) or die "Cannot create '$opt{adir}': $!";
};

my $patch_level = get_patch( $opt{ddir} )->[0];
$patch_level =~ tr/ //sd;

SKIP_RPT: {
    my $archived_rpt = catfile( $opt{adir}, "rpt${patch_level}.rpt" );
    # Do not archive if it is already done
    last SKIP_RPT
        if -f $archived_rpt && !$opt{force};

    my $mktest_rpt = catfile( $opt{ddir}, 'mktest.rpt' );
    if ( -f $mktest_rpt ) {
        copy( $mktest_rpt, $archived_rpt ) or
            die "Cannot copy to '$archived_rpt': $!";
    }
}

SKIP_OUT: {
    my $archived_out = catfile( $opt{adir}, "out${patch_level}.out" );
    # Do not archive if it is already done
    last SKIP_OUT
        if -f $archived_out && !$opt{force};

    my $mktest_out = catfile( $opt{ddir}, 'mktest.out' );
    if ( -f $mktest_out ) {
        copy( $mktest_out, $archived_out ) or
            die "Cannot copy to '$archived_out': $!";
    }
}

SKIP_LOG: {
    my $archived_log = "log${patch_level}.log";
    unless ( defined $opt{lfile} ) {
        $opt{v} and print "No logfile defined!\n";
        last SKIP_LOG;
    }
    unless ( -f $opt{lfile} ) {
        $opt{v} and print "Logfile '$opt{lfile}' not found!\n";
        last SKIP_LOG;
    }
    copy( $opt{lfile}, File::Spec->catfile( $opt{adir}, $archived_log ) ) or
        die "Cannot copy to '$archived_log': $!";
}

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
