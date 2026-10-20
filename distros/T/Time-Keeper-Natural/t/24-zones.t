#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# A zone after a time: read in that zone, then brought into the parser's
# unless keep_zone. The clock is Thursday 15 October 2026, 09:00 in London,
# when London is on BST, New York on EDT and Paris on CEST.
my $N = 'Time::Keeper::Natural';
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
sub p {
    my ($loc, $text, @opt) = @_;
    my $v = eval { $N->new(locale => $loc, zone => 'Europe/London', @opt)->parse($text) };
    return $v ? "$v" : "died: $@";
}
sub k { p(@_, keep_zone => 1) }

# Brought into the parser's zone.
is(p('en-US', '3 pm EDT'), '2026-10-15T20:00:00+01:00', 'en-US 3 pm EDT');
is(p('en-US', '3 pm EST'), '2026-10-15T21:00:00+01:00', 'en-US 3 pm EST: standard time, an hour later than EDT');
is(p('en-GB', '15:30 BST'), '2026-10-15T15:30:00+01:00', 'en-GB 15:30 BST');
is(p('en-GB', '15:30 GMT'), '2026-10-15T16:30:00+01:00', 'en-GB 15:30 GMT');
is(p('en-GB', '15:30 Europe/Paris'), '2026-10-15T14:30:00+01:00', 'an IANA name');
is(p('en-GB', '9:00 UTC'), '2026-10-15T10:00:00+01:00', 'UTC');
is(p('en-GB', '9:00 GMT+2'), '2026-10-15T08:00:00+01:00', 'the GMT format');
is(p('en-GB', '9:00 +05:30'), '2026-10-15T04:30:00+01:00', 'an offset');
is(p('en-GB', 'tomorrow 9:00 America/New_York'), '2026-10-16T14:00:00+01:00', 'a relative day in the named zone');
is(p('en-GB', '15 October 2026 15:30 Asia/Tokyo'), '2026-10-15T07:30:00+01:00', 'a date and time');
is(p('en-US', 'October 20, 2026 3 PM PST'), '2026-10-21T00:00:00+01:00', 'across midnight in London');
is(p('fr', '15:30 heure d’été d’Europe centrale'), '2026-10-15T14:30:00+01:00', 'fr: a long name');
is(p('fr', '15:30 UTC+2'), '2026-10-15T14:30:00+01:00', 'fr: its GMT format');

# Kept in the text's zone: each name keeps its own offset in either season.
is(k('en-US', '3 pm EST'), '2026-10-15T15:00:00-05:00', 'EST in October is -05:00');
is(k('en-US', '3 pm EDT'), '2026-10-15T15:00:00-04:00', 'EDT');
is(k('en-US', 'Jan 15, 2027 3 PM EDT'), '2027-01-15T15:00:00-04:00', 'EDT in January is -04:00');
is(k('en-US', 'Jan 15, 2027 3 PM EST'), '2027-01-15T15:00:00-05:00', 'EST in January');
is(k('en-US', '3:00 PM Eastern Standard Time'), '2026-10-15T15:00:00-05:00', 'a long standard name');
is(k('en-US', '3 pm Pacific Time'), '2026-10-15T15:00:00-07:00', 'a generic name follows the season');
is(k('en-GB', '15:30 Greenwich Mean Time'), '2026-10-15T15:30:00+00:00', 'Greenwich Mean Time in October');
is(k('en-GB', '15:30 British Summer Time'), '2026-10-15T15:30:00+01:00', 'British Summer Time');
is(k('en-GB', '15:30 Paris Time'), '2026-10-15T15:30:00+02:00', 'a city');
is(k('en', '15:30 CET'), '2026-10-15T15:30:00+01:00', 'CET is +01:00 in October too');
is(k('en', '15:30 CEST'), '2026-10-15T15:30:00+02:00', 'an abbreviation English has not, with one offset: CEST');
is(k('en', '9 am JST'), '2026-10-15T09:00:00+09:00', 'JST');
is(k('en', '9 am AEST'), '2026-10-15T09:00:00+10:00', 'AEST');
like(p('en', '9 am IST'), qr/^died: \Q$N\E->parse: cannot read '9 am IST' at 'IST': 'IST' names more than one zone in en at /, 'IST is India, Ireland and Israel');
is($N->new(locale => 'en', zone => 'Asia/Kolkata')->parse('9 am IST') . '', '2026-10-15T09:00:00+05:30', 'unless the parser\'s zone uses it');
like(p('en', 'xyzzy plugh'), qr/no such word in en/, 'a word that is no zone is not called ambiguous');
like(p('en-GB', 'next Tuesday zzz'), qr/at 'zzz': no such word in en-GB/, 'nor is a word after a phrase');

# Full dates and times as Time::Keeper writes them, with their zone: es-AR's
# "p. m." keeps its narrow no-break space, yue and Traditional Chinese set
# the time apart by a space, and eu wraps the zone inside the time's brackets.
for my $c (['es-AR', 'Europe/London'], ['yue', 'Europe/London'], ['zh-Hant', 'America/New_York'], ['eu', 'Asia/Tokyo'], ['zh', 'Europe/Paris']) {
    my ($loc, $z) = @$c;
    my $m = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 15, minute => 5, zone => $z, locale => $loc);
    for my $w (qw(full long)) {
        my $t = $m->format_datetime($w);
        my $v = eval { $N->new(locale => $loc, zone => 'Europe/London')->parse($t) };
        is($v ? $v->epoch : "died: $@", $m->epoch, "$loc $w: '$t'");
    }
}
is(p('th', 'พรุ่งนี้ เวลา 15:05'), '2026-10-16T15:05:00+01:00', 'th: a day and a time set apart by a space');

# The gap, and the Match.
is(k('en', 'March 8, 2026 2:30 AM America/New_York'), '2026-03-08T03:30:00-04:00', 'a time in the named zone\'s gap moves forward');
{
    my $n = $N->new(locale => 'en-US', zone => 'Europe/London');
    my $m = $n->match('3 pm EST');
    is($m->precision, 'hour', 'precision');
    is_deeply([$m->assumed], ['date'], 'the zone is not assumed');
    is_deeply([$n->match('3 pm')->assumed], [qw(date zone)], 'where the text names none it is');
    is($n->keep_zone, undef, 'keep_zone, unset');
    is($n->new(keep_zone => 1)->keep_zone, 1, 'and set');
    is(join(' / ', $n->parse_interval('9 am - 5 pm EST')), '2026-10-15T15:00:00+01:00 / 2026-10-15T23:00:00+01:00', 'a zone after an interval is both ends\'');
}

done_testing;
