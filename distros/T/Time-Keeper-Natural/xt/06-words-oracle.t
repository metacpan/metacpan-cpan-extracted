#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp ();
use FindBin;

# Numbers and Words against the pure-Perl 0.01, in a separate process (the
# oracle is TKN_ORACLE or ../Time-Keeper-Natural-PP). Number words: the
# file every locale reads, and each file's words read back, in capitals, spaced and with
# hyphens as spaces. Word tables: every table in share/words read by both
# from the same file, then frame, split_on, starts, articled and is asked
# of every phrase put into a sentence, written nine ways (as typed, upper
# case, lower case, doubled spaces, no-break spaces, a newline, padded,
# and with each apostrophe swapped for the other), against every key.
my $oracle = $ENV{TKN_ORACLE} || File::Spec->catdir($FindBin::Bin, '..', '..', 'Time-Keeper-Natural-PP');
plan skip_all => "no oracle at $oracle (set TKN_ORACLE to the pure-Perl 0.01 tree)"
    unless -f File::Spec->catfile($oracle, 'lib', 'Time', 'Keeper', 'Natural', 'Words.pm');
my $share = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..', 'share', 'words'));

my $script = <<'SCRIPT';
use strict;
use warnings;
use utf8;
use Time::Keeper;
use Time::Keeper::Natural::Numbers;
use Time::Keeper::Natural::Words;
my ($share, $out) = @ARGV;
open my $fh, '>:encoding(UTF-8)', $out or die "$out: $!";
sub show { join ' | ', map { defined $_ ? "[$_]" : 'undef' } @_ }
my $NW = 'Time::Keeper::Natural::Numbers';
for my $code (Time::Keeper::Locale->codes) {
    my $n = $NW->for($code);
    unless ($n) { print $fh "N $code none\n"; next }
    my %c = $n->cardinals;
    my %o = $n->ordinals;
    print $fh "N $code ", $n->code, ' ', scalar(keys %c), ' ', scalar(keys %o), "\n";
    next if $n->code ne $code;
    for my $w (sort keys %c) {
        print $fh "NC $code $w ", show($n->read($w), $n->read(uc $w), $n->read(" $w  "), $n->read($w =~ s/-/ /gr), $n->ordinal($w)), "\n";
    }
    for my $w (sort keys %o) {
        print $fh "NO $code $w ", show($n->ordinal($w), $n->ordinal(uc $w), $n->read($w)), "\n";
    }
}
print $fh 'NL ', join(' ', $NW->locales), "\n";
my $W = 'Time::Keeper::Natural::Words';
print $fh 'WL ', join(' ', $W->locales), "\n";
opendir my $dh, $share or die;
my @files = sort grep { /\.txt\z/ } readdir $dh;
closedir $dh;
my @KEYS = qw(start_of end_of at on skip and of last);
for my $f (@files) {
    (my $code = $f) =~ s/\.txt\z//;
    my $w = $W->from_file("$share/$f", $code);
    print $fh "W $code ", join(',', $w->keys), ' ', $w->code, "\n";
    print $fh "WT $code ", show(map { @$_ } $w->tests), "\n";
    my @phrases;
    for my $k ($w->keys) {
        my @p = $w->phrases($k);
        print $fh "WP $code $k ", show(@p), "\n";
        push @phrases, @p;
    }
    print $fh "WA $code ", show($w->articled('month')), "\n";
    my @texts = map { $_->[0] } $w->tests;
    for my $p (@phrases) {
        if ($p =~ /\{0\}/) { push @texts, map { (my $t = $p) =~ s/\{0\}/$_/; $t } 'tomorrow', 'next month', 'x' }
        else { push @texts, "next week $p friday", "$p month", "the 3rd $p", $p }
    }
    my %seen;
    for my $t (grep { !$seen{$_}++ } map {
        my $s = $_;
        ($s, uc $s, lc $s, $s =~ s/ /  /gr, $s =~ s/ /\x{a0}/gr, $s =~ s/ /\n/r, "  $s \t", $s =~ tr/'\x{2019}/\x{2019}'/r)
    } @texts) {
        (my $shown = $t) =~ s/\n/\\n/g;
        for my $k (@KEYS) {
            print $fh "F $code $k [$shown] ", show($w->frame($t, $k)), ' / ', show($w->split_on($t, $k)), ' / ', show(scalar $w->starts($t, $k)), "\n";
        }
        my $nk = lc $t;
        print $fh "I $code [$shown] ", join(',', map { $w->is($nk, $_) } @KEYS), "\n";
    }
}
close $fh;
SCRIPT

my $dir = File::Temp->newdir;
# 0.01 knows no range, after, before, weekend, alias or nth key, nor their
# test lines, nor a marked phrase ("am!"): both sides read the tables
# without them.
{
    my $copy = File::Spec->catdir($dir, 'words');
    mkdir $copy or die "$copy: $!";
    opendir my $dh, $share or die "$share: $!";
    for my $f (grep { /\.txt\z/ } readdir $dh) {
        open my $in, '<:raw', "$share/$f" or die "$f: $!";
        open my $out, '>:raw', "$copy/$f" or die "$copy/$f: $!";
        print $out map { /^#/ ? $_ : s/(?<=[\t|])[^\t|\n]*!(?:\||(?=\n))//gr =~ s/\|(?=\n)//r }
            grep { !/^(?:range|after|before|weekend|alias|nth)(?:\t|\n)/ && !m{^# test: .* => \S+ / \S+$} && !/^# test: .*\b(?:after|before|weekend)\b/ } <$in>;
    }
    $share = $copy;
}
my $file = File::Spec->catfile($dir, 'ask.pl');
open my $fh, '>:encoding(UTF-8)', $file or die "$file: $!";
print $fh $script;
close $fh;

sub run {
    my ($name, @inc) = @_;
    my $out = File::Spec->catfile($dir, "$name.txt");
    system($^X, (map { "-I$_" } @inc), $file, $share, $out) == 0 or die "$name failed: $?";
    open my $in, '<:encoding(UTF-8)', $out or die "$out: $!";
    my @l = <$in>;
    chomp @l;
    return \@l;
}
my $want = run('oracle', File::Spec->catdir($oracle, 'lib'));
my $got = run('ours', @INC);
# 0.02 ships es-419 a number file of its own, for its day ordinals ("1º."),
# with Spanish's words in it; 0.01 read es's.
@$got = grep { !/^N[CO] es-419 / } @$got;
s/^N es-419 es-419 /N es-419 es / for @$got;
s/^NL (.*?) es-419 (.*)$/NL $1 $2/ for @$got;
my @bad = grep { !defined $got->[$_] || $got->[$_] ne $want->[$_] } 0 .. $#$want;
my %kinds;
$kinds{ (split / /, $want->[$_])[0] }++ for 0 .. $#$want;
ok($kinds{F} > 10000 && $kinds{NC} > 500, join(', ', map { "$kinds{$_} $_" } sort keys %kinds) . ' asks');
is(scalar @$got, scalar @$want, 'as many answers');
is(scalar @bad, 0, scalar(@$want) . ' answers agree with the pure-Perl 0.01') or do {
    diag(scalar(@bad) . ' differ');
    for my $i (@bad[0 .. ($#bad < 7 ? $#bad : 7)]) { diag("0.01: $want->[$i]\nC:    " . ($got->[$i] // '(none)')) }
};

done_testing;
