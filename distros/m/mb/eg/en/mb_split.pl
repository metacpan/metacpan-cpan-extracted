#!/usr/bin/perl
######################################################################
# eg/en/mb_split.pl - splitting on character boundaries with mb::split
#
# What this shows:
#   mb::split('', EXPR) breaks a string into whole multibyte CHARACTERS,
#   and mb::split(PATTERN, EXPR) splits on an MBCS delimiter without ever
#   matching a byte that lies inside a multibyte character.
#
# How it differs from CORE:
#   CORE split(//, "\x82\xA0") returns two OCTETS ("\x82", "\xA0"); the
#   double-byte hiragana is torn apart. mb::split('', ...) returns it as
#   one character. mb::split is the runtime-managed counterpart of the
#   transpiled "split //" and is compatible back to Perl 5.005_03.
#
# The source is US-ASCII; multibyte data uses \xHH byte escapes.
#
#     perl eg/en/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Three hiragana in Shift_JIS: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4).
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) sees bytes: six of them here.
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) sees characters: three of them.
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# Splitting on an MBCS delimiter. The delimiter is the hiragana a
# (\x82\xA0); mb::split matches it as a whole character, not as the byte
# \x82 or \xA0 wherever those bytes happen to appear.
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# Character count via list context of mb::split (like a chars() helper).
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
