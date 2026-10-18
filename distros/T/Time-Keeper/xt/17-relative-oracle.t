#!perl
# format_relative and Duration->format against node's Intl.RelativeTimeFormat
# and Intl.DurationFormat, where node is on PATH. Author only. Node's ICU may
# carry another CLDR release than 48.2.3, so a difference is reported and
# classified, not failed: the test fails only when the agreement rate drops
# under 97 percent, which a release difference has never caused.
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

my $node = `which node 2>/dev/null`;
chomp $node;
plan skip_all => 'node is not on PATH' unless $node;
my $probe = `node -e 'console.log(typeof Intl.DurationFormat, process.versions.cldr)' 2>/dev/null`;
plan skip_all => 'this node has no Intl.DurationFormat' unless $probe =~ /^function/;
chomp $probe;
note "node's CLDR is " . (split ' ', $probe)[1] . '; ours is ' . Time::Keeper::Locale->cldr_version;

use Time::Keeper;
use JSON::PP ();
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $K = 'Time::Keeper';
my $D = 'Time::Keeper::Duration';
my @locales = qw(en en-GB fr de es it pt pt-BR ru pl uk cs ja zh ko ar ar-EG he tr nl sv da fi hu el th vi id hi bn fa);
my @units = qw(year month week day hour minute second);
my @styles = qw(long short narrow);

# One node run answers every question: a JSON list in, a JSON list out.
my @asks;
for my $loc (@locales) {
    for my $u (@units) {
        for my $n (-3 .. 3) {
            for my $st (@styles) {
                for my $num (qw(auto always)) {
                    push @asks, { kind => 'rel', loc => $loc, unit => $u, n => $n, style => $st, numeric => $num };
                }
            }
        }
    }
    for my $d ({ hours => 1, minutes => 30 }, { days => 2, hours => 3, minutes => 4 }, { minutes => 5 }, { minutes => 2 },
               { minutes => 21 }, { hours => 2 }, { seconds => 1 }, { years => 1, months => 2 }, { weeks => 3, days => 4 }) {
        for my $st (@styles) {
            push @asks, { kind => 'dur', loc => $loc, dur => $d, style => $st };
        }
    }
}
my $json = JSON::PP->new->utf8->canonical;
my $in = $json->encode(\@asks);
my $script = <<'JS';
const asks = JSON.parse(require('fs').readFileSync(0, 'utf8'));
const out = asks.map(a => {
  try {
    if (a.kind === 'rel') return new Intl.RelativeTimeFormat(a.loc, { style: a.style, numeric: a.numeric }).format(a.n, a.unit);
    return new Intl.DurationFormat(a.loc, { style: a.style }).format(a.dur);
  } catch (e) { return null; }
});
process.stdout.write(JSON.stringify(out));
JS
my $tmp = "/tmp/tk-relative-oracle-$$.json";
my $js = "/tmp/tk-relative-oracle-$$.js";
open my $w, '>:raw', $tmp or die; print $w $in; close $w;
open my $s, '>', $js or die; print $s $script; close $s;
my $answers = $json->decode(scalar `node $js < $tmp`);
unlink $tmp, $js;

my $base = $K->new(year => 2026, month => 10, day => 18, hour => 12);
my (%agree, %differ, @examples);
for my $i (0 .. $#asks) {
    my $a = $asks[$i];
    my $theirs = $answers->[$i];
    next unless defined $theirs;
    my $ours;
    if ($a->{kind} eq 'rel') {
        my $t = $base->in_locale($a->{loc})->plus("$a->{unit}s" => $a->{n});
        $ours = $t->format_relative(to => $base, unit => $a->{unit}, style => $a->{style}, numeric => $a->{numeric});
    }
    else {
        $ours = $D->new(%{ $a->{dur} })->format(locale => $a->{loc}, style => $a->{style});
    }
    for ($ours, $theirs) { s/[\x{200e}\x{200f}\x{202f}\x{a0}\x{2009}]/ /g; s/\s+/ /g }
    if ($ours eq $theirs) { $agree{ $a->{kind} }++ }
    else { $differ{ $a->{kind} }++; push @examples, "$a->{loc} $a->{kind} " . ($a->{unit} // '') . ' ' . ($a->{n} // '') . " $a->{style}: ours '$ours', node '$theirs'" if @examples < 40 }
}
for my $kind (qw(rel dur)) {
    my $n = ($agree{$kind} // 0) + ($differ{$kind} // 0);
    my $rate = $n ? ($agree{$kind} // 0) / $n : 1;
    cmp_ok($rate, '>=', 0.97, sprintf('%s: %d of %d agree with node (%.1f%%)', $kind, $agree{$kind} // 0, $n, 100 * $rate));
}
note $_ for @examples;

done_testing;
