#!/usr/bin/perl
# create Config_mini.pl for CPAN if not created already by cperl core
#usage: perl Config_mini.pl.PL [ignored]

use strict ;
my $VERSION = '6.26';
use ExtUtils::Command;

my $mini = searchdirs('Config_mini.pl', \@INC);
if ($mini) {
    warn "found Config_mini.pl at $mini\n";

    require './xsc_test.pl'; #Config_mini.pl.PL not in cperl, no eval needed
    # test if Config_mini.pl is usuable in a seperate process since
    # Config_mini.pl might be so broken that the ExtUtils::Command::cp later on
    # might need something from %Config and %Config is broken after the broken
    # Config_mini.pl was half loaded into the process
    my $ret = runperl(progfile=> $mini, stderr => 1);
    # installed Config_mini.pl unusable, a possible perl maint upgrade happened
    if ($ret ne '') {
        undef($mini);# pretend we never found Config_mini.pl
    } else {
        @ARGV = ($mini, 'Config_mini.pl');
    }
}
if (! $mini) { #create it
# there will be 2 Config.pm'es in @INC if XSConfig was installed before
    my @cfgs = searchdirslist('Config.pm', \@INC);
    my $cfg;
    foreach(@cfgs) {
        my $cfgdata;
        {
            open(my $fh, "<", $_) or die $!;
            local $/; # enable localized slurp mode
            $cfgdata = <$fh>;
            close $fh;
        }
        warn "found Config.pm at $_\n";
        if (index($cfgdata, 'Config_mini.pl') != -1) {
            warn "Found Config.pm is XS Config.pm, but sister file "
                 ."Config_mini.pl was not found, broken XS Config install?";
        } else {
            $cfg = $_;
            last;
        }
    }
    die "Couldn't find a PP Config.pm" unless $cfg;
    @ARGV = ($cfg, 'Config_mini.pl');
}

cp();
die 'failed chmod on Config_mini.pl'
    if CORE::chmod(0777, 'Config_mini.pl') != 1; #avoid EU::C's chmod for speed
@ARGV = ('Config_mini.pl');  #make tools complain file created but timestamp
touch(); # not updated, and rerun Config_mini.pl.PL on >= 2nd "make all"

sub searchdirs {
    my($fn, $fullfn) = shift;
    foreach my $d ( @{$_[0]} ) {
        my $tmppath = $d.'/'.$fn;
        if (-s $tmppath) {
            $fullfn = $tmppath;
            last;
        }
    }
    return $fullfn;
}

sub searchdirslist {
    my($fn, $fullfn) = shift;
    my @ret;
    foreach my $d ( @{$_[0]} ) {
        my $tmppath = $d.'/'.$fn;
        if (-s $tmppath) {
            push @ret, $tmppath;
        }
    }
    return @ret;
}
