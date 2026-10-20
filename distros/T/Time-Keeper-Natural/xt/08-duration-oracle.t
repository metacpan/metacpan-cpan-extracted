#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp ();
use FindBin;

# Durations against the pure-Perl 0.01, in a separate process (TKN_ORACLE
# or ../Time-Keeper-Natural-PP). In every locale: what Duration->format
# writes for eight durations in its four styles, the same in ASCII digits,
# two parts joined by the locale's standard list words, the parts as number
# words where the locale has them, ISO forms in either case, and texts that
# must die (a sign, a moment, a unit twice, a word that is not one); each
# through match_duration, its value and precision, or its death.
my $oracle = $ENV{TKN_ORACLE} || File::Spec->catdir($FindBin::Bin, '..', '..', 'Time-Keeper-Natural-PP');
plan skip_all => "no oracle at $oracle (set TKN_ORACLE to the pure-Perl 0.01 tree)"
    unless -f File::Spec->catfile($oracle, 'lib', 'Time', 'Keeper', 'Natural.pm');

my $script = <<'SCRIPT';
use strict;
use warnings;
use Time::Keeper;
use Time::Keeper::Natural;
use Time::Keeper::Natural::Numbers;
my ($out, $only) = @ARGV;
open my $fh, '>:encoding(UTF-8)', $out or die "$out: $!";
my $L = 'Time::Keeper::Locale';
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, zone => 'Europe/London');
my @D = ([hours => 1, minutes => 30], [days => 2], [years => 1, months => 2, days => 3], [minutes => 5, seconds => 9],
         [hours => 1, minutes => 5, seconds => 9], [weeks => 2], [hours => 25], [seconds => 1, nanoseconds => 500_000_000]);
for my $loc ($L->codes) {
    next if defined $only && $loc ne $only;
    my @d = $L->digits($loc);
    my %to_ascii = @d ? map { $d[$_] => $_ } 0 .. 9 : ();
    my $n = Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London');
    my (@texts, %seen);
    for my $parts (@D) {
        my $dur = Time::Keeper::Duration->new(@$parts);
        for my $style (qw(long short narrow digital)) {
            my $t = eval { $dur->format(locale => $loc, style => $style) } // next;
            push @texts, $t;
            (my $a = $t) =~ s/(.)/exists $to_ascii{$1} ? $to_ascii{$1} : $1/ge;
            push @texts, $a if $a ne $t;
        }
    }
    my $std = ($L->list_patterns($loc, 'standard') || {})->{two};
    my $h = $L->unit_patterns($loc, 'hour', 'long')->{count}{other};
    my $m = $L->unit_patterns($loc, 'minute', 'long')->{count}{other};
    if (defined $std && defined $h && defined $m) {
        for my $pair ([2, 30], [1, 1], [3, 3]) {
            (my $a = $h) =~ s/\{0\}/$pair->[0]/;
            (my $b = $m) =~ s/\{0\}/$pair->[1]/;
            (my $t = $std) =~ s/\{0\}/$a/;
            $t =~ s/\{1\}/$b/;
            push @texts, $t;
            (my $twice = $std) =~ s/\{0\}/$a/;
            $twice =~ s/\{1\}/$a/;
            push @texts, $twice;
        }
        my $nw = Time::Keeper::Natural::Numbers->for($loc);
        if ($nw) {
            my %c = $nw->cardinals;
            my ($two) = sort grep { $c{$_} == 2 } keys %c;
            if (defined $two) { (my $t = $h) =~ s/\{0\}/$two/; push @texts, $t }
        }
    }
    my $day = $L->relative_names($loc, 'day', 'long');
    push @texts, grep { defined } $day->{at}{1}, $day->{future}{other} && ($day->{future}{other} =~ s/\{0\}/3/r);
    push @texts, 'PT90M', 'pt90m', 'P1Y2M3DT4H', 'P2W', ' PT1H ', '-1 hour', '+2 hours', "\x{2212}3 days", 'zzz', '3 zzz', '1:05:09', '1:5', '12:345', '1:05:09.5', '1:05:09,123456789', '1:05:09.1234567890';
    for my $t (grep { defined && !$seen{$_}++ } @texts) {
        my $r = eval { $n->match_duration($t) };
        my $got;
        if ($r) { $got = join ' ', $r->value . '', $r->precision // '-', join(',', $r->assumed) }
        else { ($got = $@) =~ s/ at \S+ line \d+\.?\n?\z//; $got = "died: $got" }
        $got =~ s/\n/\\n/g;
        (my $shown = $t) =~ s/\n/\\n/g;
        print $fh "$loc\t$shown\t$got\n";
    }
}
close $fh;
SCRIPT

my $dir = File::Temp->newdir;
my $file = File::Spec->catfile($dir, 'ask.pl');
open my $fh, '>:encoding(UTF-8)', $file or die "$file: $!";
print $fh $script;
close $fh;

sub run {
    my ($name, @inc) = @_;
    my $out = File::Spec->catfile($dir, "$name.txt");
    system($^X, (map { "-I$_" } @inc), $file, $out, @ARGV) == 0 or die "$name failed: $?";
    open my $in, '<:encoding(UTF-8)', $out or die "$out: $!";
    my @l = <$in>;
    chomp @l;
    return \@l;
}
my $want = run('oracle', File::Spec->catdir($oracle, 'lib'));
my $got = run('ours', @INC);
my @bad = grep { !defined $got->[$_] || $got->[$_] ne $want->[$_] } 0 .. $#$want;
my %loc = map { (split /\t/)[0] => 1 } @$want;
my $died = grep { /\tdied: / } @$want;
ok(@$want > 50000, scalar(@$want) . " texts in " . scalar(keys %loc) . " locales, $died of them refused");
is(scalar @$got, scalar @$want, 'as many answers');
is(scalar @bad, 0, scalar(@$want) . ' answers agree with the pure-Perl 0.01') or do {
    diag(scalar(@bad) . ' differ');
    for my $i (@bad[0 .. ($#bad < 7 ? $#bad : 7)]) { diag("0.01: $want->[$i]\nC:    " . ($got->[$i] // '(none)')) }
};

done_testing;
