use strict;
use warnings;
use Test::More tests => 1;
use Date::Language;

# RT#17396: Parse error for french date with 'mars' (march) as month
{
    my $dateP     = Date::Language->new('French');
    my $timestamp = $dateP->str2time('4 mars 2005');
    my ($ss, $mm, $hh, $day, $month, $year, $zone) = localtime $timestamp;
    $month++;
    $year += 1900;
    my $date = "$day/$month/$year";
    is($date, "4/3/2005", "RT#17396: French 'mars' parsed correctly");
}
