#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2510;
use Text::Match::FastAlternatives;

sub invalid_ok {
    my ($s, $msg) = @_;
    ok(!Text::Match::FastAlternatives->utf8_valid($s), "invalid UTF-8, $msg");
}

sub valid_ok {
    my ($s, $msg) = @_;
    ok(Text::Match::FastAlternatives->utf8_valid($s), "valid UTF-8, $msg");
}

valid_ok('', 'empty string');
valid_ok(chr, 'plain ASCII')
    for 0x00 .. 0x7F;
valid_ok(chr() . "\xBF", sprintf '%02X BF', $_)
    for 0xC2 .. 0xDF;
valid_ok(chr() . "\xBF\xBF", sprintf '%02X BF BF', $_)
    for 0xE0 .. 0xEC, 0xEE, 0xEF;
valid_ok("\xED\x9F\xBF", 'ED 9F BF');
valid_ok(chr() . "\xBF\xBF\xBF", sprintf '%02X BF BF BF', $_)
    for 0xF0 .. 0xF4;
valid_ok("d\xC3\xA9ja\xCC\x80 vu\xE2\x80\xA6", 'mixed string');

invalid_ok(chr, sprintf 'leading byte %02X too low', $_)
    for 0x80 .. 0xC1;
invalid_ok(chr, sprintf 'leading byte %02X too high', $_)
    for 0xF5 .. 0xFF;
invalid_ok(chr, sprintf 'leading byte %02X needs a continuation byte', $_)
    for 0xC2 .. 0xF4;
invalid_ok(chr() . "\xBF", sprintf 'leading byte %02X needs 2 continuation bytes', $_)
    for 0xE0 .. 0xF4;
invalid_ok(chr() . "\xBF\xBF", sprintf 'leading byte %02X needs 3 continuation bytes', $_)
    for 0xF0 .. 0xF4;

invalid_ok("\xC2" . chr, sprintf 'overlong sequence C2 %02X', $_)
    for 0 .. 0x3F;
invalid_ok("\xE0\x07\xFF", 'overlong sequence E0 07 FF');
invalid_ok("\xF0\x8F\xBF\xBF", 'overlong sequence F0 8F BF BF');
valid_ok("\xF0\x90\x80\x80", 'exact sequence F0 90 80 80');

invalid_ok(chr() . "\x7F", sprintf 'continuation byte for %02X must be high enough', $_)
    for 0xC2 .. 0xDF;
invalid_ok(chr() . "\xFE", sprintf 'continuation byte for %02X must be low enough', $_)
    for 0xC2 .. 0xDF;

{
    my $surrogate = 0xD800;
    for my $prefix (map { "\xED" . chr } 0xA0 .. 0xBF) {
        invalid_ok($prefix . chr, sprintf 'surrogate %04X', $surrogate++)
            for 0x80 .. 0xBF;
    }
}
