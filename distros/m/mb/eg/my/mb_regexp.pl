#!/usr/bin/perl
######################################################################
# eg/my/mb_regexp.pl - mb::qr ဖြင့် multibyte-သိ matching
#
# ပြသသည်မှာ:
#   mb::qr(PATTERN) က ".", character class နှင့် capture တို့ကို ရွေးထားသော
#   script encoding အရ စာလုံးအပြည့်ဖြင့် အလုပ်လုပ်သည့် regexp ကို compile လုပ်သည်။
#
# CORE နှင့် ကွာခြားချက်:
#   CORE "." က byte တစ်လုံးကိုက်သည်၊ ထို့ကြောင့် hiragana သုံးလုံးတွင်
#   /(.)/g က အပိုင်း 6; mb::qr ဖြင့် 3 (စာလုံးတစ်လုံးလျှင်တစ်ခု)။ class
#   range နှင့် capture က စာလုံးအပြည့် ပြန်ပေးသည်။
#
# မှတ်ချက်: source code နှင့် \xHH data ကို US-ASCII အဖြစ်ထားသည်; ဤ file သည် UTF-8 ဖြစ်သည် (comment သာ ဗမာလို)။
#
#     perl eg/my/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS hiragana သုံးလုံး: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)။
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE "." က byte တစ်လုံး -- byte 6 အတွက် အပိုင်း 6။
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") က "." ကို စာလုံးအပြည့်တစ်လုံးဖြစ်စေသည် -- အပိုင်း 3။ တစ်ကြိမ်
# compile လုပ်ပြီး compile လုပ်ထားသော pattern ကို match ထဲထည့်ပါ။
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# hiragana block a..n (\x82\xA0-\x82\xF1) ပေါ်တွင် class range။ range က စာလုံးအပြည့်
# နှိုင်းယှဉ်သည်၊ ထို့ကြောင့် u အတွင်း၊ ASCII "A" မဟုတ်။
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# capture က multibyte စာလုံးအပြည့် (ဤတွင် byte နှစ်လုံး) ပြန်ပေးသည်၊ စာလုံး
# တစ်ဝက် ဘယ်တော့မှမဟုတ်။
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# ရောနှောသော string ထဲ hiragana တိုင်းကို စာလုံးအလိုက်ရှာပါ။
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
