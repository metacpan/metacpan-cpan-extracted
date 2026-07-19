#!/usr/bin/perl
######################################################################
# eg/hi/mb_tr.pl - mb::tr से अक्षर-इकाई लिप्यंतरण
#
# यह क्या दिखाता है:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) पूरे multibyte अक्षरों का
#   लिप्यंतरण करता है। /r के बिना यह अपने पहले तर्क को यथास्थान संपादित
#   करता है और गिनती लौटाता है; /r के साथ यह परिणाम लौटाता है और तर्क को
#   अछूता छोड़ देता है।
#
# CORE से अंतर:
#   CORE tr/// octet-दर-octet काम करता है, इसलिए यह किसी DAMEMOJI को
#   दूषित कर सकता है -- ऐसा दो-बाइट अक्षर जिसका दूसरा बाइट एक ASCII
#   मेटावर्ण है, जैसे So(\x83\x5C), जिसका अंतिम बाइट \x5C बैकस्लैश है।
#   \x5C पर CORE tr उस अंतिम बाइट पर लगेगा; mb::tr So को एक अक्षर के रूप
#   में देखता है और उसे छोड़ देता है।
#
# ध्यान दें: mb::tr में हाइफ़न सीमा (a-z) केवल US-ASCII सिरों के लिए
# विस्तारित होती है; SEARCH में multibyte अक्षरों को एक-एक करके सूचीबद्ध
# करना होता है (ठीक वैसे ही जैसे transpiler किसी MBCS tr/// को विस्तारित
# करता है)।
#
# स्रोत US-ASCII है; multibyte डेटा \xHH बाइट एस्केप का उपयोग करता है।
#
#     perl eg/hi/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS में पूर्ण-चौड़ाई अंक: 0(\x82\x4F) .. 9(\x82\x58)। SEARCH सभी दस
# पूर्ण-चौड़ाई अंकों को पूरे अक्षरों के रूप में सूचीबद्ध करता है; REPLACE
# US-ASCII सीमा "0-9" है (एक ASCII हाइफ़न सीमा, जिसे mb::tr विस्तारित करता है)।
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# पूर्ण-चौड़ाई "1" "3" "6" -> अर्ध-चौड़ाई "136"।
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI सुरक्षा। स्ट्रिंग A So(\x83\x5C) B है। बैकस्लैश बाइट \x5C को
# लक्ष्य करने वाला CORE tr अक्षर को दूषित करता है; mb::tr, जो केवल ASCII
# अक्षरों को मैप करता है, So को अछूता छोड़ देता है।
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr So के अंतिम बाइट पर लगता है
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r संशोधक: गैर-विनाशकारी, लिप्यंतरित प्रति लौटाता है।
$keep = "\x82\x50\x82\x51";                 # पूर्ण-चौड़ाई 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
