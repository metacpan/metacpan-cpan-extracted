#-*- perl -*-
#-*- coding: utf-8 -*-

use strict;
use warnings;

use Test::More tests => 11;
use Unicode::Precis::Preparation qw(:all);
use t::Utils;

my $ebcdic = (pack('U', 0x0041) ne 'A');

# undef
is(prepare(undef), undef, 'undef');
is_deeply([prepare(undef)], [], 'undef');

# empty string
dotest('Empty string', [result => PVALID, offset => 0], "");

# Non-shortest form
my @NONSHORTEST = (
    "\xC0\x80",         "\xE0\x80\x80",
    "\xF0\x80\x80\x80", "\xC1\xBF",
    "\xE0\x9F\xBF",     "\xF0\x80\x81\xBF",
    "\xE0\x82\x80",     "\xF0\x80\x82\x80",
    "\xE0\x9F\xBF",     "\xF0\x80\x9F\xBF",
    "\xF0\x84\x80\x80", "\xF0\x8F\xBF\xBF"
);
dotest('Non-shortest', [result => DISALLOWED, offset => 0], @NONSHORTEST);

# Incomplete
my $ok       = 1;
my @COMPLETE = (
    "\xC2\x80", "\xDF\xBA", "\xE0\xA0\x80", "\xEF\xA0\x80",
    "\xF0\x90\x80\x80"
);
foreach my $uc (@COMPLETE) {
    foreach
        my $str (($uc . substr($uc, 0, -1), $uc . substr($uc, 0, -1) . $uc)) {
        unless (
            eq_array(
                [prepare($str, ValidUTF8, UnicodeVersion => '5.2')],
                [result => DISALLOWED, offset => length $uc],
                'Incomplete'
            )
            ) {
            diag sprintf '%s %s', 'Incomplete',
                t::Utils::escape_bytestring($str);
            $ok = 0;
            last;
        }
        unless ($ebcdic) {
            Unicode::Precis::Preparation::__utf8_on($str);
            unless (
                eq_array(
                    [prepare($str, ValidUTF8, UnicodeVersion => '5.2')],
                    [result => DISALLOWED, offset => 1]
                )
                ) {
                diag sprintf '%s U+%04X ?', 'Incomplete', ord $uc;
                $ok = 0;
                last;
            }
        }
    }
}
ok($ok, 'Incomplete');

# Beyond Unicode
dotest('Non-Unicode', [result => DISALLOWED, offset => 0, length => 1, 'ord'],
    "\xF4\x90\x80\x80");
my @NONUNICODE = (
    "\xF8\x88\x80\x80\x80",
    "\xFC\x84\x80\x80\x80\x80",
    "\xFE\x84\x80\x80\x80\x80\x80",
    "\xFF\x80\x80\x80\x80\x80\x81\x80\x80\x80\x80\x80\x80\x80"
);
dotest('Longer sequence', [result => DISALLOWED, offset => 0], @NONUNICODE);

# Disallowed (noncharacters)
my @NONCHARACTERS;
# U+FDD0 .. U+FDEF
foreach my $b3 (0x90 .. 0xAF) {
    push @NONCHARACTERS, sprintf "\xEF\xB7%c", $b3;
}
# U+FFFE .. U+FFFF
foreach my $b3 (0xBE .. 0xBF) {
    push @NONCHARACTERS, sprintf "\xEF\xBF%c", $b3;
}
# U+1FFF[EF] .. U+10FFF[EF]
foreach my $b1 (0xF0 .. 0xF4) {
    foreach my $b2 ((0x8F, 0x9F, 0xAF, 0xBF)) {
        foreach my $b4 (0xBE .. 0xBF) {
            my $uc = sprintf "%c%c\xBF%c", $b1, $b2, $b4;
            next if $uc lt "\xF0\x9F\xBF\xBE";
            last if $uc gt "\xF4\x8F\xBF\xBF";
            push @NONCHARACTERS, $uc;
        }
    }
}
dotest('Noncharacter',
    [result => DISALLOWED, offset => 0, length => 1, 'ord'],
    @NONCHARACTERS);

# Disallowed (surrogates)
my @SURROGATES;
foreach my $b2 (0xA0 .. 0xBF) {
    foreach my $b3 (0x80 .. 0xBF) {
        push @SURROGATES, sprintf "\xED%c%c", $b2, $b3;
    }
}
dotest('Surrogate', [result => DISALLOWED, offset => 0, length => 1, 'ord'],
    @SURROGATES);

# Private use
my @PRIVATEUSE;

# U+E000..U+EFFF, U+F000..U+F8FF
@PRIVATEUSE =
    ("\xEE\x80\x80", "\xEE\xBF\xBF", "\xEF\x80\x80", "\xEF\xA3\xBF");
dotest('Private Use in BMP', [result => PVALID, offset => 3], @PRIVATEUSE);

# U+F0000..U+FFFFD, U+100000..U+10FFFD
@PRIVATEUSE = (
    "\xF3\xB0\x80\x80", "\xF3\xBF\xBF\xBD",
    "\xF4\x80\x80\x80", "\xF4\x8F\xBF\xBD"
);
dotest('Private Use', [result => PVALID, offset => 4], @PRIVATEUSE);

sub dotest {
    my $legend   = shift;
    my $expected = shift;
    my @chars    = @_;

    my $result;
    my $ok = 1;
    foreach my $uc (@chars) {
        my $exp = [@$expected];
        $exp->[5] = length $uc if 6 <= scalar @$exp;
        $result = [prepare($uc, ValidUTF8, UnicodeVersion => '4.0')];
        pop @$result if scalar @$result == 8;
        unless (eq_array($result, $exp)) {
            diag sprintf '%s %s', $legend, t::Utils::escape_bytestring($uc);
            $ok = 0;
            last;
        }
        unless ($ebcdic) {
            Unicode::Precis::Preparation::__utf8_on($uc);
            my $exp = [@$expected];
            $exp->[3] = 1 if 4 <= scalar @$exp and $exp->[3];
            $exp->[5] = 1 if 6 <= scalar @$exp;
            $result = [prepare($uc, ValidUTF8, UnicodeVersion => '4.0')];
            pop @$result if scalar @$result == 8;
            unless (eq_array($result, $exp)) {
                diag sprintf '%s U+%04X', $legend, ord $uc;
                $ok = 0;
                last;
            }
        }
    }
    ok($ok, $legend);
}
