#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp ();
use FindBin;

# Relative points and chains against the pure-Perl 0.01, in a separate
# process (TKN_ORACLE or ../Time-Keeper-Natural-PP). In every locale, with
# the clock pinned: every relative word and pattern CLDR has (15 fields,
# three widths, counts 0, 1, 2, 5 and 21 in the locale's digits and in
# ASCII), chains of two parts joined by the locale's list patterns, with and
# without the second part's marker, and broken phrases; each through match,
# its value, precision and assumptions, or its death.
my $oracle = $ENV{TKN_ORACLE} || File::Spec->catdir($FindBin::Bin, '..', '..', 'Time-Keeper-Natural-PP');
plan skip_all => "no oracle at $oracle (set TKN_ORACLE to the pure-Perl 0.01 tree)"
    unless -f File::Spec->catfile($oracle, 'lib', 'Time', 'Keeper', 'Natural.pm');

my $script = <<'SCRIPT';
use strict;
use warnings;
use Time::Keeper;
use Time::Keeper::Natural;
my ($out, $sorted, $only) = @ARGV;
open my $fh, '>:encoding(UTF-8)', $out or die "$out: $!";
if ($sorted) {
    # 0.01 took a phrase's offsets in hash order, so a phrase with two
    # meanings ("på mandag", this Monday and next) read as either; the C
    # takes them sorted. The oracle is made to iterate them the same way.
    package Sorted::Hash;
    require Tie::Hash;
    our @ISA = ('Tie::StdHash');
    our (%K, %I);
    sub FIRSTKEY { my ($h) = @_; $K{$h} = [ sort keys %$h ]; $I{$h} = 0; return $K{$h}[0] }
    sub NEXTKEY { my ($h) = @_; return $K{$h}[ ++$I{$h} ] }
    package main;
    no warnings 'redefine';
    my $orig = \&Time::Keeper::Locale::relative_names;
    *Time::Keeper::Locale::relative_names = sub {
        my $r = $orig->(@_);
        return $r unless ref $r eq 'HASH' && ref $r->{at} eq 'HASH';
        tie my %at, 'Sorted::Hash';
        %at = %{ $r->{at} };
        return { %$r, at => \%at };
    };
}
my $L = 'Time::Keeper::Locale';
my @FIELDS = qw(year quarter month week day hour minute second mon tue wed thu fri sat sun);
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, zone => 'Europe/London');
sub fill { my ($p, $n) = @_; (my $t = $p) =~ s/\{0\}/$n/g; $t }
for my $loc ($L->codes) {
    next if defined $only && $loc ne $only;
    my @d = $L->digits($loc);
    my $n = Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London');
    my (@texts, %seen);
    for my $f (@FIELDS) {
        for my $w (qw(long short narrow)) {
            my $r = $L->relative_names($loc, $f, $w);
            push @texts, map { $r->{at}{$_} } sort keys %{ $r->{at} };
            for my $dir (qw(future past)) {
                for my $p (map { $r->{$dir}{$_} } sort keys %{ $r->{$dir} || {} }) {
                    for my $c (0, 1, 2, 5, 21) {
                        push @texts, fill($p, $c);
                        push @texts, fill($p, join '', map { $d[$_] } split //, $c) if @d;
                    }
                }
            }
        }
    }
    my $two = ($L->list_patterns($loc, 'unit') || {})->{two};
    if (defined $two) {
        for my $dir (qw(future past)) {
            my $h = $L->relative_names($loc, 'hour', 'long')->{$dir}{other};
            my $m = $L->relative_names($loc, 'minute', 'long')->{$dir}{other};
            my $u = $L->unit_patterns($loc, 'minute', 'long')->{count}{other};
            my $dd = $L->relative_names($loc, 'day', 'long')->{$dir}{other};
            next unless defined $h && defined $m;
            for my $pair ([ fill($h, 2), fill($m, 30) ], [ fill($h, 2), defined $u ? fill($u, 30) : 'x' ], [ fill($dd, 3), fill($h, 4) ]) {
                (my $t = $two) =~ s/\{0\}/$pair->[0]/;
                $t =~ s/\{1\}/$pair->[1]/;
                push @texts, $t;
            }
        }
    }
    my @broken = map { ("$_ zzz", "zzz $_") } grep { defined } @texts[0 .. 3];
    for my $t (grep { defined && !$seen{$_}++ } @texts, @broken, 'zzz') {
        my $m = eval { $n->match($t) };
        my $got;
        if ($m) { $got = join ' ', $m->value . '', $m->precision // '-', join(',', $m->assumed) }
        else { eval { $n->parse($t) }; ($got = $@) =~ s/ at \S+ line \d+\.?\n?\z//; $got = "died: $got" }
        $got =~ s/\n/\\n/g;
        print $fh "$loc\t$t\t$got\n";
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
# 0.02 reads chains 0.01 died on in a spaceless locale, where a piece starts
# with its direction word ("ในอีก 2 ชั่วโมง และ 30 นาที") or a number word:
# an answer may differ only that way.
my %gain = map { $_ => 1 } grep {
    !$tie{$_} && defined $got->[$_] && $got->[$_] ne $want->[$_] && $want->[$_] =~ /\tdied: / && $got->[$_] !~ /\tdied: /
} 0 .. $#$want;
note(scalar(keys %gain) . " texts 0.01 could not read now read");
my @bad = grep { !$tie{$_} && !$gain{$_} && (!defined $got->[$_] || $got->[$_] ne $want->[$_]) } 0 .. $#$want;
my %loc = map { (split /\t/)[0] => 1 } @$want;
my $died = grep { /\tdied: / } @$want;
ok(@$want > 100000, scalar(@$want) . " texts in " . scalar(keys %loc) . " locales, $died of them refused");
is(scalar @$got, scalar @$want, 'as many answers');
is(scalar @bad, 0, scalar(@$want) . ' answers agree with the pure-Perl 0.01') or do {
    diag(scalar(@bad) . ' differ');
    for my $i (@bad[0 .. ($#bad < 7 ? $#bad : 7)]) { diag("0.01: $want->[$i]\nC:    " . ($got->[$i] // '(none)')) }
};

done_testing;
