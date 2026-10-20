#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# Sixty locales, nine durations, three styles and the digital clock: what
# Duration->format writes, parse_duration reads back.
my @LOCALES = qw(en en-GB en-US en-IN fr fr-CA de de-AT es es-MX pt pt-PT it nl sv da nb fi pl cs sk ru uk bg
                 sr hr sl ro hu el tr ar ar-EG he fa ur hi bn ta te ml kn mr gu si th lo km my vi id ms ja ko zh
                 zh-Hant ka hy am sw);
my @ISO = qw(P1Y P2M P3W P4D PT5H PT6M PT7S PT1H30M P1Y2M3DT4H5M6S);
my $D = 'Time::Keeper::Duration';
my ($asks, @ambiguous) = (0);
for my $loc (@LOCALES) {
    my $n = Time::Keeper::Natural->new(locale => $loc);
    my @bad;
    for my $iso (@ISO) {
        my $d = $D->parse($iso);
        for my $style (qw(long short narrow), ($iso =~ /^PT/ ? 'digital' : ())) {
            $asks++;
            my $s = $d->format(locale => $loc, style => $style);
            my $got = eval { $n->parse_duration($s) };
            next if $got && "$got" eq "$d";
            if ($got && grep { my $x = $_; Time::Keeper::Natural::Lexicon->for($loc)->key($got->format(locale => $loc, style => $x)) eq Time::Keeper::Natural::Lexicon->for($loc)->key($s) } qw(long short narrow)) { push @ambiguous, "$loc $style '$s' read as $got"; next }
            push @bad, "$iso $style '$s': " . ($got ? "$got" : $@);
        }
    }
    ok(!@bad, "$loc: everything Duration->format writes reads back") or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
}
cmp_ok($asks, '>=', 60 * (9 * 3 + 4), "$asks asks");
note(scalar(@ambiguous) . ' strings written the same for two durations:');
note($_) for @ambiguous;
cmp_ok(scalar @ambiguous, '<=', 20, 'few of them');

done_testing;
