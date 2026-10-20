#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

use Time::Keeper;
use Time::Keeper::Natural;

my $N = 'Time::Keeper::Natural';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

my $pinned = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
local $Time::Keeper::CLOCK = $pinned;

# Every option, taken and read back.
{
    my $t = Time::Keeper->new(year => 2026, month => 1, day => 2, zone => 'Asia/Tokyo', locale => 'ja');
    my $n = $N->new(now => $t, zone => 'Europe/Paris', locale => 'fr-CA', bare_hour => 'pm', prefer => 'future');
    isa_ok($n, $N);
    is($n->now->epoch, $t->epoch, 'now is the anchor');
    is($n->now->zone_name, 'Europe/Paris', 'in the zone given');
    is($n->zone, 'Europe/Paris', 'zone');
    is($n->locale, 'fr-CA', 'locale, canonical');
    is($N->new(locale => 'fr_ca')->locale, 'fr-CA', 'a code in another spelling is canonical too');
    is($n->bare_hour, 'pm', 'bare_hour');
    is($n->prefer, 'future', 'prefer');
}

# What is wrong dies from new, by name.
{
    dies_like(sub { $N->new(colour => 'red') }, qr/^\Q$N->new: 'colour' is not an option; the options are now, zone, locale, bare_hour, prefer, keep_zone and calendar\E/, 'an unknown option');
    dies_like(sub { $N->new(zone => 'UTC', zone => 'UTC') }, qr/^\Q$N->new: zone is given twice\E/, 'a repeated option');
    dies_like(sub { $N->new('zone') }, qr/^\Q$N->new: the options are name and value pairs\E/, 'an odd list');
    dies_like(sub { $N->new(now => '2026-10-15') }, qr/^\Q$N->new: now is a Time::Keeper value\E/, 'now that is not a value');
    dies_like(sub { $N->new(now => Time::Keeper::Duration->new(hours => 1)) }, qr/now is a Time::Keeper value/, 'nor a duration');
    dies_like(sub { $N->new(zone => 'Nowhere/Here') }, qr/^\Q$N->new: no time zone named 'Nowhere\/Here'\E/, 'a zone that is not there');
    dies_like(sub { $N->new(locale => 'xx-YY') }, qr/^\Q$N->new: there is no locale 'xx-YY'\E/, 'a locale that is not there');
    dies_like(sub { $N->new(bare_hour => 'noon') }, qr/^\Q$N->new: bare_hour is 'am', 'pm' or 'next', not 'noon'\E/, 'a bare_hour it does not know');
    dies_like(sub { $N->new(prefer => 'now') }, qr/^\Q$N->new: prefer is 'future' or 'past', not 'now'\E/, 'a prefer it does not know');
}

# The anchor is the clock, and the zone and locale are the anchor's.
{
    my $n = $N->new;
    is($n->now->epoch, $pinned->epoch, 'the anchor is the pinned clock');
    is($n->now->zone_name, 'UTC', 'in UTC, as now is');
    is($n->zone, 'UTC', 'zone is UTC');
    is($n->locale, 'en', 'locale is English');
    is($N->zone, 'UTC', 'the class answers too');
    is($N->locale, 'en', 'and its locale');
    my $later = $pinned->plus(hours => 2);
    {
        local $Time::Keeper::CLOCK = $later;
        is($n->now->epoch, $later->epoch, 'the clock is read on every call');
    }
    is($n->now->epoch, $pinned->epoch, 'and restored');
    my $t = Time::Keeper->new(year => 2026, month => 1, day => 2, zone => 'Asia/Tokyo', locale => 'ja');
    my $a = $N->new(now => $t);
    is($a->zone, 'Asia/Tokyo', 'with now, the zone is the anchor\'s');
    is($a->locale, 'ja', 'and so is the locale');
    is($N->new(zone => 'Asia/Tokyo')->now->zone_name, 'Asia/Tokyo', 'the clock read in the zone given');
    is($N->new(locale => 'fr')->now->locale, 'fr', 'and in the locale given');
}

