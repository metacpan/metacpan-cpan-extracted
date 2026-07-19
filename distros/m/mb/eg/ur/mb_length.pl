#!/usr/bin/perl
######################################################################
# eg/ur/mb_length.pl - mb ke sath characters vs bytes ki ginti
#
# Yeh misal kya dikhati hai:
#   CORE ka length() OCTET (byte) ginta hai; mb::length() muntakhab kiye
#   gaye script encoding ke mutabiq poore multibyte CHARACTER ko 1 ginta
#   hai. mb::substr() aur mb::index() bhi character ki unit mein kaam
#   karte hain, is liye do-byte character kabhi beech se nahin katta.
#
# CORE se kya farq hai:
#   length("\x82\xA0") 2 (byte) hai, lekin mb::length("\x82\xA0") 1 hai
#   (ek Shift_JIS hiragana).
#
# Note: source code aur \xHH data US-ASCII hi rehte hain; yeh file bhi US-ASCII hai (comments Roman Urdu mein).
#
#     perl eg/ur/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS ke teen hiragana, kul chhe byte:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length() byte ginta hai; mb::length() character ginta hai.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() character ki unit mein kaatta hai, is liye do-byte
# character aadha nahin hota. Pehle 2 character theek 4 byte ki string
# bante hain.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() maqam ko byte mein nahin, character mein batata hai. Teesra
# character byte 4 se shuru hota hai, lekin character index 2 par.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
