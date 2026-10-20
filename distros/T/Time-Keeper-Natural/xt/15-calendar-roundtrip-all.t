#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# Every calendar in every locale: two moments written in the calendar's four
# date formats and its medium date and time, read back by a parser in that
# calendar, the same instant and in the calendar. Before Time::Keeper 0.09,
# which reads them, texts in Hebrew or Chinese numerals are left out.
my $TK09 = Time::Keeper->VERSION >= 0.09;
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
my ($asks, @bad) = (0);
for my $cal (Time::Keeper::Calendar->ids) {
    for my $loc (Time::Keeper::Locale->codes) {
        my $n = Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London', calendar => $cal);
        for my $d ([2026, 10, 15, 15, 5], [2027, 3, 3, 9, 30]) {
            my $m = Time::Keeper->new(year => $d->[0], month => $d->[1], day => $d->[2], hour => $d->[3], minute => $d->[4], zone => 'Europe/London')
                ->in_calendar($cal)->in_locale($loc);
            for my $w (qw(full long medium short dt)) {
                my $t = eval { $w eq 'dt' ? $m->format_datetime('medium') : $m->format_date($w) } // next;
                next if !$TK09 && $t =~ /[\x{5D0}-\x{5EA}]{2}|[〇一二三四五六七八九十初廿元]/;
                $asks++;
                my $want = $w eq 'dt' ? $m->truncate(to => 'second') : $m->truncate(to => 'day');
                my $v = eval { $n->parse($t) };
                push @bad, "$cal $loc $w '$t': " . ($v // $@) unless $v && $v->epoch == $want->epoch && $v->calendar eq $cal;
            }
        }
    }
}
cmp_ok($asks, '>=', 150_000, "$asks dates in 17 calendars and every locale");
ok(!@bad, 'each reads back, in its calendar') or diag(join "\n", scalar(@bad) . ' do not:', @bad[0 .. ($#bad < 19 ? $#bad : 19)]);

done_testing;
