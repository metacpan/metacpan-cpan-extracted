#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# find over every locale: what format_date and format_datetime write in
# their long width, set inside other words, is found as one mention with
# parse's value, wherever parse reads it. The ones it does not are named:
# eu nests brackets ("3(a) (15:05:00 (GMT))"), km writes its zone's name
# with a zero-width space, and tok's date is longer than a mention's
# twelve words.
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
my %known = map { $_ => 1 } qw(eu eu-ES km km-KH tok tok-001);
my ($asks, $whole, @miss) = (0, 0);
for my $loc (Time::Keeper::Locale->codes) {
    my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => $loc);
    my $v = Time::Keeper->new(year => 2026, month => 11, day => 3, hour => 15, minute => 5, zone => 'Europe/London', locale => $loc);
    for my $t (grep { defined } map { my $m = $_; eval { $v->$m('long') } } qw(format_date format_datetime)) {
        my $p = eval { '' . $n->parse($t) };
        next unless defined $p;
        $asks++;
        my $x = "\x{a7}\x{a7} $t \x{a7}\x{a7}";
        my @m = $n->find($x);
        if (@m == 1 && substr($x, $m[0]->start, $m[0]->end - $m[0]->start) eq $t && '' . $m[0]->value eq $p) {
            $whole++;
        }
        elsif (!$known{$loc}) {
            push @miss, "$loc '$t' => " . join(' + ', map { '[' . substr($x, $_->start, $_->end - $_->start) . ']' } @m);
        }
    }
}
note("$asks texts parse reads, $whole found whole");
ok($asks > 2000, "$asks asks");
ok(!@miss, 'each found whole, the named exceptions apart') or diag(join "\n", @miss[0 .. ($#miss < 20 ? $#miss : 20)]);

done_testing;
