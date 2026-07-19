#!/usr/bin/perl
######################################################################
# eg/hi/mb_split.pl - mb::split से अक्षर सीमा पर विभाजन
#
# यह क्या दिखाता है:
#   mb::split('', EXPR) स्ट्रिंग को पूरे multibyte अक्षरों में तोड़ता है,
#   और mb::split(PATTERN, EXPR) किसी MBCS डिलिमिटर पर विभाजन करता है, कभी
#   भी multibyte अक्षर के अंदर पड़े किसी बाइट से मेल खाए बिना।
#
# CORE से अंतर:
#   CORE split(//, "\x82\xA0") दो OCTET ("\x82", "\xA0") लौटाता है; दो-बाइट
#   हिरागाना फट जाता है। mb::split('', ...) उसे एक अक्षर के रूप में लौटाता
#   है। mb::split ट्रांसपाइल किए गए "split //" का runtime-प्रबंधित समकक्ष
#   है और Perl 5.005_03 तक पीछे संगत है।
#
# स्रोत US-ASCII है; multibyte डेटा \xHH बाइट एस्केप का उपयोग करता है।
#
#     perl eg/hi/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS में तीन हिरागाना: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)।
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) बाइट देखता है: यहाँ छह।
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) अक्षर देखता है: यहाँ तीन।
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# MBCS डिलिमिटर पर विभाजन। डिलिमिटर हिरागाना a (\x82\xA0) है; mb::split
# उसे पूरे अक्षर के रूप में मेल करता है, बाइट \x82 या \xA0 के रूप में नहीं,
# चाहे वे बाइट कहीं भी आएँ।
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# mb::split के list संदर्भ द्वारा अक्षर गणना (एक chars() हेल्पर की तरह)।
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
