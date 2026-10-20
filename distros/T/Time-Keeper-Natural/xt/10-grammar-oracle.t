#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use File::Temp ();
use FindBin;

# The word grammar against the pure-Perl 0.01, in a separate process
# (TKN_ORACLE or ../Time-Keeper-Natural-PP). In every locale with a word
# table, its regional variants, and twenty locales without one: each table
# phrase put round the locale's own words for a period (relative words,
# month and day names, a date, a year, a field name), "at" before a time and
# between a day and a time, "on" before a day, ordinal weekdays of a month,
# the table's test lines (not 0.02's intervals), in capitals too, and the phrases with nothing
# after them; each through match under three parsers, its value, precision
# and assumptions, or its death. A phrase's offsets are iterated sorted in
# the oracle, as xt/07 does.
my $oracle = $ENV{TKN_ORACLE} || File::Spec->catdir($FindBin::Bin, '..', '..', 'Time-Keeper-Natural-PP');
plan skip_all => "no oracle at $oracle (set TKN_ORACLE to the pure-Perl 0.01 tree)"
    unless -f File::Spec->catfile($oracle, 'lib', 'Time', 'Keeper', 'Natural.pm');

my $src = do { open my $f, '<:encoding(UTF-8)', File::Spec->catfile($FindBin::Bin, '07-relative-oracle.t') or die; local $/; <$f> };
my ($sorted) = $src =~ /^(if \(\$sorted\) \{\n.*?\n\}\n)/ms or die 'no sorted block in xt/07';

