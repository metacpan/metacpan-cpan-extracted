#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# A whole phrase CLDR writes for two offsets of one field: Hindi "कल" is
# yesterday and tomorrow. It dies naming both unless prefer picks, future
# the later and past the earlier, and the Match then assumes the direction.
my $A = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
local $Time::Keeper::CLOCK = $A;
sub p {
    my ($loc, $text, $prefer) = @_;
    my $n = Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London', prefer => $prefer);
    my $v = eval { $n->parse($text) };
    return $v ? "$v" : "died: $@";
}

like(p('hi', 'कल'), qr/^died: Time::Keeper::Natural->parse: cannot read 'कल' at 'कल': 'कल' means yesterday and tomorrow in hi; pass prefer at /, 'hi: कल dies naming both');
is(p('hi', 'कल', 'future'), '2026-10-16T00:00:00+01:00', 'prefer future: tomorrow');
is(p('hi', 'कल', 'past'), '2026-10-14T00:00:00+01:00', 'prefer past: yesterday');
like(p('hi', 'परसों'), qr/'परसों' means 2 days ago and in 2 days in hi; pass prefer/, 'hi: परसों, named in English where CLDR has no word for it');
is(p('hi', 'परसों', 'future'), '2026-10-17T00:00:00+01:00', 'prefer future: two days on');
is(p('hi', 'परसों', 'past'), '2026-10-13T00:00:00+01:00', 'prefer past: two days back');
like(p('ar', 'السبت القادم'), qr/'السبت القادم' means this Saturday and next Saturday in ar; pass prefer/, 'ar: this Saturday or next');
is(p('ar', 'السبت القادم', 'future'), '2026-10-17T00:00:00+01:00', 'prefer future: the later Saturday');
is(p('ar', 'السبت القادم', 'past'), '2026-10-10T00:00:00+01:00', 'prefer past: the earlier');
like(p('sd', 'پويون سال'), qr/means last year, this year and next year in sd/, 'sd: three readings, listed in order');
like(p('chr', 'ᎯᎠ ᎧᎸ.'), qr/cannot read 'ᎯᎠ ᎧᎸ\.' at 'ᎯᎠ ᎧᎸ\.': 'ᎯᎠ ᎧᎸ\.' means/, 'chr: the phrase quoted as typed, not lower-cased');

like(p('hi', 'कल 15:00'), qr/'कल' means yesterday and tomorrow in hi; pass prefer/, 'a tie inside a day and a time dies the same way');
is(p('hi', 'कल 15:00', 'future'), '2026-10-16T15:00:00+01:00', 'and resolves the same way');
is(p('hi', '15:00 कल', 'past'), '2026-10-14T15:00:00+01:00', 'either way round');

my $m = Time::Keeper::Natural->new(locale => 'hi', zone => 'Europe/London', prefer => 'future')->match('कल');
is_deeply([ $m->assumed ], [qw(time direction zone)], 'the Match assumes the direction prefer picked');
is(Time::Keeper::Natural->new(locale => 'hi', zone => 'Europe/London')->match('कल'), undef, 'and match gives undef where parse dies');
is(p('en', 'tomorrow', 'past'), '2026-10-16T00:00:00+01:00', 'prefer moves nothing that is not a tie');
is_deeply([ Time::Keeper::Natural->new(locale => 'en', zone => 'Europe/London', prefer => 'past')->match('tomorrow')->assumed ], [qw(time zone)], 'nor assumes a direction there');

# Every at-string CLDR has, in every locale: the ties, by name, so a CLDR
# change that adds or removes one is noticed. Regional locales repeat their
# language's and are counted, not listed.
my %want = map { $_ => 1 } grep { length } map { (my $s = $_) =~ s/^\s+//; $s } split /\n/, <<'TIES';
    ar السبت القادم
    chr ᎯᎠ ᎧᎸ.
    da på fr.
    da på fre.
    da på fredag
    da på lø.
    da på lør.
    da på lørdag
    da på ma.
    da på man.
    da på mandag
    da på on.
    da på ons.
    da på onsdag
    da på sø.
    da på søn.
    da på søndag
    da på ti.
    da på tir.
    da på tirsdag
    da på to.
    da på tor.
    da på torsdag
    hi कल
    hi परसों
    ig ụbọchị Monde a
    ig ụbọchị Wednesde a
    ky өткөн жм
    ky өткөн жм.
    mai काल्हिक दिन
    nqo ߛߊ߲߬ߘߐ߫
    raj काल
    rw ejo
    sd پويون سال
TIES
my $L = 'Time::Keeper::Locale';
my (%got, $all, $asks);
for my $loc ($L->codes) {
    my $n = Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London');
    my %seen;
    for my $f (qw(year quarter month week day hour minute second mon tue wed thu fri sat sun)) {
        for my $w (qw(long short narrow)) {
            my $r = $L->relative_names($loc, $f, $w);
            for my $s (values %{ $r->{at} }) {
                next if $seen{$s}++;
                $asks++;
                next unless !eval { $n->parse($s); 1 } && $@ =~ /pass prefer/;
                $all++;
                $got{"$loc $s"} = 1 unless $loc =~ /-/;
            }
        }
    }
}
is_deeply([ sort keys %got ], [ sort keys %want ], scalar(keys %want) . " ties in the languages' own locales, among $asks at-strings");
is($all, 119, 'and 119 with the regional locales');

done_testing;
