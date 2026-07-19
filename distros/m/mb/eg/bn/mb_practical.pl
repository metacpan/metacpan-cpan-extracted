#!/usr/bin/perl
######################################################################
# eg/bn/mb_practical.pl - অক্ষর না ভেঙে নির্দিষ্ট-কলামে ছাঁটাই
#
# কী দেখায় (ছোট বাস্তব কাজ):
#   Shift_JIS লাইনকে নির্দিষ্ট প্রদর্শন-প্রস্থে ছাঁটা — অর্ধ-প্রস্থ অক্ষর 1
#   কলাম, পূর্ণ-প্রস্থ অক্ষর 2 কলাম (সেই 1:2 অনুপাত) — দুই-বাইট অক্ষরকে
#   সীমানায় না ভেঙে।
#
# CORE থেকে পার্থক্য:
#   সরল CORE substr N-তম বাইটে কাটে ও অর্ধেক অক্ষর রেখে দিতে পারে। এখানে
#   mb::split('') পুরো অক্ষর হাঁটে, বাইট দৈর্ঘ্যে প্রস্থ মাপে ও বাজেট
#   ছাড়ানোর আগে থামে। mb::length() পুরো অক্ষর নিশ্চিত করে।
#
# দ্রষ্টব্য: সোর্স কোড ও \xHH ডেটা US-ASCII থাকে; এই ফাইলটি UTF-8 (শুধু মন্তব্য বাংলায়)।
#
#     perl eg/bn/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C, তারপর তিন পূর্ণ-প্রস্থ হিরাগানা a i u, এরপর দুই অর্ধ-প্রস্থ কাতাকানা।
#   ASCII A B C            : 1 column each
#   full-width a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 columns each
#   half-width ka(\xB6) ki(\xB7)                   : 1 column each
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # 7 প্রদর্শন কলামে ছাঁটা

# অক্ষর-সীমা নিরাপদ, প্রস্থ-সচেতন ছাঁটাই।
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 বাইট -> 1 কলাম, 2 বাইট -> 2 কলাম
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 কলাম) + a (2) + i (2) = 7 কলাম; u উপচে পড়বে বলে বাদ যায়,
# তাই শেষের দুই-বাইট অক্ষর পুরো থাকে।
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# দুই-বাইট-মাত্র ডেটায় তুলনা: নির্দিষ্ট বাইট সংখ্যায় কাটলে অক্ষরের ভিতরে
# পড়তে পারে। হিরাগানা a i u সব দুই-বাইট, তাই বিজোড় বাইট দৈর্ঘ্য মানে
# কাটা অক্ষর ভেঙেছে; mb::substr সবসময় অক্ষর সীমায় থামে (এখানে জোড়
# বাইট দৈর্ঘ্য)।
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + ঝুলন্ত লিড বাইট
$char_cut  = mb::substr($aiu, 0, 1);    # ঠিক a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
