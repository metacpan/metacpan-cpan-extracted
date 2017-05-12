#! /usr/bin/perl -w
use strict;
$| = 1;

# $Id$
use vars qw( $VERSION );
$VERSION = '0.014';

use Cwd;
use Time::Local;
use File::Spec::Functions;
use File::Path;
use File::Copy;
use FindBin;
use lib catdir( $FindBin::Bin, 'lib' );
use lib $FindBin::Bin;
use Test::Smoke;
use Test::Smoke::Reporter;
use Test::Smoke::Util qw( 
    do_pod2usage time_in_hhmm calc_timeout
    get_patch parse_report_Config );

my $myusage = "Usage: $0 -c [smokeconfig]";
use Getopt::Long;
Getopt::Long::Configure( 'bundling' );
my %opt = (
    dir     => undef,
    config  => undef,
    matrix  => undef,
    help    => 0,
    man     => 0,
);

=head1 NAME

smokestatus.pl - Check the status of a running smoke

=head1 SYNOPSIS

    $ ./smokestatus.pl -c [smokecurrent_config]

=head1 OPTIONS

=over 4

=item * B<All configurations>

    -a | --all                Find all *_config
    -r | --running            Check all *.lck

=item * B<Configuration file>

    -c | --config <configfile> Use the settings from the configfile

F<smokestatus.pl> uses the configuration file created by
F<configsmoke.pl>.

=item * B<Output options>

    -m | --matrix            Add the letter-matrix when possible

=item * B<General options>

    -d | --dir <directory>   Specify where the *_config files are
    -h | --help              Show help message (needs Pod::Usage)
    --man                    Show the perldoc  (needs Pod::Usage)

=back

=head1 DESCRIPTION

This is a small program that checks the status of a running smoke and
reports.

=cut

GetOptions( \%opt, qw(
    all|a      running|r
    dir|d=s
    matrix|m

    help|h     man

    config|c:s
)) or do_pod2usage( verbose => 1, myusage => $myusage );

do_pod2usage( verbose => 1, exitval => 1, myusage => $myusage )
    unless $opt{all} || $opt{running} || defined $opt{config};
$opt{ man} and do_pod2usage( verbose => 2, exitval => 0, myusage => $myusage );
$opt{help} and do_pod2usage( verbose => 1, exitval => 0, myusage => $myusage );

defined $opt{dir} or $opt{dir} = curdir();
$opt{dir} && -d $opt{dir} or $opt{dir} = '';
$opt{dir} ||= $FindBin::Bin;

my %save_opt = %opt;
my @configs = $opt{all} 
    ? get_configs() : $opt{running} ? get_lcks() : $opt{config};

print "$0-$VERSION Test::Smoke-$Test::Smoke::VERSION Test::Smoke::Reporter-$Test::Smoke::Reporter::VERSION\n\n";

foreach my $config ( @configs ) {
    %opt = %save_opt;
    $opt{config} = $config;
    process_args();
    print "\n" unless $config eq $configs[0];
    my $pver = $opt{perl_version} ? " ($opt{perl_version})" : "";
    print "Checking status for configuration '$opt{config}'$pver\n";
    my $rpt  = parse_out( { ddir => $opt{ddir} } ) or do {
        guess_status( $opt{ddir}, $opt{adir}, $opt{config} );
        next;
    };
    my $bcfg = Test::Smoke::BuildCFG->new( $conf->{cfg} );
    my $ccnt = 0;
    Test::Smoke::skip_config( $_ ) or $ccnt++ for $bcfg->configurations;

    printf "  Change number $rpt->{patch} started on %s.\n", 
           scalar localtime( $rpt->{started} );

    print "    $rpt->{ccount} out of $ccnt configurations finished",
          $rpt->{ccount} ? " in $rpt->{time}.\n" : ".\n";

    printf "    $rpt->{fail} configuration%s showed failures%s.\n",
           ($rpt->{fail} == 1 ? "":"s"), $rpt->{stat} ? " ($rpt->{stat})":""
        if $rpt->{ccount};

    printf "    $rpt->{running} failure%s in the running configuration.\n",
           ($rpt->{running} == 1 ? "" : "s")
        if exists $rpt->{running};

    my $todo = $ccnt - $rpt->{ccount};
    my $est_curr = $rpt->{avg} > 0
        ? $rpt->{avg} - ( $rpt->{rtime} - $rpt->{ccount}*$rpt->{avg} ) : 0;
    my $est_todo = $todo > 0 && $rpt->{avg} > 0
        ? ( (($todo - 1) * $rpt->{avg}) + $est_curr ) : 0;
    $est_todo > $todo * $rpt->{avg} and $est_todo = $todo * $rpt->{avg};
    my $killtime = calc_timeout( $conf->{killtime}, $rpt->{started} )
        ? timeout_msg( $conf->{killtime}, $rpt->{started } )
        : "";
    
    my $todo_time = $rpt->{avg} <= 0  ? '.' : 
        $est_todo <= 0 
            ? has_lck( $config )
                ? ", smoke looks hanging delay " . time_in_hhmm( -$est_todo )
                : ", smoke looks terminated${killtime}."
            : ", estimated completion in " . time_in_hhmm( $est_todo );

    printf "    $todo configuration%s to finish$todo_time\n",
           $todo == 1 ? "" : "s"
        if $todo;

    printf "    Average smoke duration: %s.\n", time_in_hhmm( $rpt->{avg} )
        if $rpt->{ccount};

    if ( $rpt->{ccount} > 0 && $opt{matrix} ) {
        printf "  Matrix, using %s:\n", $rpt->{reporter}->ccinfo;
        print join "", map "  $_\n" 
            => split /\n/, $rpt->{reporter}->smoke_matrix;
        print join "", map "  $_\n" 
            => split /\n/, $rpt->{reporter}->bldenv_legend;
    }
}

