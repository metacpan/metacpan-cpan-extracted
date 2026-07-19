#!/usr/bin/perl
######################################################################
# eg/tw/mb_tr.pl - ç¨ mb::tr ä»¥å­åçºå®ä½è½å¯«
#
# æ­¤ä¾å±ç¤ºï¼
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) ä»¥æ´åå¤ä½åçµ
#   å­åçºå®ä½è½å¯«ãä¸å  /r æå°ç¬¬ä¸å¼æ¸å°±å°æ¹
#   åä¸¦åå³æ¸éï¼å  /r æåå³çµæä¸ä¸åå¼æ¸ã
#
# è CORE çåå¥ï¼
#   CORE tr/// éä½åçµéä½ï¼æå¯è½æå£ DAMEMOJI --
#   ç¬¬äºå byte æ¯ ASCII åå­åçéä½åçµå­åï¼
#   ä¾å¦ So(\x83\x5C)ï¼å¶å°¾ byte \x5C æ¯åæç·ãå° \x5C
#   å·è¡ CORE tr ææå°é£åå°¾ byteï¼mb::tr å° So è¦çº
#   ä¸åå­åèä¸åå®ã
#
# æ³¨ï¼mb::tr ä¸­çé£å­èç¯å(a-z)åå° US-ASCII ç«¯é»
# å±éï¼SEARCH ä¸­çå¤ä½åçµå­åå¿é éä¸ååº
# ï¼éæ­£æ¯è½è­¯å¨å±é MBCS tr/// çæ¹å¼ï¼ã
#
# æ³¨ï¼åå§ç¢¼è \xHH è³æç¶­æ US-ASCIIï¼æ¬æªçº
# UTF-8ï¼åè¨»è§£å¨å°åçºç¹é«ä¸­æï¼ã
#
#     perl eg/tw/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS å¨å½¢æ¸å­ï¼ 0(\x82\x4F) .. 9(\x82\x58)ã
# SEARCH éä¸ååºååå¨å½¢æ¸å­ï¼REPLACE æ¯ US-ASCII ç¯
# å "0-9"ï¼mb::tr æå±éç ASCII é£å­èç¯åï¼ã
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# å¨å½¢ "1" "3" "6" -> åå½¢ "136"ã
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI å®å¨æ§ãå­ä¸²çº A So(\x83\x5C) Bãéå®åæç·
# byte \x5C ç CORE tr ææå£å­åï¼åæ å° ASCII å­æ¯ç
# mb::tr åä¿æ So å®æ´ã
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr æå° So çå°¾ byte
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r ä¿®é£¾ç¬¦ï¼éç ´å£ï¼åå³è½å¯«å¾çå¯æ¬ã
$keep = "\x82\x50\x82\x51";                 # å¨å½¢ 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
