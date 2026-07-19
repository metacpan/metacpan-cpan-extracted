#!/usr/bin/perl
######################################################################
# eg/my/mb_tr.pl - mb::tr ဖြင့် စာလုံး-ဧကက transliteration
#
# ပြသသည်မှာ:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) က multibyte စာလုံးအပြည့်ကို
#   ပြောင်းသည်။ /r မပါလျှင် ပထမ argument ကို နေရာတွင်ပြင်ပြီး count ပြန်ပေးသည်;
#   /r ပါလျှင် ရလဒ်ပြန်ပေးပြီး argument ကို မပြောင်းဘဲထားသည်။
#
# CORE နှင့် ကွာခြားချက်:
#   CORE tr/// က byte အလိုက်လုပ်သည်၊ ထို့ကြောင့် DAMEMOJI ပျက်နိုင်သည် —
#   ဒုတိယ byte က ASCII meta စာလုံး (ဥပမာ So \x83\x5C, နောက်ဆုံး \x5C backslash)။
#   mb::tr က So ကို စာလုံးတစ်လုံးအဖြစ်မြင်ပြီး မထိဘဲထားသည်။
#
# မှတ်ချက်: mb::tr တွင် hyphen range (a-z) သည် US-ASCII အစွန်းများအတွက်သာ
# ချဲ့သည်; SEARCH ရှိ multibyte စာလုံးများကို တစ်လုံးချင်း စာရင်းပြုရသည်။
#
# မှတ်ချက်: source code နှင့် \xHH data ကို US-ASCII အဖြစ်ထားသည်; ဤ file သည် UTF-8 ဖြစ်သည် (comment သာ ဗမာလို)။
#
#     perl eg/my/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Full-width digits in Shift_JIS: 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH က full-width ဂဏန်း 10 လုံးကို စာလုံးအပြည့်အဖြစ်စာရင်းပြုသည်;
# REPLACE မှာ US-ASCII range "0-9" (mb::tr ချဲ့သော ASCII hyphen range)။
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# full-width "1" "3" "6" -> half-width "136"။
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI လုံခြုံမှု။ string မှာ A So(\x83\x5C) B။ backslash byte \x5C ကို
# ပစ်မှတ်ထားသော CORE tr က စာလုံးပျက်စေသည်; mb::tr က ASCII စာလုံးသာ map လုပ်၍
# So ကို မထိဘဲထားသည်။
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr က So ၏ နောက်ဆုံး byte ကိုထိသည်
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r modifier: ဖျက်ဆီးမှုမရှိ၊ ပြောင်းပြီးမိတ္တူပြန်ပေးသည်။
$keep = "\x82\x50\x82\x51";                 # full-width 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
