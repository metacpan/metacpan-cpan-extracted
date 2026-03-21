use strict;
use warnings;
use Test::More tests => 5;
use Date::Parse qw(str2time);

# RT#64789: str2time() should accept an optional epoch as third argument
# to use as the reference time instead of time() when filling in missing
# date components (month, day, year).
{
    # Use a known fixed epoch as the reference time:
    # 2010-06-15 12:00:00 UTC = 1276603200
    my $ref_epoch = 1276603200;  # 2010-06-15 12:00:00 UTC

    # Parsing "21 feb" with no year: February (month 1) < June (month 5),
    # so February is in the past — most recent occurrence is current year (2010).
    my $t = str2time("21 feb 17:05 UTC", undef, $ref_epoch);
    ok(defined $t, "RT#64789: str2time with epoch arg returns defined");
    my $parsed_year = 1900 + (gmtime($t))[5];
    is($parsed_year, 2010, "RT#64789: 'feb' with epoch 2010-06 stays in 2010 (most recent occurrence)");

    # Parsing a time-only string: "10:30:00 UTC"
    # With ref_epoch (2010-06-15), the date portion should come from ref_epoch
    my $t2 = str2time("10:30:00 UTC", undef, $ref_epoch);
    ok(defined $t2, "RT#64789: time-only str2time with epoch arg returns defined");
    my @gm2 = gmtime($t2);
    is($gm2[3], 15, "RT#64789: time-only: day from ref_epoch");
    is(1900 + $gm2[5], 2010, "RT#64789: time-only: year from ref_epoch");
}
