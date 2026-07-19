#!/usr/bin/perl
######################################################################
# eg/ne/mb_tr.pl - mb::tr द्वारा अक्षर-एकाइ ट्रान्सलिटरेसन
#
# के देखाउँछ:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) ले पूरा मल्टिबाइट अक्षर
#   अनुवाद गर्छ। /r बिना पहिलो तर्क ठाउँमै बदल्छ र गणना फर्काउँछ; /r सँग
#   नतिजा फर्काउँछ र तर्क अछुतो राख्छ।
#
# CORE भन्दा फरक:
#   CORE tr/// बाइट-बाइट चल्छ, त्यसैले DAMEMOJI बिगार्न सक्छ — जसको दोस्रो
#   बाइट ASCII मेटा-वर्ण हो (जस्तै So \x83\x5C, पुछारको \x5C ब्याकस्ल्यास)।
#   mb::tr ले So लाई एक अक्षरका रूपमा देख्छ र नछुने।
#
# नोट: mb::tr मा हाइफन दायरा (a-z) US-ASCII छेउका लागि मात्र विस्तार हुन्छ;
# SEARCH का मल्टिबाइट अक्षर एक-एक गरी सूचीबद्ध गर्नुपर्छ।
#
# द्रष्टव्य: स्रोत कोड र \xHH डेटा US-ASCII मै रहन्छ; यो फाइल UTF-8 हो (टिप्पणी मात्र नेपालीमा)।
#
#     perl eg/ne/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Full-width digits in Shift_JIS: 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH ले दसै पूरा-चौडाइ अङ्कलाई पूरा अक्षरका रूपमा राख्छ; REPLACE
# US-ASCII दायरा "0-9" हो (ASCII हाइफन दायरा, जसलाई mb::tr विस्तार गर्छ)।
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# पूरा-चौडाइ "1" "3" "6" -> आधा-चौडाइ "136"।
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI सुरक्षा। स्ट्रिङ A So(\x83\x5C) B हो। ब्याकस्ल्यास बाइट \x5C
# लक्षित CORE tr ले अक्षर बिगार्छ; mb::tr ले ASCII अक्षर मात्र म्याप गरी
# So अछुतो राख्छ।
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr ले So को पुछारको बाइटमा हान्छ
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r मोडिफायर: विनाशकारी होइन, अनुवादित प्रतिलिपि फर्काउँछ।
$keep = "\x82\x50\x82\x51";                 # पूरा-चौडाइ 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
