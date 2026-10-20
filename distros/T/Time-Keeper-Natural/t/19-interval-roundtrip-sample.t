#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# Sixty locales, eight skeletons, ends that differ in the day, month, year,
# hour or minute: what format_interval writes, parse_interval reads back.
# Where a time skeleton's ends differ in the date both are written in full
# and each is read as parse reads it, so those either read back or die, and
# never read as something else. The exceptions are named: sw and wae write
# "15 - 18 Nov" for 15 October to 18 November, and si writes "09.05", which
# ISO reads as a decimal hour.
my @LOCALES = qw(en en-GB en-US en-IN fr fr-CA de de-AT es es-MX pt pt-PT it nl sv da nb fi pl cs sk ru uk bg
                 sr hr sl ro hu el tr ar ar-EG he fa ur hi bn ta te ml kn mr gu si th lo km my vi id ms ja ko zh
                 zh-Hant ka hy am sw);
my %KNOWN = map { $_ => 1 } 'sw yMMMd M', 'sw-* yMMMd M', 'wae MMMd M', 'si Hm M', 'si Hm d', 'mn *';
my $A = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 5, zone => 'Europe/London');
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, zone => 'Europe/London');
my %DIFF = (d => [days => 2], M => [months => 1, days => 3], y => [years => 1, months => 2], h => [hours => 3, minutes => 20], m => [minutes => 25]);
my %UNIT = (yMMMd => 'day', yMMMMd => 'day', yMd => 'day', MMMd => 'day', hm => 'minute', Hm => 'minute', yMMM => 'month', y => 'year');

sub known {
    my ($loc, $sk, $d) = @_;
    (my $base = $loc) =~ s/-.*//;
    return grep { $KNOWN{$_} } "$loc $sk $d", "$base-* $sk $d", "$base $sk $d", "$base *";
}

my ($asks, $full_died) = (0, 0);
for my $loc (@LOCALES) {
    my $n = Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London');
    my $x = $A->in_locale($loc);
    my @bad;
    for my $sk (sort keys %UNIT) {
        for my $d (sort keys %DIFF) {
            my $b = $x->plus(@{ $DIFF{$d} });
            next if $sk !~ /y/ && $b->year != 2026;
            my $t = eval { $x->format_interval($b, skeleton => $sk) } // next;
            next if $t eq $x->format_skeleton($sk);
            next if known($loc, $sk, $d);
            $asks++;
            my $u = $UNIT{$sk};
            my $ws = $x->truncate(to => $u);
            my $we = $u eq 'minute' ? $b->truncate(to => 'minute') : $b->end_of(to => $u);
            my @r = eval { $n->parse_interval($t) };
            next if @r == 2 && $r[0] == $ws && $r[1] == $we;
            if ($u eq 'minute' && $d =~ /[dMy]/ && !@r) { $full_died++; next }
            push @bad, "$sk $d '$t': " . (@r ? "@r" : $@);
        }
    }
    ok(!@bad, "$loc: what format_interval writes reads back") or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
}
cmp_ok($asks, '>=', 1000, "$asks asks");
note("$full_died intervals written in full had an end parse does not read");
cmp_ok($full_died, '<=', 20, 'few of them');

done_testing;
