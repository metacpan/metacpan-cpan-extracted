#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;

# Every calendar's four date formats in every locale, for two days, read back
# by parse_cldr with the same pattern: the same day.
my ($n, @bad) = (0);
for my $c (Time::Keeper::Calendar->ids) {
    for my $l (Time::Keeper::Locale->codes) {
        my @f = Time::Keeper::Locale->formats($l, 'date', $c);
        for my $m (Time::Keeper->new(year => 2026, month => 10, day => 15, zone => 'Europe/London'),
                   Time::Keeper->new(year => 2027, month => 3, day => 3, zone => 'Europe/London')) {
            my $v = $m->in_calendar($c)->in_locale($l);
            for my $i (0 .. 3) {
                my $s = $v->format_date((qw(full long medium short))[$i]);
                $n++;
                my $r = eval { Time::Keeper->parse_cldr($s, $f[$i], locale => $l, calendar => $c, zone => 'Europe/London') };
                push @bad, "$c $l '$s' ($f[$i]): " . ($r // $@) unless $r && $r == $m;
            }
        }
    }
}
cmp_ok($n, '>=', 150_000, "$n dates in 17 calendars and every locale");
ok(!@bad, 'each reads back with its own pattern') or diag(join "\n", scalar(@bad) . ' do not:', @bad[0 .. ($#bad < 19 ? $#bad : 19)]);

done_testing;
