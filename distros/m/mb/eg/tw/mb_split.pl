#!/usr/bin/perl
######################################################################
# eg/tw/mb_split.pl - ç¨ mb::split å¨å­åéçåå²
#
# æ­¤ä¾å±ç¤ºï¼
#   mb::split('', EXPR) å°å­ä¸²æææ´åå¤ä½åçµå­åï¼
#   mb::split(PATTERN, EXPR) åä»¥ MBCS åéç¬¦åå²ï¼ä¸çµä¸æ
#   å¹éå°å¤ä½åçµå­åå§é¨ç byteã
#
# è CORE çåå¥ï¼
#   CORE split(//, "\x82\xA0") åå³å©åä½åçµ("\x82", "\xA0")ï¼
#   éä½åçµå¹³ååè¢«æè£ãmb::split('', ...) ååå³çºä¸
#   åå­åãmb::split æ¯è½è­¯å¾ "split //" çå·è¡æå°æ
#   ç©ï¼åä¸ç¸å®¹è³ Perl 5.005_03ã
#
# æ³¨ï¼åå§ç¢¼è \xHH è³æç¶­æ US-ASCIIï¼æ¬æªçº
# UTF-8ï¼åè¨»è§£å¨å°åçºç¹é«ä¸­æï¼ã
#
#     perl eg/tw/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS ä¸åå¹³ååï¼ a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)ã
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) çå° byteï¼éè£¡æå­åã
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) çå°å­åï¼ä¸åã
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# ä»¥ MBCS åéç¬¦åå²ãåéç¬¦æ¯å¹³åå a
# (\x82\xA0)ï¼mb::split å°å¶ç¶ä½æ´åå­åå¹éï¼èé byte \x82
# æ \xA0 å¨ä»»ä½ä½ç½®åºç¾æã
#     A a B a C  ->  æ¬ä½ï¼ A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# ä»¥ mb::split çæ¸å®èçµ¡è¨å­åæ¸ï¼é¡ä¼¼ chars() è¼å©ï¼ã
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
