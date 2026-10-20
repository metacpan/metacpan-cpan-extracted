#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# Every locale's full and long date and time, which name the zone, written
# for a moment in five zones in October and in January, and read back by a
# parser in London: the same instant, in every locale with no exception.
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
# Time::Keeper 0.08 reads back the GMT formats of hr and bs ("GMT -4"), eu
# ("GMT–4") and am ("+530"); before it, those are left out.
my %old = Time::Keeper->VERSION < 0.08 ? map { $_ => 1 } qw(hr hr-BA hr-HR bs bs-Latn bs-Latn-BA eu eu-ES am am-ET) : ();
note('Time::Keeper ' . Time::Keeper->VERSION . (%old ? ': hr, bs, eu and am left out' : ''));
my ($asks, @bad) = (0);
for my $loc (Time::Keeper::Locale->codes) {
    next if $old{$loc};
    my $n = Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London');
    for my $z (qw(Europe/London America/New_York Asia/Tokyo Europe/Paris Australia/Sydney)) {
        for my $d ([2026, 10, 15], [2027, 1, 20]) {
            my $m = Time::Keeper->new(year => $d->[0], month => $d->[1], day => $d->[2], hour => 15, minute => 5, zone => $z, locale => $loc);
            for my $w (qw(full long)) {
                my $t = eval { $m->format_datetime($w) } // next;
                $asks++;
                my $v = eval { $n->parse($t) };
                push @bad, "$loc $z $w '$t': " . ($v // $@) unless $v && $v->epoch == $m->epoch;
            }
        }
    }
}
cmp_ok($asks, '>=', 21500, "$asks moments written with their zone");
ok(!@bad, 'each reads back as the same instant') or diag(join "\n", scalar(@bad) . ' do not:', @bad[0 .. ($#bad < 9 ? $#bad : 9)]);

done_testing;
