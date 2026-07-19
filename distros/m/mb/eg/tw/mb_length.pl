#!/usr/bin/perl
######################################################################
# eg/tw/mb_length.pl - ç¨ mb æ¯è¼å­åæ¸èä½åçµæ¸
#
# æ­¤ä¾å±ç¤ºï¼
#   CORE ç length() è¨ç®ä½åçµï¼byteï¼ï¼mb::length() ä¾æé¸
#   è³æ¬ç·¨ç¢¼ï¼å°æ´åå¤ä½åçµå­åç®ä½ 1ãmb::substr() è
#   mb::index() ä¹ä»¥å­åçºå®ä½ï¼æéä½åçµå­åä¸æè¢«ææ·ã
#
# è CORE çåå¥ï¼
#   length("\x82\xA0") çº 2ï¼byteï¼ï¼ä½ mb::length("\x82\xA0") çº 1
#   ï¼ä¸å Shift_JIS å¹³ååï¼ã
#
# æ³¨ï¼åå§ç¢¼è \xHH è³æç¶­æ US-ASCIIï¼æ¬æªçº
# UTF-8ï¼åè¨»è§£å¨å°åçºç¹é«ä¸­æï¼ã
#
#     perl eg/tw/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS ä¸åå¹³ååï¼å± 6 å byteï¼
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length() è¨ byteï¼mb::length() è¨å­åã
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() ä»¥å­åçºå®ä½åå²ï¼æéä½åçµå­åä¸æå
# æä¸åãåå©åå­åæ°å¥½æ¯ 4 å byte çå­ä¸²ã
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() åå ±çä½ç½®æ¯å­åèé byteãç¬¬ä¸å
# å­åå¨ byte 4 éå§ï¼ä½å­åç´¢å¼çº 2ã
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
