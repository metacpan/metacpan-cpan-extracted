#!perl
#
# This file is part of Time::Fuzzy.
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

BEGIN {
    # some cpan testers have a weird env with no local timezone.
    $ENV{TZ} = 'UTC';
}

use Test::More tests => 39;
use Time::Fuzzy;

my $dt = DateTime->new(year=>1976);


# fuzziness: high.
$Time::Fuzzy::FUZZINESS = 'high';
$dt->set(month=>10); 
$dt->set(day=>18); is( fuzzy($dt), 'start of week',  'fuzzy() - high usage monday' );
$dt->set(day=>19); is( fuzzy($dt), 'middle of week', 'fuzzy() - high usage tuesday' );
$dt->set(day=>20); is( fuzzy($dt), 'middle of week', 'fuzzy() - high usage wednesday' );
$dt->set(day=>21); is( fuzzy($dt), 'middle of week', 'fuzzy() - high usage thursday' );
$dt->set(day=>22); is( fuzzy($dt), 'end of week',    'fuzzy() - high usage friday' );
$dt->set(day=>23); is( fuzzy($dt), 'week-end!',      'fuzzy() - high usage saturday' );
$dt->set(day=>24); is( fuzzy($dt), 'week-end!',      'fuzzy() - high usage sunday' );
like( fuzzy(),    qr/^week|week$/, 'fuzzy() - high usage without param' );


# fuzziness: medium.
$Time::Fuzzy::FUZZINESS = 'medium';
$dt->set(hour=>0);  is( fuzzy($dt), 'night',         'fuzzy() - medium usage 0h' );
$dt->set(hour=>1);  is( fuzzy($dt), 'night',         'fuzzy() - medium usage 1h' );
$dt->set(hour=>2);  is( fuzzy($dt), 'night',         'fuzzy() - medium usage 2h' );
$dt->set(hour=>3);  is( fuzzy($dt), 'night',         'fuzzy() - medium usage 3h' );
$dt->set(hour=>4);  is( fuzzy($dt), 'night',         'fuzzy() - medium usage 4h' );
$dt->set(hour=>5);  is( fuzzy($dt), 'early morning', 'fuzzy() - medium usage 5h' );
$dt->set(hour=>6);  is( fuzzy($dt), 'early morning', 'fuzzy() - medium usage 6h' );
$dt->set(hour=>7);  is( fuzzy($dt), 'early morning', 'fuzzy() - medium usage 7h' );
$dt->set(hour=>8);  is( fuzzy($dt), 'morning',       'fuzzy() - medium usage 8h' );
$dt->set(hour=>9);  is( fuzzy($dt), 'morning',       'fuzzy() - medium usage 9h' );
$dt->set(hour=>10); is( fuzzy($dt), 'morning',       'fuzzy() - medium usage 10h' );
$dt->set(hour=>11); is( fuzzy($dt), 'noon',          'fuzzy() - medium usage 11h' );
$dt->set(hour=>12); is( fuzzy($dt), 'noon',          'fuzzy() - medium usage 12h' );
$dt->set(hour=>13); is( fuzzy($dt), 'noon',          'fuzzy() - medium usage 1"h' );
$dt->set(hour=>14); is( fuzzy($dt), 'afternoon',     'fuzzy() - medium usage 14h' );
$dt->set(hour=>15); is( fuzzy($dt), 'afternoon',     'fuzzy() - medium usage 15h' );
$dt->set(hour=>16); is( fuzzy($dt), 'afternoon',     'fuzzy() - medium usage 16h' );
$dt->set(hour=>17); is( fuzzy($dt), 'afternoon',     'fuzzy() - medium usage 17h' );
$dt->set(hour=>18); is( fuzzy($dt), 'afternoon',     'fuzzy() - medium usage 18h' );
$dt->set(hour=>19); is( fuzzy($dt), 'evening',       'fuzzy() - medium usage 19h' );
$dt->set(hour=>20); is( fuzzy($dt), 'evening',       'fuzzy() - medium usage 20h' );
$dt->set(hour=>21); is( fuzzy($dt), 'evening',       'fuzzy() - medium usage 21h' );
$dt->set(hour=>22); is( fuzzy($dt), 'late evening',  'fuzzy() - medium usage 22h' );
$dt->set(hour=>23); is( fuzzy($dt), 'late evening',  'fuzzy() - medium usage 23h' );
like( fuzzy(),    qr/ning|noon|night/, 'fuzzy() - medium usage without param' );



# fuzziness: low.
$Time::Fuzzy::FUZZINESS = 'low';
$dt->set(hour=>8,minute=>2);
is( fuzzy($dt), "eight o'clock", 'fuzzy() - low usage' );
$dt->set(minute=>3); # should be enough to go to next sector
is( fuzzy($dt), 'five past eight', 'fuzzy() - low usage' );
$dt->set( hour=>23, minute=>58);
is( fuzzy($dt), 'midnight', 'fuzzy() - low usage, midnight case (just before)' );
$dt->set(hour=>0,minute=>1);
is( fuzzy($dt), 'midnight', 'fuzzy() - low usage, midnight case' );
$dt->set(hour=>11,minute=>59);
is( fuzzy($dt), 'noon', 'fuzzy() - low usage, noon case (just before)' );
$dt->set(hour=>12,minute=>0);
is( fuzzy($dt), 'noon', 'fuzzy() - low usage, noon case' );



exit;
