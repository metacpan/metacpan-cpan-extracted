#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use utf8;
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# The arithmetic calendars against ICU, through Node's Intl.DateTimeFormat,
# on random days from Gregorian 1 to 3000 (1582 on for the three ICU reads
# as Julian before the cutover). Author only; skipped without node.
use Time::Keeper;

my $node = $ENV{TK_NODE} || (grep { -x $_ } '/opt/homebrew/bin/node', '/usr/local/bin/node', '/usr/bin/node')[0];
plan skip_all => 'node is not on this machine' unless $node;
my $N = $ENV{TK_ORACLE_N} || 3000;
my @cals = qw(gregory buddhist japanese roc coptic ethiopic ethioaa hebrew islamic-civil islamic-tbla islamic-umalqura persian indian islamic islamic-rgsa chinese dangi);
my $js = <<'JS';
const cals = process.argv[2].split(",");
const n = +process.argv[3];
const DAY = 86400000;
const fs = {}; for (const c of cals) fs[c] = new Intl.DateTimeFormat("en-u-ca-" + c + "-nu-latn", { timeZone: "UTC", era: "short", year: "numeric", month: "numeric", day: "numeric" });
let seed = +process.argv[4]; function rnd() { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x80000000; }
const out = [];
for (let i = 0; i < n; i++) {
  const day = Math.floor((rnd() * 3000 - 1969) * 365.2425);
  const date = new Date(day * DAY);
  for (const c of cals) {
    const p = Object.fromEntries(fs[c].formatToParts(date).filter(x => x.type !== "literal").map(x => [x.type, x.value]));
    out.push([day, c, p.era, p.year ?? p.relatedYear, p.month, p.day].join("\t"));
  }
}
process.stdout.write(out.join("\n") + "\n");
JS
my $script = "/tmp/tk-cal-oracle-$$.js";
open my $w, '>', $script or die; print $w $js; close $w;
my @rows = `"$node" "$script" @{[ join ',', @cals ]} $N 20261018`;
unlink $script;
plan skip_all => 'node gave nothing' unless @rows;
my %slot = (Tishri => 1, Heshvan => 2, Kislev => 3, Tevet => 4, Shevat => 5, 'Adar I' => 6, Adar => 7, 'Adar II' => 7, Nisan => 8, Iyar => 9, Sivan => 10, Tamuz => 11, Av => 12, Elul => 13);
my (%bad, %n);
for (@rows) {
    chomp;
    my ($day, $cal, $era, $year, $month, $dd) = split /\t/;
    next if $cal =~ /^(buddhist|japanese|roc)$/ && $day < -141427;
    next if $cal =~ /^(chinese|dangi|islamic|islamic-rgsa)$/ && ($day < -354242 || $day >= 376160);
    my $t = Time::Keeper->from_epoch($day * 86400, calendar => $cal);
    my $slot = $cal eq 'hebrew' ? $slot{$month} // -1 : $month;
    my $got = $t->month;
    $got = $t->is_leap_year ? $got : ($got <= 5 ? $got : $got + 1) if $cal eq 'hebrew';
    if ($cal eq 'chinese' || $cal eq 'dangi') {
        (my $m = $month) =~ s/^Mo//;
        my $leap = $m =~ s/bis$//;
        $slot = $m;
        $got = $t->month_code =~ /^M(\d\d)(L?)$/ ? 0 + $1 : -1;
        $got = -1 if ($2 ? 1 : 0) != ($leap ? 1 : 0);
    }
    $n{$cal}++;
    my $ok = $got == $slot && $t->day == $dd && (($cal eq 'chinese' || $cal eq 'dangi') ? $t->related_year : $t->era_year) == $year;
    $ok &&= Time::Keeper->new(year => $t->year, month => $t->month, day => $t->day, calendar => $cal)->epoch == $day * 86400;
    unless ($ok) {
        $bad{$cal}++;
        diag("day $day in $cal: ours " . join('-', $t->era_year, $got, $t->day) . ", ICU $era $year $month $dd") if $bad{$cal} <= 3;
    }
}
my $total = 0;
$total += $bad{$_} for keys %bad;
my $checks = 0;
$checks += $n{$_} for keys %n;
is($total, 0, "$checks ICU dates across " . scalar(keys %n) . " calendars agree") or diag(join ' ', map { "$_: $bad{$_}" } sort keys %bad);

done_testing;