# New parsers from old ones.
{
    my $n = $N->new(zone => 'Europe/London', locale => 'en', bare_hour => 'pm');
    my $fr = $n->in_locale('fr');
    is($fr->locale, 'fr', 'in_locale reads French');
    is($fr->zone, 'Europe/London', 'and keeps the zone');
    is($fr->bare_hour, 'pm', 'and the other options');
    is($n->locale, 'en', 'the old parser is as it was');
    is($n->in_zone('Asia/Tokyo')->zone, 'Asia/Tokyo', 'in_zone');
    is($n->in_zone('Asia/Tokyo')->locale, 'en', 'keeps the locale');
    my $m = $n->new(prefer => 'past', bare_hour => undef);
    is($m->prefer, 'past', 'new on a parser adds an option');
    is($m->zone, 'Europe/London', 'and keeps the rest');
    is($m->bare_hour, undef, 'undef drops one');
    is($N->in_locale('de')->locale, 'de', 'in_locale on the class');
}

# The class form takes options after the text; the instance form takes none.
{
    dies_like(sub { $N->parse('tomorrow', locale => 'fr') }, qr/no such word in fr/, 'the class form, with options');
    dies_like(sub { $N->new->parse('tomorrow', locale => 'fr') }, qr/^\Q$N->parse: options go to new, not to parse\E/, 'the instance form refuses them');
    dies_like(sub { $N->parse('tomorrow', colour => 'red') }, qr/'colour' is not an option/, 'and the class form checks them');
}

# The error form.
{
    my $n = $N->new;
    dies_like(sub { $n->parse('') }, qr/^\Q$N->parse: cannot read '' at '': the text is empty\E/, 'an empty text');
    dies_like(sub { $n->parse("  \t ") }, qr/cannot read '  \t ' at '': the text is empty/, 'a text of spaces');
    dies_like(sub { $n->parse(undef) }, qr/^\Q$N->parse: the text is undefined\E/, 'no text');
    dies_like(sub { $n->parse('xyzzy plugh') }, qr/^\Q$N->parse: cannot read 'xyzzy plugh' at 'xyzzy': no such word in en\E/, 'a word it does not know, the first named');
    dies_like(sub { $n->parse('  xyzzy  ') }, qr/cannot read '  xyzzy  ' at 'xyzzy': no such word in en/, 'the text as given, the token trimmed');
    dies_like(sub { $n->in_locale('fr')->parse('xyzzy') }, qr/no such word in fr/, 'the locale named');
    dies_like(sub { $n->parse_date('xyzzy') }, qr/^\Q$N->parse_date: cannot read 'xyzzy' at 'xyzzy'\E/, 'parse_date names itself');
    dies_like(sub { $n->parse_duration('xyzzy') }, qr/^\Q$N->parse_duration: cannot read 'xyzzy' at 'xyzzy'\E/, 'so does parse_duration');
    is($n->match('xyzzy'), undef, 'match of nothing is undef');
}

# The try_ forms give undef and leave $@ alone.
{
    my $n = $N->new;
    for my $m (qw(try_parse try_parse_date try_parse_duration)) {
        local $@ = 'left alone';
        is($n->$m('xyzzy'), undef, "$m gives undef");
        is($@, 'left alone', 'and leaves $@');
        is($N->$m('xyzzy', locale => 'fr'), undef, 'in the class form too');
        is($n->$m(''), undef, 'for an empty text');
        is($n->$m(undef), undef, 'and for none');
    }
}

# Coverage: English has a word table, the rest read the data.
{
    is($N->coverage('en'), 'words', 'English has words');
    is($N->coverage('sw'), 'data', 'Swahili is data');
    is($N->new->coverage('tr'), 'data', 'on a parser too');
    dies_like(sub { $N->coverage('xx-YY') }, qr/^\Q$N->coverage: there is no locale 'xx-YY'\E/, 'a locale that is not there');
    is_deeply([$N->locales], [qw(ar bn de el en es fr hi it ja ko nl pt ru th zh)], 'the locales with a table');
}

done_testing;
