#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use utf8;
use open 'IO' => ':utf8';
use open ':std';

use Test::More;

use Text::Lossy;

my $lossy = Text::Lossy->new->add('alphabetize');

is($lossy->process('Hello, World!'), 'Hello, Wlord!', "Internally sorted");
is($lossy->process('alphabetization'), 'aaabehiilopttzn', "Long word internally sorted");
is($lossy->process("!!::..::!! \t\t\r\n 162534"), "!!::..::!! \t\t\r\n 162534", "Whitespace, punctuation and numbers unaffected");
is($lossy->process('dcba1dcba zyx1 1zyx'), 'dcba1dcba zyx1 1zyx', "Requires end-of-word at each side");
is($lossy->process("drüben señor"), "dberün seoñr", "Unicode sorting");
is($lossy->process("こんにちは"), "こちにんは", "More unicode sorting");

done_testing();
