#-*- perl -*-
#-*- coding: utf-8 -*-

use strict;
use warnings;
use Test::More tests => 4;

use Unicode::Precis::Preparation qw(:all);
use t::Utils;

my $ok;

my %chars = (
    "\xEA\xB0\x80"     => '2.0',    # U+AC00
    "\xE2\x82\xAC"     => '2.1',    # U+20AC
    "\xDE\xB0"         => '3.0',    # U+07B0
    "\xF0\x90\x8C\x80" => '3.1',    # U+10300
    "\xEF\xBD\x9F"     => '3.2',    # U+FF5F
    "\xF3\xA0\x84\x80" => '4.0',    # U+E0100
    "\xF0\x90\xA8\x80" => '4.1',    # U+10A00
    "\xF0\x92\x80\x80" => '5.0',    # U+12000
    "\xF0\x9F\x80\x80" => '5.1',    # U+1F000
    "\xF0\xAA\x9C\x80" => '5.2',    # U+2A700
    "\xF0\x9F\x9C\x80" => '6.0',    # U+1F700
    "\xF0\x9E\xB8\x80" => '6.1',    # U+1EE00
    "\xE2\x82\xBA"     => '6.2',    # U+20BA
    "\xD8\x9C"         => '6.3',    # U+061C
);

$ok = 1;
foreach my $ver (('1.1', sort values %chars)) {
    foreach my $char (sort keys %chars) {
        my $result =
            {prepare($char, ValidUTF8, UnicodeVersion => $ver)}->{result};
        if ($ver lt $chars{$char}) {
            unless (defined $result and $result == UNASSIGNED) {
                diag sprintf '%s is in %s',
                    t::Utils::escape_bytestring($char), $ver;
                $ok = 0;
            }
        } elsif (not(defined $result and $result == PVALID)) {
            diag sprintf '%s is not in %s',
                t::Utils::escape_bytestring($char), $ver;
            $ok = 0;
        }
    }
}
ok($ok, 'Versions');

my @DISALLOWED = (
    "\x00",                # U+0000
    "\x7F",                # U+007F
    "\xC2\x80",            # U+0080
    "\xC2\xAD",            # U+00AD
    "\xDF\xBA",            # U+07FA
    "\xE1\x84\x80",        # U+1100
    "\xEF\xBF\xBB",        # U+FFFB
    "\xF0\x91\x82\xBD",    # U+110BD
    "\xF3\xA0\x80\x81",    # U+E0001
    "\xF3\xB0\x80\x80",    # U+F0000
    "\xF3\xBF\xBF\xBD",    # U+FFFFD
    "\xF4\x80\x80\x80",    # U+100000
    "\xF4\x8F\xBF\xBD",    # U+10FFFD
);

$ok = 1;
foreach my $char (@DISALLOWED) {
    my $result;
    $result = {prepare($char, ValidUTF8, UnicodeVersion => '5.2')}->{result};
    unless (defined $result and $result == PVALID) {
        diag sprintf '%s is not in ValidUTF8',
            t::Utils::escape_bytestring($char);
        $ok = 0;
    }
    $result =
        {prepare($char, FreeFormClass, UnicodeVersion => '5.2')}->{result};
    unless (defined $result and $result == DISALLOWED) {
        diag sprintf '%s is in FreeFormClass',
            t::Utils::escape_bytestring($char);
        $ok = 0;
    }
}
ok($ok, 'PVALID');

my @PVALID = (
    "\x21",                # U+0021
    "\x7E",                # U+007E
    "\xC3\x80",            # U+00C0
    "\xDF\xB5",            # U+07F5
    "\xE0\xA0\x80",        # U+0800
    "\xEF\xB9\xB3",        # U+FE73
    "\xF0\x90\x80\x80",    # U+10000
    "\xF0\xA0\x80\x80",    # U+20000
    "\xF0\xAB\x9D\x80",    # U+2B740
);

$ok = 1;
foreach my $char (@PVALID) {
    my $result;
    $result =
        {prepare($char, IdentifierClass, UnicodeVersion => '6.0')}->{result};
    unless (defined $result and $result == PVALID) {
        diag sprintf '%s is not in IdentifierClass',
            t::Utils::escape_bytestring($char);
        $ok = 0;
    }
    $result =
        {prepare($char, FreeFormClass, UnicodeVersion => '6.0')}->{result};
    unless (defined $result and $result == PVALID) {
        diag sprintf '%s is not in FreeFormClass',
            t::Utils::escape_bytestring($char);
        $ok = 0;
    }
}
ok($ok, 'PVALID');

my @ID_DIS = (
    "\x20",                # U+0020
    "\xC2\xA0",            # U+00A0
    "\xDF\xB9",            # U+07F9
    "\xE0\xA0\xB0",        # U+0830
    "\xEF\xBF\xBD",        # U+FFFD
    "\xF0\x90\x84\x80",    # U+10100
    "\xF0\xAF\xA0\x80",    # U+2F800
);

$ok = 1;
foreach my $char (@ID_DIS) {
    my $result;
    $result =
        {prepare($char, IdentifierClass, UnicodeVersion => '5.2')}->{result};
    unless (defined $result and $result == DISALLOWED) {
        diag sprintf '%s is in IdentifierClass',
            t::Utils::escape_bytestring($char);
        $ok = 0;
    }
    $result =
        {prepare($char, FreeFormClass, UnicodeVersion => '5.2')}->{result};
    unless (defined $result and $result == PVALID) {
        diag sprintf '%s is not in FreeFormClass',
            t::Utils::escape_bytestring($char);
        $ok = 0;
    }
}
ok($ok, 'ID_DIS or FREE_PVAL');
