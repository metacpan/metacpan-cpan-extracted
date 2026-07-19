#!/usr/bin/perl
######################################################################
# eg/bn/mb_tr.pl - mb::tr দিয়ে অক্ষর-একক ট্রান্সলিটারেশন
#
# কী দেখায়:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) পুরো মাল্টিবাইট অক্ষর
#   অনুবাদ করে। /r ছাড়া প্রথম আর্গুমেন্ট জায়গায় বদলে গণনা ফেরত দেয়; /r
#   দিয়ে ফলাফল ফেরত দেয় ও আর্গুমেন্ট অপরিবর্তিত রাখে।
#
# CORE থেকে পার্থক্য:
#   CORE tr/// বাইট-বাইট কাজ করে, তাই DAMEMOJI নষ্ট করতে পারে — যার দ্বিতীয়
#   বাইট ASCII মেটা-অক্ষর (যেমন So \x83\x5C, শেষ \x5C ব্যাকস্ল্যাশ)।
#   mb::tr So-কে এক অক্ষর হিসেবে দেখে ও অক্ষত রাখে।
#
# নোট: mb::tr-এ হাইফেন পরিসর (a-z) কেবল US-ASCII প্রান্তের জন্য বিস্তৃত হয়;
# SEARCH-এর মাল্টিবাইট অক্ষর এক-এক করে তালিকাভুক্ত করতে হয়।
#
# দ্রষ্টব্য: সোর্স কোড ও \xHH ডেটা US-ASCII থাকে; এই ফাইলটি UTF-8 (শুধু মন্তব্য বাংলায়)।
#
#     perl eg/bn/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Full-width digits in Shift_JIS: 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH দশটি পূর্ণ-প্রস্থ অঙ্ককে পুরো অক্ষর হিসেবে রাখে; REPLACE হলো
# US-ASCII পরিসর "0-9" (ASCII হাইফেন পরিসর, যা mb::tr বিস্তৃত করে)।
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# পূর্ণ-প্রস্থ "1" "3" "6" -> অর্ধ-প্রস্থ "136"।
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI নিরাপত্তা। স্ট্রিং A So(\x83\x5C) B। ব্যাকস্ল্যাশ বাইট \x5C
# লক্ষ্য করা CORE tr অক্ষর নষ্ট করে; mb::tr কেবল ASCII অক্ষর ম্যাপ করে
# So অক্ষত রাখে।
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr So-এর শেষ বাইটে আঘাত করে
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r মডিফায়ার: ধ্বংসাত্মক নয়, অনূদিত অনুলিপি ফেরত দেয়।
$keep = "\x82\x50\x82\x51";                 # পূর্ণ-প্রস্থ 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
