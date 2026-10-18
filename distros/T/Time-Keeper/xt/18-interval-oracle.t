#!perl
# format_interval against node's Intl.DateTimeFormat formatRange, where node is
# on PATH. Author only. Three classes of difference are expected and listed as
# notes, not failed: node's ICU carries another CLDR release (48.0 against our
# 48.2.3), so a few patterns differ (Russian yMMM across months); ICU resolves
# a skeleton through its own matcher and writes Japanese and Chinese "short
# month" skeletons in numeric form where this module follows the named
# skeleton's own interval formats; and the comma in the date-time glue of a
# widened time skeleton differs by data version, so commas are ignored. The
# test fails only when the agreement rate drops under 90 percent.
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

my $node = `which node 2>/dev/null`;
chomp $node;
plan skip_all => 'node is not on PATH' unless $node;

use Time::Keeper;
use JSON::PP ();
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $K = 'Time::Keeper';
my @locales = qw(en en-GB fr de es it pt ru ja zh ko ar he nl sv pl tr th hi fi);
# skeleton to Intl options: the fields the skeleton names
my %opts = (
    yMMMd  => { year => 'numeric', month => 'short', day => 'numeric' },
    yMMMEd => { year => 'numeric', month => 'short', day => 'numeric', weekday => 'short' },
    MMMd   => { month => 'short', day => 'numeric' },
    yMMM   => { year => 'numeric', month => 'short' },
    y      => { year => 'numeric' },
    yMd    => { year => 'numeric', month => 'numeric', day => 'numeric' },
    hm     => { hour => 'numeric', minute => 'numeric', hour12 => JSON::PP::true },
    Hm     => { hour => 'numeric', minute => 'numeric', hour12 => JSON::PP::false },
);
my $base = $K->new(year => 2026, month => 10, day => 15, hour => 9, minute => 0, zone => 'UTC');
my @pairs = map { [$base, $base->plus(@$_)] } ([days => 2], [months => 1], [years => 1], [hours => 1, minutes => 30], [hours => 5], [minutes => 15], [days => 1, hours => 5], [seconds => 30]);
my @asks;
for my $loc (@locales) {
    for my $sk (sort keys %opts) {
        for my $p (@pairs) {
            push @asks, { loc => $loc, sk => $sk, from => $p->[0]->epoch_millis, to => $p->[1]->epoch_millis };
        }
    }
}
my $json = JSON::PP->new->utf8->canonical;
my $script = <<'JS';
const asks = JSON.parse(require('fs').readFileSync(0, 'utf8'));
const opts = OPTS;
const out = asks.map(a => {
  try { return new Intl.DateTimeFormat(a.loc, Object.assign({ timeZone: 'UTC' }, opts[a.sk])).formatRange(new Date(a.from), new Date(a.to)); }
  catch (e) { return null; }
});
process.stdout.write(JSON.stringify(out));
JS
$script =~ s/OPTS/$json->encode(\%opts)/e;
my ($tmp, $js) = ("/tmp/tk-interval-oracle-$$.json", "/tmp/tk-interval-oracle-$$.js");
open my $w, '>:raw', $tmp or die; print $w $json->encode(\@asks); close $w;
open my $s, '>', $js or die; print $s $script; close $s;
my $answers = $json->decode(scalar `node $js < $tmp`);
unlink $tmp, $js;

my ($agree, $differ, @examples) = (0, 0);
for my $i (0 .. $#asks) {
    my $a = $asks[$i];
    my $theirs = $answers->[$i];
    next unless defined $theirs;
    my ($from, $to) = ($K->from_epoch_millis($a->{from}, locale => $a->{loc}), $K->from_epoch_millis($a->{to}));
    my $ours = eval { $from->format_interval($to, skeleton => $a->{sk}) };
    $ours = "death: $@" unless defined $ours;
    for ($ours, $theirs) { s/[\x{200e}\x{200f}\x{202f}\x{a0}\x{2009}\x{200b},]/ /g; s/\s+/ /g; s/\s*([–-])\s*/ - /g }
    if ($ours eq $theirs) { $agree++ }
    else { $differ++; push @examples, "$a->{loc} $a->{sk} $a->{from}..$a->{to}: ours '$ours', node '$theirs'" if @examples < 60 }
}
my $n = $agree + $differ;
cmp_ok($n ? $agree / $n : 1, '>=', 0.90, sprintf('%d of %d interval formats agree with node (%.1f%%)', $agree, $n, $n ? 100 * $agree / $n : 100));
note $_ for @examples;

done_testing;
