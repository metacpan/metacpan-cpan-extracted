use strict;
use warnings;
use Test::More tests => 5;
use Date::Parse qw(strptime str2time);

# RT#48164: Date::Parse unable to set seconds correctly
{
    for my $str ("2008.11.30 22:35 CET", "2008-11-30 22:35 CET") {
        my @t = strptime($str);
        my $t = join ":", map { defined($_) ? $_ : "-" } @t;
        is($t, "-:35:22:30:10:108:3600:20", "RT#48164: seconds parsing for '$str'");
    }
}

# RT#17396: Parse error for french date with 'mars' (march) as month
{
    use Date::Language;
    my $dateP     = Date::Language->new('French');
    my $timestamp = $dateP->str2time('4 mars 2005');
    my ($ss, $mm, $hh, $day, $month, $year, $zone) = localtime $timestamp;
    $month++;
    $year += 1900;
    my $date = "$day/$month/$year";
    is($date, "4/3/2005", "RT#17396: French 'mars' parsed correctly");
}

# RT#51664: Change in str2time behaviour between 1.16 and 1.19
{
    ok(str2time('16 Oct 09') >= 0, "RT#51664: '16 Oct 09' parses to non-negative time");
}

# RT#84075: Date::Parse::str2time maps date in 1963 to 2063
{
    my $this_year = 1900 + (gmtime(time))[5];
    my $target_year = $this_year - 50;
    my $date = "$target_year-01-01 00:00:00 UTC";
    my $time = str2time($date);
    my $year_parsed_as = 1900 + (gmtime($time))[5];
    is($year_parsed_as, $target_year, "RT#84075: year $target_year not mapped to future");
}
