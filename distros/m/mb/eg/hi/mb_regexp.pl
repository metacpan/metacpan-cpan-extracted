#!/usr/bin/perl
######################################################################
# eg/hi/mb_regexp.pl - mb::qr से multibyte-सजग मिलान
#
# यह क्या दिखाता है:
#   mb::qr(PATTERN) एक regular expression संकलित करता है जिसका ".", अक्षर
#   वर्ग (character class) और capture चुने गए स्क्रिप्ट एन्कोडिंग के अनुसार
#   पूरे multibyte अक्षरों में काम करते हैं।
#
# CORE से अंतर:
#   CORE "." एक OCTET से मेल खाता है, इसलिए तीन Shift_JIS हिरागाना पर
#   /(.)/g छह टुकड़े देता है। वही पैटर्न mb::qr से तीन देता है, प्रति अक्षर
#   एक। [a-hiragana ...] जैसी वर्ग-सीमा पूरे अक्षरों की तुलना करती है, और
#   capture एक पूरा अक्षर लौटाता है।
#
# स्रोत US-ASCII है; multibyte डेटा \xHH बाइट एस्केप का उपयोग करता है। यह
# runtime इंटरफ़ेस है (कोई source filter नहीं), इसलिए यह 5.005_03 से आगे
# हर perl पर चलता है।
#
#     perl eg/hi/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS में तीन हिरागाना: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)।
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE "." एक octet है -- छह बाइट के लिए छह टुकड़े।
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") "." को एक पूरा अक्षर बनाता है -- तीन टुकड़े। एक बार संकलित
# करें, फिर संकलित पैटर्न को मिलान में प्रक्षेपित करें।
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# हिरागाना खंड a..n (\x82\xA0-\x82\xF1) पर अक्षर-वर्ग सीमा। सीमा पूरे
# अक्षरों की तुलना करती है, इसलिए u अंदर है और ASCII "A" नहीं।
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# capture एक पूरा multibyte अक्षर लौटाता है (यहाँ दो बाइट), कभी उसका आधा
# नहीं।
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# मिश्रित स्ट्रिंग में हर हिरागाना को अक्षर की इकाई में खोजें।
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
