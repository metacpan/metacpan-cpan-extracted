use strict;
use warnings;
use Test::More tests => 15;
use Date::Parse qw(str2time);
use Time::Zone;

# IST (Indian Standard Time) should resolve to UTC+5:30
{
    my $offset = tz_offset("ist");
    is($offset, 19800, "tz_offset('ist') returns 19800 (UTC+5:30)");

    my $time = str2time("2024-01-15 12:00:00 IST");
    my $time_utc = str2time("2024-01-15 06:30:00 UTC");
    is($time, $time_utc, "IST date parses to correct UTC equivalent");
}

# RT#76968: tz2zone("America/Chicago") doesn't work
# IANA timezone names like "America/Chicago" should be usable with tz_offset
{
    use POSIX qw();

  SKIP: {
        # Verify that the system supports IANA timezone names
        my $has_iana = eval {
            local $ENV{TZ} = "Etc/UTC";
            POSIX::tzset();
            my ($std) = POSIX::tzname();
            defined $std && $std =~ /UTC|GMT/i;
        };
        skip "system does not support IANA timezone names", 6 unless $has_iana;

        # tz_offset with IANA name "Etc/UTC" must return 0 (deterministic)
        my $utc_offset = tz_offset("Etc/UTC");
        is($utc_offset, 0, "RT#76968: tz_offset('Etc/UTC') returns 0");

        # tz2zone with IANA name "Etc/UTC" must return a valid abbreviation
        my $utc_name = tz2zone("Etc/UTC", undef, 0);
        ok(defined $utc_name && length($utc_name) > 0,
            "RT#76968: tz2zone('Etc/UTC') returns a defined non-empty name");

        # tz_offset(tz2zone(IANA_name)) must return defined — the key failure in the bug
        my $chicago_abbr = tz2zone("America/New_York", undef, 0);
        ok(defined $chicago_abbr,
            "RT#76968: tz2zone('America/New_York', dst=0) returns defined");

        my $chicago_offset = tz_offset($chicago_abbr);
        ok(defined $chicago_offset,
            "RT#76968: tz_offset(tz2zone('America/New_York')) returns defined");

        # tz_offset of IANA name directly must return defined
        my $ny_offset = tz_offset("America/New_York");
        ok(defined $ny_offset,
            "RT#76968: tz_offset('America/New_York') returns defined");

        # tz_offset("Etc/UTC") via tz2zone round-trip
        my $utc_abbr = tz2zone("Etc/UTC", undef, 0);
        my $utc_offset2 = tz_offset($utc_abbr);
        is($utc_offset2, 0,
            "RT#76968: tz_offset(tz2zone('Etc/UTC')) returns 0");
    }
}

# RT#59298: tz_name() reports incorrect offset for unknown timezone names
# The offset passed is in seconds, but the old code treated it as minutes,
# producing e.g. "+33000" for IST (+5:30) instead of "+0530".
# Also: negative fractional-hour offsets must format correctly.
{
    # UTC+5:30 = 19800s — not in the Zone table when the bug was filed
    is(tz_name(19800, 0), "ist",   "RT#59298: tz_name(19800) returns ist (UTC+5:30 is now in table)");
    # An offset not in the table: UTC+1:30 = 5400s → "+0130" (was "+9000" before fix)
    is(tz_name(5400, 0),  "+0130", "RT#59298: tz_name(5400) returns +0130, not +9000");
    # Negative fractional offset: UTC-1:30 = -5400s → "-0130"
    # (Note: -9000 is now NDT/Newfoundland Daylight, so use -5400 instead)
    is(tz_name(-5400, 0), "-0130", "RT#59298: tz_name(-5400) returns -0130 (UTC-1:30)");
}

# RT#82271: tz_name should return CEST (not MEST) for Central European Summer Time
# CEST (Central European Summer Time) is the standard/preferred abbreviation;
# MEST (Middle European Summer Time) is a German-influenced variant.
{
    is(tz_name(7200, 1),  "cest", "RT#82271: tz_name(+2h, dst=1) returns cest not mest");
    is(tz_offset("MEST"), 7200,   "RT#82271: tz_offset(MEST) still works for backward compat");
}

# RT#98949: Moscow Time Change in October 2014
# MSK (Moscow Standard Time) is UTC+3 permanently since 25 Oct 2014.
# Russia eliminated DST in 2011 (UTC+4 year-round), then reverted to UTC+3 in Oct 2014.
{
    my $offset = tz_offset("msk");
    is($offset, 10800, "RT#98949: tz_offset('msk') returns 10800 (UTC+3)");

    my $time     = str2time("2014-10-27 00:00:00 MSK");
    my $time_utc = str2time("2014-10-26 21:00:00 UTC");
    is($time, $time_utc, "RT#98949: MSK date after 2014 change parses to correct UTC");
}
