#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
use Unicode::Normalize ();
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural::Lexicon;

# Lexicon->key, ->normalise, ->ascii_digits and ->_spellings are C since
# 0.01's port; the reference below is 0.01's Perl, word for word, and the C
# must agree with it on every string every locale's lexicon is built from,
# each also written five more ways (upper case, spaced out, with no-break
# spaces, with invisible marks, with curly apostrophes) in twelve locales,
# or in all of them under AUTHOR_TESTING or RELEASE_TESTING (1.9 million
# strings, 15 seconds).
# U+180E MONGOLIAN VOWEL SEPARATOR is no space since Unicode 6.3, though
# [\s\p{Zs}] on perls before 5.18 still takes it; the C keeps it in the word.
# What 0.01 kept in the lexicon's hash, rebuilt from the locale's data.
my %STATE;
sub state_of {
    my ($lex) = @_;
    return $STATE{ $lex->code } ||= do {
        my @digits = Time::Keeper::Locale->digits($lex->code);
        my %s = (spaceless => $lex->spaceless);
        if (join('', @digits) ne '0123456789') {
            $s{digit_map} = { map { $digits[$_] => $_ } 0 .. 9 };
            my $chars = join '', map { quotemeta } @digits;
            $s{digit_re} = qr/([$chars])/;
        }
        \%s;
    };
}
sub ref_normalise {
    my ($lex, $s) = @_;
    if ($s =~ /[^\x00-\x7f]/) {
        $s = Unicode::Normalize::NFC($s);
        $s =~ tr/\x{2018}\x{2019}\x{02bc}/'''/;
        $s =~ s/[\x{200b}-\x{200f}\x{feff}\x{061c}]//g;
        $s =~ s/(?:(?!\x{180e})[\s\p{Zs}])+/ /g;
    }
    else {
        $s =~ s/\s+/ /g;
    }
    $s = lc $s;
    $s =~ s/^ //;
    $s =~ s/ \z//;
    $s =~ s/ //g if state_of($lex)->{spaceless};
    return $s;
}
sub ref_ascii_digits {
    my ($lex, $s) = @_;
    my $st = state_of($lex);
    return $s unless defined $s && $st->{digit_re};
    $s =~ s/$st->{digit_re}/$st->{digit_map}{$1}/g;
    return $s;
}
sub ref_key { my ($lex, $s) = @_; return ref_normalise($lex, ref_ascii_digits($lex, $s)) }
sub ref_spellings {
    my ($lex, $k) = @_;
    return ($k) if index($k, '.') < 0;
    (my $bare = $k) =~ s/\.//g;
    $bare =~ s/  +/ /g;
    $bare =~ s/^ //;
    $bare =~ s/ \z//;
    return $bare eq $k || $bare eq '' ? ($k) : ($k, $bare);
}

my $X = 'Time::Keeper::Natural::Lexicon';
my $L = 'Time::Keeper::Locale';
my @FIELDS = qw(year quarter month week day hour minute second mon tue wed thu fri sat sun);
my @UNITS  = qw(year month week day hour minute second millisecond microsecond nanosecond);

sub strings_of {
    my ($loc) = @_;
    my @d = $L->digits($loc);
    my $three = @d ? $d[3] : '3';
    my $n21 = @d ? "$d[2]$d[1]" : '21';
    my @s;
    for my $f (@FIELDS) {
        for my $w (qw(long short narrow)) {
            my $r = $L->relative_names($loc, $f, $w);
            push @s, $r->{display} if defined $r->{display};
            push @s, values %{ $r->{at} };
            for my $p (map { values %{ $r->{$_} || {} } } qw(future past)) {
                push @s, $p, map { (my $t = $p) =~ s/\{0\}/$_/g; $t } $three, $n21;
            }
        }
    }
    for my $u (@UNITS) {
        for my $w (qw(long short narrow)) {
            my $r = $L->unit_patterns($loc, $u, $w) or next;
            push @s, $r->{display} if defined $r->{display};
            push @s, map { (my $t = $_) =~ s/\{0\}/$three/g; ($_, $t) } values %{ $r->{count} || {} };
        }
    }
    for my $kind (qw(months days am_pm)) {
        for my $w (qw(wide abbreviated narrow)) {
            push @s, $L->names($loc, $kind, $w, $_) for qw(format stand-alone);
        }
    }
    return grep { defined && length } @s;
}

sub variants {
    my ($s) = @_;
    (my $spaced = "  $s ") =~ s/ /  \t/g;
    (my $nbsp = $s) =~ s/ /\x{a0}\x{3000}/g;
    (my $marks = $s) =~ s/(.)/\x{200e}$1\x{200b}/;
    (my $curly = $s) =~ s/'/\x{2019}/g;
    return ($s, uc $s, $spaced, $nbsp, "\x{feff}$marks\x{061c}", $curly);
}

my $ALL = $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};
my %VARIED = map { $_ => 1 } qw(en en-GB fr de ru ar-EG fa he ja zh th hi);
my ($asks, $locales, @bad) = (0, 0);
for my $loc ($L->codes) {
    my $lex = $X->for($loc);
    $locales++;
    my %seen;
    my @s = strings_of($loc);
    @s = map { variants($_) } @s if $ALL || $VARIED{$loc};
    for my $s (grep { !$seen{$_}++ } @s) {
        $asks++;
        my $want = ref_key($lex, $s);
        my $got  = $lex->key($s);
        if ($got ne $want) { push @bad, "$loc key '$s': '$got' not '$want'"; next }
        my $n = $lex->normalise($s);
        push @bad, "$loc normalise '$s': '$n'" if $n ne ref_normalise($lex, $s);
        my $a = $lex->ascii_digits($s);
        push @bad, "$loc ascii_digits '$s': '$a'" if $a ne ref_ascii_digits($lex, $s);
        my @sp = $lex->_spellings($got);
        push @bad, "$loc _spellings '$got': @sp" if "@sp" ne join ' ', ref_spellings($lex, $got);
    }
    last if @bad > 20;
}
ok($locales > 1000, "$locales locales");
is(scalar @bad, 0, "$asks strings: key, normalise, ascii_digits and _spellings agree with 0.01's Perl") or diag(join "\n", @bad[0 .. ($#bad < 19 ? $#bad : 19)]);

# The cases the sweep does not reach.
my $en = $X->for('en');
my $ar = $X->for('ar-EG');
my $ja = $X->for('ja');
is($en->key(undef), '', 'undef keys as nothing');
is($en->normalise("caf\xe9  NOW"), "caf\x{e9} now", 'a Latin-1 string without the UTF-8 flag is its characters');
is($en->normalise("Cafe\x{301}"), "caf\x{e9}", 'NFC joins a combining accent');
is($en->normalise(" \t\n "), '', 'white space alone is nothing');
is($en->normalise("A\x{2028}B\x{85}C"), 'a b c', 'line and paragraph separators and NEL are spaces');
is($en->normalise("\x{130}"), lc("\x{130}"), 'the dotted capital I lowers as lc does');
is($ja->normalise("明 日"), '明日', 'a spaceless locale drops every space');
is($ar->key("٣ ساعات"), '3 ساعات', 'Arabic-Indic digits key as ASCII');
is($ar->ascii_digits(undef), undef, 'ascii_digits keeps undef');
is($en->ascii_digits("١٢"), "١٢", 'a locale writing 0 to 9 maps nothing');
is_deeply([ $en->_spellings('a.m.') ], [ 'a.m.', 'am' ], 'a dotted key has its bare spelling');
is_deeply([ $en->_spellings('. .') ], [ '. .' ], 'a key that is all dots has no bare one');
is_deeply([ $en->_spellings('x . y') ], [ 'x . y', 'x y' ], 'spaces left by a dot collapse');

done_testing;
