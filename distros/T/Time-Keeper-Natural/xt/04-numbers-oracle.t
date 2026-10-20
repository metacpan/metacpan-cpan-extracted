#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper::Natural::Numbers;

# The number words against ICU's own spellout, through PyICU, for every locale
# with rules and 0 to 99. ICU's default spellout is one rule set; ours keeps
# every cardinal set, so the test is that ICU's word is among ours. A
# difference is listed, not failed, when it is ICU's data version against
# CLDR 48.2.3; the count of differences is the result.
my $py = `python3 -c 'import icu; print(icu.ICU_VERSION)' 2>/dev/null`;
plan skip_all => 'PyICU is not installed (pip install PyICU); this oracle needs ICU\'s RuleBasedNumberFormat' unless $py;
chomp $py;
my @locales = Time::Keeper::Natural::Numbers->locales;
my $script = <<'PY';
import icu, sys, json
out = {}
for code in sys.argv[1:]:
    loc = icu.Locale(code.replace('-', '_'))
    f = icu.RuleBasedNumberFormat(icu.URBNFRuleSetTag.SPELLOUT, loc)
    out[code] = [f.format(n) for n in range(100)]
print(json.dumps(out))
PY
open my $fh, '-|', 'python3', '-c', $script, @locales or die $!;
local $/;
my $icu = JSON::PP->new->utf8->decode(scalar <$fh>) if eval { require JSON::PP; 1 };
close $fh;
my ($asks, @diff) = (0);
for my $code (@locales) {
    my $nw = Time::Keeper::Natural::Numbers->for($code) or next;
    for my $n (0 .. 99) {
        $asks++;
        my $w = $icu->{$code}[$n] // next;
        $w =~ s/\x{00ad}//g;
        my $got = $nw->read($w);
        push @diff, "$code $n: ICU '$w' read as " . ($got // 'nothing') unless defined $got && $got == $n;
    }
}
note("ICU $py, $asks asks, " . scalar(@diff) . ' differences');
note($_) for @diff;
cmp_ok(scalar @diff, '<=', $asks / 50, "$asks asks against ICU $py: " . scalar(@diff) . ' differences');

done_testing;
