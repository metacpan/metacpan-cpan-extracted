#!/usr/bin/perl
######################################################################
# eg/en/mb_regexp.pl - multibyte-aware matching with mb::qr
#
# What this shows:
#   mb::qr(PATTERN) compiles a regular expression whose "." , character
#   classes and captures work in whole multibyte CHARACTERS under the
#   selected script encoding.
#
# How it differs from CORE:
#   A CORE "." matches a single OCTET, so /(.)/g over three Shift_JIS
#   hiragana yields six pieces. The same pattern through mb::qr yields
#   three, one per character. A class range such as [a-hiragana ... ]
#   compares whole characters, and a capture returns a whole character.
#
# The source is US-ASCII; multibyte data uses \xHH byte escapes. This is
# the runtime interface (no source filter), so it runs on every perl
# from 5.005_03 up.
#
#     perl eg/en/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Three hiragana in Shift_JIS: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE "." is one octet -- six pieces for six bytes.
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") makes "." one whole character -- three pieces. Compile
# once, then interpolate the compiled pattern into the match.
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# Character-class range over the hiragana block a..n (\x82\xA0-\x82\xF1).
# The range compares whole characters, so u is inside and ASCII "A" is not.
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# Capture returns a whole multibyte character (two bytes here), never a
# half of one.
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# Find every hiragana in a mixed string, in character units.
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
