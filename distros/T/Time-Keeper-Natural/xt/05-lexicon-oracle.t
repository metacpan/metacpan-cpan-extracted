#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::MD5 ();
use File::Spec;
use File::Temp ();
use FindBin;

# Every table of every locale's lexicon against the pure-Perl 0.01's, in
# a separate process: the oracle is the 0.01 tree, TKN_ORACLE or
# ../Time-Keeper-Natural-PP beside this one. Each locale's tables, markers,
# joiners, patterns and ties are written as canonical text and compared by
# digest; a difference prints the first lines that differ.
my $oracle = $ENV{TKN_ORACLE} || File::Spec->catdir($FindBin::Bin, '..', '..', 'Time-Keeper-Natural-PP');
plan skip_all => "no oracle at $oracle (set TKN_ORACLE to the pure-Perl 0.01 tree)"
    unless -f File::Spec->catfile($oracle, 'lib', 'Time', 'Keeper', 'Natural', 'Lexicon.pm');

my $canon = <<'CANON';
use strict;
use warnings;
use Time::Keeper;
use Time::Keeper::Natural::Lexicon;
use Digest::MD5 ();
our $C_SIDE;
my @LIST = qw(fixed counted unit_fixed unit_counted bare bare_fixed field_names);
my @VALUE = qw(numbers ordinals num_tok num_char);
sub cm { my ($m) = @_; join ',', map { "$_=" . (ref $m->{$_} ? join('', @{ $m->{$_} }) : $m->{$_}) } sort keys %$m }
sub sections {
    my ($code) = @_;
    my $lex = Time::Keeper::Natural::Lexicon->for($code);
    my $t;
    if ($C_SIDE) { $t = $lex->_tables }
    else {
        $lex->ordinal('x');
        $t = { %$lex };
    }
    my %out;
    for my $n (@LIST) {
        my $h = $t->{$n} || {};
        $out{$n} = join "\n", map { (my $k = $_) =~ s/\0/{N}/; "$k\t" . join(';', sort map { cm($_) } @{ $h->{$_} }) } sort keys %$h;
    }
    for my $n (@VALUE) {
        my $h = $t->{$n} || {};
        $out{$n} = join "\n", map { "$_=$h->{$_}" } sort keys %$h;
    }
    $out{markers} = join '|', map { @{ $t->{markers}{$_} } } qw(future past);
    $out{joiners} = join "\n", map { "$_->{word}|$_->{raw}" } @{ $t->{joiners} };
    $out{scalars} = join ',', map { "$_=" . ($t->{$_} ? $t->{$_} : 0) } qw(num_max spaceless);
    $out{digit_map} = join ',', map { "$_=$t->{digit_map}{$_}" } sort keys %{ $t->{digit_map} || {} };
    $out{patterns} = join "\n", map { cm($_) } $lex->patterns;
    my $ties = $lex->ties;
    $out{ties} = join "\n", map { "$_\t" . join(';', sort map { cm($_) } @{ $ties->{$_} }) } sort keys %$ties;
    $out{api} = join "\n", map { join '|', @$_ } [ $lex->markers('future') ], [ $lex->markers('past') ],
        [ $lex->joiners ], [ $lex->lead_joiners ], [ $lex->tail_joiners ], [ $lex->code, $lex->spaceless ? 1 : 0 ],
        [ map { "$_=" . ($lex->digital->{$_} // '') } sort keys %{ $lex->digital } ],
        [ map { my $l = $lex->lists($_); map { "$_=$l->{$_}" } sort keys %$l } qw(standard unit unit-short unit-narrow) ];
    return \%out;
}
sub digests {
    my ($fh, $only) = @_;
    for my $code (Time::Keeper::Locale->codes) {
        next if $only && $code ne $only;
        my $s = sections($code);
        for my $n (sort keys %$s) {
            my $b = $s->{$n};
            my $v;
            if ($only) { ($v = $b) =~ s/\n/\\n/g; $v =~ s/\t/\\t/g }
            else { utf8::encode($b); $v = Digest::MD5::md5_hex($b) }
            print $fh join("\t", $code, $n, $v), "\n";
        }
    }
}
1;
CANON

my $dir = File::Temp->newdir;
my $lib = File::Spec->catfile($dir, 'canon.pl');
open my $fh, '>:encoding(UTF-8)', $lib or die "$lib: $!";
print $fh "use utf8;\n", $canon;
close $fh;

sub read_digests {
    my ($fh) = @_;
    my %d;
    while (my $l = <$fh>) { chomp $l; my ($c, $n, $v) = split /\t/, $l, 3; $d{"$c\t$n"} = $v }
    return \%d;
}
sub oracle {
    my ($only) = @_;
    my $out = File::Spec->catfile($dir, 'oracle.txt');
    my $code = sprintf q{open STDOUT, '>:encoding(UTF-8)', q{%s} or die; require q{%s}; digests(\*STDOUT, %s)},
        $out, $lib, defined $only ? "q{$only}" : 'undef';
    system($^X, '-I' . File::Spec->catdir($oracle, 'lib'), '-e', $code) == 0 or die "the oracle failed: $?";
    open my $in, '<:encoding(UTF-8)', $out or die "$out: $!";
    return read_digests($in);
}
sub ours {
    my ($only) = @_;
    my $out = File::Spec->catfile($dir, 'ours.txt');
    { no warnings q{once}; $main::C_SIDE = 1 }
    require $lib;
    open my $o, '>:encoding(UTF-8)', $out or die "$out: $!";
    digests($o, $only);
    close $o;
    open my $in, '<:encoding(UTF-8)', $out or die "$out: $!";
    return read_digests($in);
}

my ($want, $got) = (oracle(), ours());
my @bad = grep { !defined $got->{$_} || $got->{$_} ne $want->{$_} } sort keys %$want;
my %locales = map { (split /\t/)[0] => 1 } keys %$want;
ok(keys %locales > 1000, scalar(keys %locales) . ' locales from the oracle');
is(scalar(keys %$got), scalar(keys %$want), 'the same sections');
is(scalar @bad, 0, scalar(keys %$want) . ' sections agree with the pure-Perl 0.01') or do {
    my %by;
    $by{ (split /\t/)[1] }++ for @bad;
    diag(scalar(@bad) . ' differ: ' . join(', ', map { "$_ $by{$_}" } sort keys %by) . '; the first: ' . join(' ', @bad[0 .. ($#bad < 9 ? $#bad : 9)]));
    my %seen;
    for my $b (grep { !$seen{ (split /\t/)[1] }++ } @bad) {
        my ($c, $n) = split /\t/, $b;
        my ($w, $g) = (oracle($c)->{"$c\t$n"}, ours($c)->{"$c\t$n"});
        my @w = split /\\n/, $w // '';
        my @g = split /\\n/, $g // '';
        my $shown = 0;
        diag("$c $n:");
        for my $i (0 .. ($#w > $#g ? $#w : $#g)) {
            next if defined $w[$i] && defined $g[$i] && $w[$i] eq $g[$i];
            diag("  line $i\n    0.01: " . ($w[$i] // '(none)') . "\n    C:    " . ($g[$i] // '(none)'));
            last if ++$shown >= 3;
        }
    }
};

done_testing;
