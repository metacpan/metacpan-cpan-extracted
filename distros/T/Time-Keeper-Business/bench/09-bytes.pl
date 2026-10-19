#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }

# Bytes a schedule costs: the growth of the process over many schedules of
# a hundred literal holidays each, in a fresh process.
my $N = $ENV{TK_BENCH_SCHEDULES} // 2000;
my $prog = 'use Time::Keeper::Business; my @h = map { sprintf q{2026-%02d-%02d}, 1 + $_ % 12, 1 + $_ % 28 } 0 .. 99; '
         . 'my @warm = map { Time::Keeper::Business->new(holidays => \@h) } 1 .. 20; '
         . 'sub rss { my $r = `ps -o rss= -p $$`; $r =~ s/\s//g; $r * 1024 } '
         . "my \$before = rss(); my \@s = map { Time::Keeper::Business->new(holidays => \\\@h) } 1 .. $N; print +(rss() - \$before) / $N";
my $bytes = `"$^X" -Mblib -e '$prog'`;
printf "info bytes per schedule of 100 holidays, by RSS over %d: %.0f\n", $N, $bytes;
if (eval { require Devel::Size; require Time::Keeper::Business; 1 }) {
    my @h = map { sprintf '2026-%02d-%02d', 1 + $_ % 12, 1 + $_ % 28 } 0 .. 99;
    printf "info Devel::Size::total_size of the scalar and its spec: %d (the C struct and its arrays are not counted)\n",
        Devel::Size::total_size(Time::Keeper::Business->new(holidays => \@h));
}
mark_less('bytes per schedule, 100 holidays', sprintf('%.0f', $bytes), 4096, 1, 'the mark', 'B');
done();
