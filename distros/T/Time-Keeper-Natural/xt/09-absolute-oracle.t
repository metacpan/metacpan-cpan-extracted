#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp ();
use FindBin;

# Absolute dates and times against the pure-Perl 0.01, in a separate process
# (TKN_ORACLE or ../Time-Keeper-Natural-PP). In every locale, with the clock
# pinned: two moments written in the locale's four date, time and date-time
# formats and every skeleton it has; a relative day and a time together
# either way round; ISO and RFC forms; bare hours and day periods; a weekday
# that does not fit; each through match under three parsers (no options,
# bare_hour => 'next', prefer => 'past'), its value, precision and
# assumptions, or its death.
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
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, zone => 'Europe/London');
my @MOMENTS = (Time::Keeper->new(year => 2026, month => 3, day => 7, hour => 15, minute => 5, second => 9, zone => 'Europe/London'),
               Time::Keeper->new(year => 2027, month => 11, day => 23, hour => 4, minute => 45, zone => 'Europe/London'));
for my $loc ($L->codes) {
    next if defined $only && $loc ne $only;
    my @parsers = map { Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London', @$_) } [], [bare_hour => 'next'], [prefer => 'past'];
    my (@texts, %seen);
    my $af = $L->available_formats($loc) || {};
    my @pats = ($L->formats($loc, 'date'), $L->formats($loc, 'time'), map { $af->{$_} } grep { !/-/ } sort keys %$af);
    for my $m (@MOMENTS) {
        my $v = $m->in_locale($loc);
        push @texts, map { my $p = $_; eval { $v->format($p) } // () } @pats;
        push @texts, map { my $w = $_; eval { $v->format_datetime($w) } // () } qw(full long medium short);
    }
    my $day = $L->relative_names($loc, 'day', 'long')->{at}{1};
    my $short_time = eval { $MOMENTS[0]->in_locale($loc)->format_time('short') };
    if (defined $day && defined $short_time) { push @texts, "$day $short_time", "$short_time $day" }
    for my $p (sort keys %{ $L->day_periods($loc, 'wide') || {} }) {
        my $name = $L->day_periods($loc, 'wide')->{$p};
        push @texts, $name, "3 $name", "11 $name" if defined $name;
    }
    push @texts, '2026-10-20T15:00:00Z', '2026-10-20', '2026-10', '2026', '2026-W43', '2026-10-20 15:30', '@1792000000',
                 'Tue, 20 Oct 2026 15:00:00 GMT', '3', '15', '0', '24', '7 pm', 'Friday 15 October 2026', '15/10/26', 'zzz 3';
    for my $t (grep { defined && length && !$seen{$_}++ } @texts) {
        my @got;
        for my $n (@parsers) {
            my $r = eval { $n->match($t) };
            my $got;
            if ($r) { $got = join ' ', $r->value . '', $r->precision // '-', join(',', $r->assumed) }
            else { ($got = $@) =~ s/ at \S+ line \d+\.?\n?\z//; $got = "died: $got" }
            push @got, $got;
        }
        my $line = join "\t", $loc, $t, @got;
        $line =~ s/\n/\\n/g;
        print $fh "$line\n";
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
# 0.02 reads texts 0.01 died on: a zone named after a time, a spaceless
# locale's date and time set apart by a space. Each answer that differs must
# be one of those; whether it is right is the round trips' (xt/01, xt/14).
my %zone = map { $_ => 1 } grep {
    my @w = (split /\t/, $want->[$_])[2 .. 4];
    my @g = (split /\t/, $got->[$_] // '')[2 .. 4];
    !$tie{$_} && @g == 3 && grep({ $w[$_] ne $g[$_] } 0 .. 2)
        && !grep({ $w[$_] ne $g[$_] && ($w[$_] !~ /^died: / || $g[$_] =~ /^died: /) } 0 .. 2)
} 0 .. $#$want;
note(scalar(keys %zone) . " texts 0.01 could not read now read");
my @bad = grep { !$tie{$_} && !$zone{$_} && (!defined $got->[$_] || $got->[$_] ne $want->[$_]) } 0 .. $#$want;
my %loc = map { (split /\t/)[0] => 1 } @$want;
my $died = grep { /\tdied: / } @$want;
ok(@$want > 100000, scalar(@$want) . " texts in " . scalar(keys %loc) . " locales, three parsers each, $died with a death");
is(scalar @$got, scalar @$want, 'as many answers');
is(scalar @bad, 0, scalar(@$want) . ' answers agree with the pure-Perl 0.01') or do {
    diag(scalar(@bad) . ' differ');
    for my $i (@bad[0 .. ($#bad < 7 ? $#bad : 7)]) { diag("0.01: $want->[$i]\nC:    " . ($got->[$i] // '(none)')) }
};

done_testing;
