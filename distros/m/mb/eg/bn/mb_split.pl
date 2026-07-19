#!/usr/bin/perl
######################################################################
# eg/bn/mb_split.pl - mb::split দিয়ে অক্ষর-সীমায় বিভাজন
#
# কী দেখায়:
#   mb::split('', EXPR) স্ট্রিংকে পুরো মাল্টিবাইট অক্ষরে ভাঙে, এবং
#   mb::split(PATTERN, EXPR) MBCS বিভাজকে ভাগ করে — অক্ষরের ভিতরের
#   বাইটের সাথে কখনো মেলে না।
#
# CORE থেকে পার্থক্য:
#   CORE split(//) দুই-বাইট হিরাগানাকে দুই বাইটে ছিঁড়ে ফেলে; mb::split
#   একে এক অক্ষর রাখে। Perl 5.005_03 পর্যন্ত সঙ্গতিপূর্ণ।
#
# দ্রষ্টব্য: সোর্স কোড ও \xHH ডেটা US-ASCII থাকে; এই ফাইলটি UTF-8 (শুধু মন্তব্য বাংলায়)।
#
#     perl eg/bn/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS-এর তিন হিরাগানা: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)।
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) বাইট দেখে: এখানে ছয়টি।
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) অক্ষর দেখে: তিনটি।
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# MBCS বিভাজকে ভাগ করা। বিভাজক হিরাগানা a (\x82\xA0); mb::split একে
# পুরো অক্ষর হিসেবে ম্যাচ করে, যেখানে-সেখানে থাকা বাইট \x82 বা \xA0 নয়।
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# mb::split-এর লিস্ট কনটেক্সট দিয়ে অক্ষর গণনা (chars()-এর মতো)।
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
