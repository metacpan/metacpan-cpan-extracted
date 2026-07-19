#!/usr/bin/perl
######################################################################
# eg/ko/mb_length.pl - mbë¡ ë¬¸ì ìì ë°ì´í¸ ì ë¹êµ
#
# ë¬´ìì ë³´ì¬ì£¼ë:
#   CORE length()ë ì¥í(ë°ì´í¸)ë¥¼ ì¸ê³ , mb::length()ë ì íë
#   ì¤í¬ë¦½í¸ ì¸ì½ë© ê¸°ì¤ì¼ë¡ ë©í°ë°ì´í¸ ë¬¸ì íëë¥¼ 1ë¡ ì¼ë¤.
#   mb::substr()ì mb::index()ë ë¬¸ì ë¨ìë¡ ëìíë¯ë¡ ë ë°ì´í¸
#   ë¬¸ìê° ì¤ê°ìì ìë¦¬ì§ ìëë¤.
#
# COREìì ì°¨ì´:
#   length("\x82\xA0")ë 2(ë°ì´í¸)ì§ë§ mb::length("\x82\xA0")ë 1
#   (Shift_JIS íë¼ê°ë íë).
#
# Ì¸ê³ : ìì¤ì \xHH ë°ì´í°ë US-ASCII ê·¸ëë¡ì´ê³ , ì´ íì¼ì
# UTF-8ìëë¤(ì£¼ìë§ íêµ­ì´ë¡ íì§í).
#
#     perl eg/ko/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS íë¼ê°ë 3ê°, ëª¨ë 6ë°ì´í¸:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length()ë ë°ì´í¸ë¥¼, mb::length()ë ë¬¸ìë¥¼ ì¼ë¤.
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr()ë ë¬¸ì ë¨ìë¡ ìë¼ë´ë¯ë¡ ë ë°ì´í¸ ë¬¸ìê° ë°ì¼ë¡
# ìë¦¬ì§ ìëë¤. ì²ì ë ë¬¸ìë ì íí 4ë°ì´í¸ ë¬¸ìì´ì´ë¤.
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index()ë ìì¹ë¥¼ ë°ì´í¸ê° ìë ë¬¸ìë¡ ë³´ê³ íë¤. ì¸ ë²ì§¸
# ë¬¸ìë ë°ì´í¸ 4ìì ììíì§ë§ ë¬¸ì ì¸ë±ì¤ë¡ë 2ì´ë¤.
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