sub guess_status {
    my( $ddir, $adir, $config ) = @_;
    ( my $patch = get_patch( $ddir )->[0] || "" ) =~ s/\?//g;
    if ( $patch && $adir ) {
        my $a_rpt = catfile( $adir, "rpt${patch}.rpt" );
        my $mtime = -e $a_rpt ? (stat $a_rpt)[9] : undef;
        if ( $mtime ) {
            local *REPORT;
            my $status;
            if ( open REPORT, "< $a_rpt" ) {
                my $report = do { local $/; <REPORT> };
                close REPORT;
                my $summary = ( parse_report_Config( $report ) )[-1];
                $status = $summary ? " [$summary]" : "";
            }
            printf "  Change number %s%s finshed on %s\n", 
                   $patch, $status, scalar localtime( $mtime );
        } else {
            print "  Change number $patch found, but no (previous) results.\n";
        }
    } else {
        print "  No (previous) results for $config\n";
    }
}

sub parse_out {
    my( $conf ) = @_;

    return unless -f catfile $conf->{ddir}, 'mktest.out';

    my $reporter = Test::Smoke::Reporter->new( $conf );
    my %rpt = %{ $reporter->{_rpt} };

    $rpt{finished} ||= "Busy";
    $rpt{ccount} = scalar keys %{ $rpt{statcfg} };
    $rpt{avg}   = $rpt{ccount} ? $rpt{secs} / $rpt{ccount} : 0;
    $rpt{time}  = time_in_hhmm( $rpt{secs} );
    $rpt{rtime} = time() - $rpt{started};
    $rpt{fail} = 0; $rpt{stat} = { };

    my $fcnt = 0;
    foreach my $config ( keys %{ $rpt{statcfg} } ) {

        if ( $rpt{statcfg}{ $config } ) {
            $fcnt = $rpt{statcfg}{ $config };
            $rpt{statcfg}{ $config } = "F" 
                if $rpt{statcfg}{ $config } =~ /^\d+$/;

            $rpt{fail}++;
            $rpt{stat}->{ $rpt{statcfg}{ $config } }++;
        }
    }
    $rpt{stat} = join "", sort keys %{ $rpt{stat} };

    $rpt{reporter} = $reporter;
    return \%rpt    
}

sub get_configs {
    local *DH;
    opendir DH, $opt{dir} or return;
    my @list = grep /_config\z/ => readdir DH;
    closedir DH;
    return sort @list;
}

sub get_lcks {
    local *DH;
    opendir DH, $opt{dir} or return;
    my @list = map { s/\.lck\z/_config/; $_ } grep /\.lck\z/ => readdir DH;
    closedir DH;
    return sort @list;
}

sub has_lck {
    ( my $lck = shift ) =~ s/_config\z/.lck/;
    return -f File::Spec->catfile( $opt{dir}, $lck );
}

sub process_args {
    return unless defined $opt{config};

    $opt{config} eq "" and $opt{config} = 'smokecurrent_config';
    read_config( $opt{config} ) or do {
        my $config_name = File::Spec->catfile( $opt{dir}, $opt{config} );
        read_config( $config_name );
    };

    unless ( Test::Smoke->config_error ) {
        foreach my $option ( keys %$conf ) {
            $opt{ $option } = $conf->{ $option }, next 
              unless defined $opt{ $option };
            $conf->{ $option } = $opt{ $option }
        }
    } else {
        warn "WARNING: Could not process '$opt{config}': " . 
             Test::Smoke->config_error . "\n";
    }
}

sub timeout_msg {
    my( $killtime, $from ) = @_;

    defined $from or $from = time;
    if ( $killtime =~ /^\+(\d+):(\d+)/ ) {
        my( $hh, $mm ) = ( $1, $2 );
        $from += 60 * $mm;
        $from += 60 * 60 * $hh;
        return " from " . localtime $from;
    } else {
        my @lt = localtime $from;
        my( $hh, $mm ) = $killtime =~ /(\d+):(\d+)/;
        my $time_min = 60 * $hh + $mm;
        my( $now_m, $now_h ) = @lt[1, 2];
        my $now_min = 60 * $now_h + $now_m;
        my $kill_min = $time_min - $now_min;
        $kill_min += 60 * 24 if $kill_min < 0;

        $hh = int( $kill_min / 60 );
        $mm = $kill_min % 60;
        @lt[ 1, 2] = ( $mm, $hh );

        return " at " . localtime timelocal @lt;
    }
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
