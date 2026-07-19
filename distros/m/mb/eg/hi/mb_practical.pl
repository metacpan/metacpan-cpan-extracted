#!/usr/bin/perl
######################################################################
# eg/hi/mb_practical.pl - अक्षर तोड़े बिना निश्चित-स्तंभ छँटाई
#
# यह क्या दिखाता है (एक छोटा वास्तविक कार्य):
#   fixed-column आउटपुट के लिए किसी Shift_JIS पंक्ति को एक निश्चित
#   DISPLAY WIDTH तक छाँटें, अर्ध-चौड़ाई अक्षर को 1 स्तंभ और पूर्ण-चौड़ाई
#   अक्षर को 2 स्तंभ गिनते हुए (क्लासिक 1:2 अनुपात), और किसी दो-बाइट अक्षर
#   को सीमा पर कभी न तोड़ें।
#
# CORE से अंतर:
#   भोला CORE substr(EXPR, 0, N) N-वें OCTET पर काटता है और एक लटकता हुआ
#   lead byte छोड़ सकता है -- अक्षर का टूटा आधा भाग। यहाँ हम mb::split('')
#   से पूरे अक्षरों पर चलते हैं, प्रत्येक अक्षर की चौड़ाई उसकी बाइट लंबाई
#   से मापते हैं (1 बाइट -> 1 स्तंभ, 2 बाइट -> 2 स्तंभ), और बजट पार होने से
#   पहले रुक जाते हैं। mb::length() पुष्टि करता है कि परिणाम अक्षरों की
#   पूर्ण संख्या है।
#
# स्रोत US-ASCII है; multibyte डेटा \xHH बाइट एस्केप का उपयोग करता है।
# केवल runtime इंटरफ़ेस, इसलिए यह 5.005_03 से आगे हर perl पर चलता है।
#
#     perl eg/hi/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C फिर तीन पूर्ण-चौड़ाई हिरागाना a i u फिर दो अर्ध-चौड़ाई कटाकाना।
#   ASCII A B C            : प्रत्येक 1 स्तंभ
#   पूर्ण-चौड़ाई a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : प्रत्येक 2 स्तंभ
#   अर्ध-चौड़ाई ka(\xB6) ki(\xB7)                    : प्रत्येक 1 स्तंभ
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # 7 प्रदर्शन स्तंभों तक छाँटें

# अक्षर-सीमा-सुरक्षित, चौड़ाई-सजग छँटाई।
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 बाइट -> 1 स्तंभ, 2 बाइट -> 2 स्तंभ
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 स्तंभ) + a (2) + i (2) = 7 स्तंभ; u अतिप्रवाहित होकर हटा दिया
# जाता है, इसलिए अंतिम दो-बाइट अक्षर पूरा रहता है।
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# केवल-दो-बाइट डेटा पर विरोधाभास: निश्चित OCTET संख्या पर काटना किसी अक्षर
# के अंदर उतर सकता है। हिरागाना a i u सभी दो-बाइट हैं, इसलिए विषम बाइट
# लंबाई का अर्थ है कि कट ने अक्षर तोड़ा; mb::substr हमेशा अक्षर सीमा पर
# रुकता है (यहाँ सम बाइट लंबाई)।
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + लटकता हुआ lead byte
$char_cut  = mb::substr($aiu, 0, 1);    # ठीक a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
