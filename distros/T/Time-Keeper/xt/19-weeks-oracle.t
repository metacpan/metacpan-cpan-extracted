#!perl
# week(locale => 1) and week_year(locale => 1) against format's w and Y on
# random dates in 30 locales, and truncate(to => 'week', week_start => 'locale')
# against the locale's first day. Author only.
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $K = 'Time::Keeper';
my $L = 'Time::Keeper::Locale';
my $N = $ENV{TK_ORACLE_N} || 20_000;
srand($ENV{TK_SEED} || 20261018);
my @locales = qw(en en-GB fr de es it pt pt-BR ru ja zh ko ar ar-EG he fa fa-AF hi th vi tr pl nl sv fi hu el id bn sw);
my $bad = 0;
my %ascii;
# format writes the locale's own digits; map them back to ASCII to compare
sub ascii { my ($loc, $s) = @_; my $d = $ascii{$loc} //= do { my @d = $L->digits($loc); +{ map { $d[$_] => $_ } 0 .. 9 } }; join '', map { $d->{$_} // $_ } split //, $s }
for my $i (1 .. $N) {
    my $loc = $locales[int(rand(@locales))];
    my $t = $K->from_epoch(int(rand(4e9)) - 1e9, locale => $loc);
    my ($w, $wy, $fw, $fy) = ($t->week(locale => 1), $t->week_year(locale => 1), ascii($loc, $t->format('w')), ascii($loc, $t->format('Y')));
    unless ($w eq $fw && $wy eq $fy) {
        $bad++;
        diag("$t in $loc: week(locale) $w of $wy, format w $fw Y $fy") if $bad <= 20;
    }
    my $start = $t->truncate(to => 'week', week_start => 'locale');
    my $first = $L->first_day_of_week($loc);
    unless ($start->day_of_week == $first && $start <= $t && ($t - $start)->in_units('days') < 7 && $start->hms eq '00:00:00') {
        $bad++;
        diag("$t in $loc: week starts $start, the locale's first day is $first") if $bad <= 20;
    }
    last if $bad > 20;
}
is($bad, 0, "$N random dates: the locale's week agrees with format, and the week starts on the locale's first day");

done_testing;
