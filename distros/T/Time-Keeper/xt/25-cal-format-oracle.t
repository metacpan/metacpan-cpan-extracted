#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use utf8;
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# The calendars' names and formats against ICU, through Node's
# Intl.DateTimeFormat: the full, long, medium and short dates of random days
# in every calendar, in a dozen locales, and the month and era names.
# Author only; skipped without node. ICU's spacing marks (U+200F etc.) are
# compared as they come.
use Time::Keeper;

my $node = $ENV{TK_NODE} || (grep { -x $_ } '/opt/homebrew/bin/node', '/usr/local/bin/node', '/usr/bin/node')[0];
plan skip_all => 'node is not on this machine' unless $node;
my $N = $ENV{TK_ORACLE_N} || 300;
my @cals = qw(buddhist japanese roc coptic ethiopic ethioaa hebrew islamic islamic-civil islamic-umalqura persian indian chinese dangi);
my @locales = qw(en en-GB he ja ar fa th zh ko de fr ru);
my $js = <<'JS';
const [cals, locales, n, seed0] = [process.argv[2].split(","), process.argv[3].split(","), +process.argv[4], +process.argv[5]];
let seed = seed0; function rnd() { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x80000000; }
const DAY = 86400000, out = [];
for (let i = 0; i < n; i++) {
  const day = Math.floor((rnd() * 1300 + 1600 - 1970) * 365.2425);
  const date = new Date(day * DAY);
  const cal = cals[i % cals.length], loc = locales[i % locales.length];
  const styles = {};
  for (const s of ["full", "long", "medium", "short"]) styles[s] = new Intl.DateTimeFormat(loc + "-u-ca-" + cal, { timeZone: "UTC", dateStyle: s }).format(date);
  const parts = Object.fromEntries(new Intl.DateTimeFormat(loc + "-u-ca-" + cal, { timeZone: "UTC", era: "short", year: "numeric", month: "long", day: "numeric" }).formatToParts(date).filter(x => x.type !== "literal").map(x => [x.type, x.value]));
  out.push([day, cal, loc, styles.full, styles.long, styles.medium, styles.short, parts.month ?? "", parts.era ?? ""].join("\t"));
}
process.stdout.write(out.join("\n") + "\n");
JS
my $script = "/tmp/tk-cal-format-$$.js";
open my $w, '>', $script or die; print $w $js; close $w;
my @rows = `"$node" "$script" @{[ join ',', @cals ]} @{[ join ',', @locales ]} $N 20261018`;
unlink $script;
plan skip_all => 'node gave nothing' unless @rows;
binmode STDOUT, ':encoding(UTF-8)';
my (%bad, %n, %example);
my $strip = sub { my ($s) = @_; $s =~ s/[\x{200E}\x{200F}\x{061C}]//g; $s =~ s/\x{202F}/ /g; $s =~ s/\x{00A0}/ /g; $s };
for (@rows) {
    chomp;
    utf8::decode($_);
    my ($day, $cal, $loc, @icu) = split /\t/, $_, -1;
    next if $cal =~ /^(buddhist|japanese|roc)$/ && $day < -141427;
    next if $cal =~ /^(chinese|dangi|islamic|islamic-rgsa)$/ && ($day < -354242 || $day >= 376160);
    my $t = Time::Keeper->from_epoch($day * 86400, calendar => $cal, locale => $loc);
    my @mine = ((map { $t->format_date($_) } qw(full long medium short)), $t->month_name, $t->era_abbr);
    for my $k (0 .. 5) {
        my $what = (qw(full long medium short month_name era_abbr))[$k];
        $n{"$cal $what"}++;
        next if $k == 4 && $icu[4] =~ /^\d+$/;   # a locale whose months are numbers: ICU's part is the number
        next if $strip->($mine[$k]) eq $strip->($icu[$k]);
        $bad{"$cal $what"}++;
        $example{"$cal $what"} //= "$loc day $day: ours '$mine[$k]' ICU '$icu[$k]'";
    }
}
my ($checks, $total) = (0, 0);
$checks += $n{$_} for keys %n;
$total += $bad{$_} for keys %bad;
my $agree = $checks ? 100 * ($checks - $total) / $checks : 0;
cmp_ok($agree, '>=', 90, sprintf '%d of %d checks agree with ICU (%.1f%%)', $checks - $total, $checks, $agree)
    or diag(join "\n", map { sprintf '%-28s %4d of %4d  e.g. %s', $_, $bad{$_}, $n{$_}, $example{$_} } sort keys %bad);
diag(join "\n", map { sprintf '%-28s %4d of %4d  e.g. %s', $_, $bad{$_}, $n{$_}, $example{$_} } sort keys %bad) if %bad && $ENV{TK_ORACLE_DIAG};

done_testing;