my $script = <<'SCRIPT';
use strict;
use warnings;
use Time::Keeper;
use Time::Keeper::Natural;
use Time::Keeper::Natural::Words;
use Time::Keeper::Natural::Numbers;
my ($out, $sorted, $only) = @ARGV;
open my $fh, '>:encoding(UTF-8)', $out or die "$out: $!";
SORTED
my $L = 'Time::Keeper::Locale';
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, zone => 'Europe/London');
my $W = 'Time::Keeper::Natural::Words';
my @tables = $W->locales;
my %regional = map { $_ => 1 } qw(en-GB en-US en-AU fr-CA fr-CH de-AT de-CH es-MX es-419 pt-PT pt-BR zh-Hant zh-HK ar-EG ru-UA nl-BE it-CH);
my @others = qw(sv da fi pl cs tr uk he fa ur id vi ms sw ta te mr gu kn ml);
my $moment = Time::Keeper->new(year => 2026, month => 11, day => 3, hour => 15, minute => 5, zone => 'Europe/London');
sub fill { my ($p, $x) = @_; return $p =~ /\{0\}/ ? ($p =~ s/\{0\}/$x/r) : "$p $x" }
my %real = map { $_ => 1 } $L->codes;
for my $loc (grep { $real{$_} } @tables, sort(keys %regional), @others) {
    next if defined $only && $loc ne $only;
    my $w = $W->for($loc) || $W->for('en');
    my @parsers = map { Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London', @$_) } [], [bare_hour => 'next'], [prefer => 'past'];
    my (@texts, %seen);
    my @periods;
    for my $f (qw(day week month year quarter)) {
        my $r = $L->relative_names($loc, $f, 'long');
        push @periods, map { $r->{at}{$_} } sort keys %{ $r->{at} };
        push @periods, $r->{display} if defined $r->{display};
    }
    my @months = $L->names($loc, 'months', 'wide');
    my @days = $L->names($loc, 'days', 'wide');
    push @periods, $months[9], $months[1], $days[1], '2026', '2027';
    my $v = $moment->in_locale($loc);
    my $date = eval { $v->format_date('medium') };
    my $time = eval { $v->format_time('short') };
    push @periods, $date if defined $date;
    my $ym = eval { $v->format_skeleton('yMMMM') };
    push @periods, $ym if defined $ym;
    my $in3 = $L->relative_names($loc, 'hour', 'long')->{future}{other};
    push @periods, $in3 =~ s/\{0\}/3/r if defined $in3;
    for my $key (qw(start_of end_of)) {
        for my $p ($w->phrases($key)) {
            push @texts, map { fill($p, $_) } grep { defined } @periods;
            push @texts, map { fill($p, $_) } map { "$_ " . $periods[0] } $w->phrases('skip');
            push @texts, $p =~ s/\s*\{0\}\s*//r;
        }
    }
    if (defined $time) {
        push @texts, $time;
        for my $p ($w->phrases('at')) {
            push @texts, fill($p, $time), $p =~ s/\s*\{0\}\s*//r;
            push @texts, map { "$_ " . fill($p, $time) } grep { defined } @periods[0 .. 3], $days[4];
        }
        push @texts, map { "$_ $time" } grep { defined } @periods[0 .. 2], $days[4], $date;
        push @texts, map { "$time $_" } grep { defined } @periods[0 .. 2];
        push @texts, '3', "$days[4] 3";
    }
    for my $p ($w->phrases('on')) {
        push @texts, map { fill($p, $_) } grep { defined } @days[0, 4], $date, $periods[0];
    }
    my $nw = Time::Keeper::Natural::Numbers->for($loc);
    my %o = $nw ? $nw->ordinals : ();
    my %by;
    for my $word (sort keys %o) { $by{ $o{$word} } //= $word }
    for my $of ($w->phrases('of')) {
        for my $first ((map { $by{$_} } grep { $by{$_} } 1, 3, 5), $w->phrases('last')) {
            for my $what (grep { defined } $L->relative_names($loc, 'month', 'long')->{at}{1}, $months[1], $L->relative_names($loc, 'week', 'long')->{at}{1}) {
                push @texts, join(' ', $first, $days[4], fill($of, $what));
                push @texts, join(' ', $first, $days[0], fill($of, $what));
            }
        }
    }
    push @texts, map { $_->[0] } grep { $_->[1] !~ m{ / } && $_->[0] !~ /\b(?:after|before|weekend)\b/ } $w->tests;
    push @texts, map { uc } @texts[0 .. ($#texts < 40 ? $#texts : 40)];
    for my $t (grep { defined && length && !$seen{$_}++ } @texts) {
        my @got;
        for my $n (@parsers) {
            my $r = eval { $n->match($t) };
            my $got;
            if ($r) { $got = join ' ', $r->value . '', $r->precision // '-', join(',', $r->assumed) }
            else { $got = 'undef' }
            my $e = eval { $n->parse($t); '' } // do { (my $m = $@) =~ s/ at \S+ line \d+\.?\n?\z//; "died: $m" };
            push @got, "$got / $e";
        }
        my $line = join "\t", $loc, $t, @got;
        $line =~ s/\n/\\n/g;
        print $fh "$line\n";
    }
}
close $fh;
SCRIPT
$script =~ s/^SORTED\n/$sorted/m;

my $dir = File::Temp->newdir;
my $file = File::Spec->catfile($dir, 'ask.pl');
open my $fh, '>:encoding(UTF-8)', $file or die "$file: $!";
print $fh $script;
close $fh;

sub run {
    my ($name, @inc) = @_;
    my $out = File::Spec->catfile($dir, "$name.txt");
    system($^X, (map { "-I$_" } @inc), $file, $out, $name eq 'oracle' ? 1 : 0, @ARGV) == 0 or die "$name failed: $?";
    open my $in, '<:encoding(UTF-8)', $out or die "$out: $!";
    my @l = <$in>;
    chomp @l;
    return \@l;
}
my $want = run('oracle', File::Spec->catdir($oracle, 'lib'));
my $got = run('ours', @INC);
# 0.02 refuses a phrase CLDR writes for two offsets unless prefer picks,
# and assumes the direction when it does; 0.01 read the earlier offset.
my %tie = map { $_ => 1 } grep { defined $got->[$_] && $got->[$_] ne $want->[$_] && $got->[$_] =~ /pass prefer|\bdirection\b/ } 0 .. $#$want;
note(scalar(keys %tie) . " answers differ by 0.02's rule for a phrase with two meanings");
# 0.02 reads texts 0.01 died on (a spaceless locale's day and time set apart
# by a space, "พรุ่งนี้ เวลา 15:05"): an answer may differ only that way.
my %gain = map { $_ => 1 } grep {
    my @w = (split /\t/, $want->[$_])[2 .. 4];
    my @g = (split /\t/, $got->[$_] // '')[2 .. 4];
    !$tie{$_} && @g == 3 && grep({ $w[$_] ne $g[$_] } 0 .. 2)
        && !grep({ $w[$_] ne $g[$_] && ($w[$_] !~ /^undef \/ died: / || $g[$_] =~ /^undef /) } 0 .. 2)
} 0 .. $#$want;
note(scalar(keys %gain) . " texts 0.01 could not read now read");
my @bad = grep { !$tie{$_} && !$gain{$_} && (!defined $got->[$_] || $got->[$_] ne $want->[$_]) } 0 .. $#$want;
my %loc = map { (split /\t/)[0] => 1 } @$want;
my $died = grep { /died: / } @$want;
ok(@$want > 10000, scalar(@$want) . " texts in " . scalar(keys %loc) . " locales, three parsers each, $died with a death");
is(scalar @$got, scalar @$want, 'as many answers');
is(scalar @bad, 0, scalar(@$want) . ' answers agree with the pure-Perl 0.01') or do {
    diag(scalar(@bad) . ' differ');
    for my $i (@bad[0 .. ($#bad < 7 ? $#bad : 7)]) { diag("0.01: $want->[$i]\nC:    " . ($got->[$i] // '(none)')) }
};

done_testing;
