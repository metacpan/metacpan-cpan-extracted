#!/usr/bin/perl
######################################################################
# eg/hi/mb_length.pl - mb से अक्षर बनाम बाइट की गिनती
#
# यह क्या दिखाता है:
#   CORE का length() OCTET (बाइट) गिनता है; mb::length() चुने गए स्क्रिप्ट
#   एन्कोडिंग के अनुसार पूरे multibyte अक्षर को 1 गिनता है। mb::substr()
#   और mb::index() भी अक्षर की इकाई में काम करते हैं, इसलिए दो-बाइट अक्षर
#   कभी बीच से नहीं कटता।
#
# CORE से अंतर:
#   length("\x82\xA0") 2 (बाइट) है, पर mb::length("\x82\xA0") 1 है
#   (एक Shift_JIS हिरागाना)।
#
# ध्यान दें: सोर्स कोड और \xHH डेटा US-ASCII ही रहते हैं; यह फाइल UTF-8 है (केवल टिप्पणियाँ हिन्दी में)।
#
#     perl eg/hi/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS के तीन हिरागाना, कुल छह बाइट:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length() बाइट गिनता है; mb::length() अक्षर गिनता है।
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() अक्षर की इकाई में काटता है, इसलिए दो-बाइट अक्षर आधा नहीं
# होता। पहले 2 अक्षर ठीक 4 बाइट की स्ट्रिंग बनते हैं।
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() स्थिति बाइट में नहीं, अक्षर में बताता है। तीसरा अक्षर बाइट
# 4 से शुरू होता है, पर अक्षर सूचकांक 2 पर।
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
