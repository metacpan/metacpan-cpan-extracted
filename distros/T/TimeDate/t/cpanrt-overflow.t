use strict;
use warnings;
use Test::More tests => 3;
use Date::Parse qw(str2time);

# RT#88777: str2time for far-future dates must not return negative epoch
# On 32-bit platforms timegm() overflows for years beyond ~2038, returning
# a wrong negative (or wrapping) value.  str2time() must detect this and
# return undef rather than a nonsense negative epoch.
{
    my @cases = (
        [ "2900/01/01 00:00:00", "year 2900" ],
        [ "3000/01/01 00:00:00", "year 3000" ],
        [ "3870/01/01 00:59:59", "year 3870 (exact RT date)" ],
    );

    for my $c (@cases) {
        my ($date, $desc) = @$c;
        my $t = str2time($date);
        ok( !defined($t) || $t >= 0,
            "RT#88777: $desc returns undef or non-negative epoch (got "
            . ( defined $t ? $t : "undef" ) . ")" );
    }
}
