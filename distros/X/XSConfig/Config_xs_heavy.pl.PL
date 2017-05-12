#!/usr/bin/perl
# create Config_xs_heavy.pl for CPAN from Config_heavy.pl in @INC
#usage: perl Config_xs_heavy.pl.PL [ignored]

use strict ;
my $VERSION = '6.00';

my $heavyfn = searchdirs('Config_heavy.pl', \@INC);
die 'Config_heavy.pl not found' unless $heavyfn;
my $cfgdata;
{
    open(my $fh, '<', $heavyfn) or die $!;
    local $/; # enable localized slurp mode
    $cfgdata = <$fh>;
    close $fh;
};


my $replace = '# This file was created by configpm when Perl was built. Any changes
# made to this file will be lost the next time perl is built.';
$cfgdata =~ s/$replace/# This file was created by Config_xs_heavy.pl.PL./;

my $pos1st = index($cfgdata, q|local *_ = \my $a;
$_ = <<'!END!';|);
die 'Config_heavy.pl cant match' if $pos1st == -1;

my $pos2nd = index($cfgdata, 'sub config_vars {', $pos1st);
die 'Config_heavy.pl cant match' if $pos2nd == -1;

$cfgdata  = substr($cfgdata, 0, $pos1st).
q|sub STORE  { die "\%Config::Config is read-only\n" }
*DELETE = *CLEAR = \*STORE; # Typeglob aliasing uses less space

sub config_sh {
    my $s = ' ' x 32000; # prealloc 32.000 byte, I got 33568
    $s = '';
    for my $k (sort &Config::KEYS) { # XXX sort Config::KEYS() is broken
        my $v = Config->FETCH($k);
        $s .= defined $v ? "$k='$v'\n" : "$k=''\n";
    }
    $s
}

sub config_re {
    my $re = shift or return ();
    my @s;
    for my $k (sort &Config::KEYS) {
       if (eval { $k =~ /^(?:$re)/ }) {
            my $v = Config->FETCH($k);
            push @s, defined $v ? "$k='$v'" : "$k=''";
        }
    }
    sort @s
}

|
. substr($cfgdata, $pos2nd);
{
    open(my $fh, '>', 'Config_xs_heavy.pl') or die $!;
    syswrite($fh, $cfgdata);
    close $fh;
}

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
