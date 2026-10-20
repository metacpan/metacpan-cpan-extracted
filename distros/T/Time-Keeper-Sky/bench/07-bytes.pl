#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }

# Bytes a Day and a place cost: the growth of the process over many of them,
# each in its own fresh process. A Moon::Day is measured as copies of one
# computed day: making each afresh frees the moonrise computation's working
# memory, which the next day then reuses, and the growth under-counts.
my $N = $ENV{TK_BENCH_VALUES} // 100_000;
my %make = (
    'a Day'   => 'my $s = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, zone => q{Europe/London}); my $d = Time::Keeper::Date->new(year => 2026, month => 10, day => 15); sub mk { $s->on($d) }',
    'a Moon::Day with a place' => 'my $s = Time::Keeper::Sun->new(place => q{Europe/London}); my $d = Time::Keeper::Date->new(year => 2026, month => 10, day => 15); my $tmpl = Time::Keeper::Moon->on($d, place => $s); sub mk { my $c = ${$tmpl}; bless \$c, q{Time::Keeper::Moon::Day} }',
    'a place' => 'sub mk { Time::Keeper::Sun->new(latitude => 51.5074 + $_[0] / 1e6, longitude => -0.1278, zone => q{Europe/London}) }',
);
my %bytes;
for my $m (sort keys %make) {
    my $prog = "use Time::Keeper; use Time::Keeper::Sun; use Time::Keeper::Moon; $make{$m} "
             . 'my @warm = map { mk($_) } 1 .. 100; '
             . 'sub rss { my $r = `ps -o rss= -p $$`; $r =~ s/\s//g; $r * 1024 } '
             . "my \$before = rss(); my \@v = map { mk(\$_) } 1 .. $N; print +(rss() - \$before) / $N";
    $bytes{$m} = `"$^X" -Mblib -e '$prog'`;
}
printf "info bytes by RSS over %d: a Day %.0f, a place %.0f, a Moon::Day with a place %.0f\n", $N, @bytes{'a Day', 'a place', 'a Moon::Day with a place'};
$_ = sprintf('%.0f', $_) for values %bytes;
mark_less('bytes a Day costs', $bytes{'a Day'}, 400, 1, 'the mark', 'B');
mark_less('bytes a place costs', $bytes{'a place'}, 200, 1, 'the mark', 'B');
mark_less('bytes a Moon::Day costs', $bytes{'a Moon::Day with a place'}, 400, 1, 'the mark', 'B');
done();
