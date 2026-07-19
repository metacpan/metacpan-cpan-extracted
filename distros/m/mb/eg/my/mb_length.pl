#!/usr/bin/perl
######################################################################
# eg/my/mb_length.pl - mb ဖြင့် စာလုံးအရေအတွက်နှင့် byte အရေအတွက်
#
# ပြသသည်မှာ:
#   CORE length() က byte ရေတွက်သည်; mb::length() က ရွေးထားသော
#   script encoding အရ multibyte စာလုံးတစ်လုံးကို 1 အဖြစ်ရေတွက်သည်။
#   mb::substr() နှင့် mb::index() တို့လည်း စာလုံးဖြင့် အလုပ်လုပ်သည်။
#
# CORE နှင့် ကွာခြားချက်:
#   double-byte hiragana ကို length က 2 (byte); mb::length က 1
#   (Shift_JIS hiragana စာလုံးတစ်လုံး)။
#
# မှတ်ချက်: source code နှင့် \xHH data ကို US-ASCII အဖြစ်ထားသည်; ဤ file သည် UTF-8 ဖြစ်သည် (comment သာ ဗမာလို)။
#
#     perl eg/my/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS hiragana သုံးလုံး၊ စုစုပေါင်း byte 6:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length() က byte ရေတွက်သည်; mb::length() က စာလုံးရေတွက်သည်။
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() က စာလုံးအလိုက်ဖြတ်သည်၊ double-byte စာလုံး တစ်ဝက်မပြတ်ပါ။
# ပထမ စာလုံး 2 သည် byte 4 အတိအကျ string ဖြစ်သည်။
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() က byte မဟုတ်၊ စာလုံးအနေအထားပြန်ပေးသည်။ တတိယစာလုံးသည်
# byte 4 မှစသည်၊ သို့သော် စာလုံး index 2 တွင်။
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
