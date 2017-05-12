#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use lib "$FindBin::RealBin";

use Tk;
use Tk::DateEntry;
use TkTest qw(catch_grabs);

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

my $mw = eval { MainWindow->new };
if (!$mw) {
    print "1..0 # skip: cannot create MainWindow: $@";
    exit;
}
$mw->geometry('+1+1');

plan tests => 5;

my $date;
my $de = $mw->DateEntry(-dateformat => 4,
			-textvariable => \$date,
			-todaybackground => "green",
		       )->pack;

$mw->update; $mw->after(200);
# The used members are internals, do not use in regular programs!
$mw->after(1200, sub {
	       $de->{_daybutton}->[2]->[3]->invoke;
	   });
catch_grabs {
    $de->buttonDown;
    $mw->update;
    # This blocks until a date is clicked
    my $iso_date_qr = qr/^(\d{4})-(\d{2})-(\d{2})$/;
    like($date, $iso_date_qr, "Got ISO date");

    my($y,$m,$d) = $date =~ $iso_date_qr;
    $y+=0; # make numeric
    $m+=0;
    $d+=0;
    my(undef,undef,undef,undef,$this_month,$this_year) = localtime; $this_month++; $this_year+=1900;
    is($y, $this_year, "Expected year $this_year");
    is($m, $this_month, "Expected month $this_month");
    cmp_ok($d, ">=", 1, "Day in expected range, min");
    cmp_ok($d, "<=", 31, "Day in expected range, max");
} 5;

__END__
