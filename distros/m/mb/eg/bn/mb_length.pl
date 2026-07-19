#!/usr/bin/perl
######################################################################
# eg/bn/mb_length.pl - mb দিয়ে অক্ষর সংখ্যা বনাম বাইট সংখ্যা
#
# কী দেখায়:
#   CORE-এর length() বাইট গোনে; mb::length() নির্বাচিত স্ক্রিপ্ট
#   এনকোডিং অনুযায়ী পুরো মাল্টিবাইট অক্ষরকে 1 গোনে। mb::substr() ও
#   mb::index() অক্ষর এককেও কাজ করে, দুই-বাইট অক্ষর মাঝখানে কাটে না।
#
# CORE থেকে পার্থক্য:
#   length দুই-বাইট হিরাগানাকে 2 (বাইট) দেয়, কিন্তু mb::length দেয় 1
#   (একটি Shift_JIS হিরাগানা অক্ষর)।
#
# দ্রষ্টব্য: সোর্স কোড ও \xHH ডেটা US-ASCII থাকে; এই ফাইলটি UTF-8 (শুধু মন্তব্য বাংলায়)।
#
#     perl eg/bn/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS-এর তিন হিরাগানা, মোট 6 বাইট:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE length() বাইট গোনে; mb::length() অক্ষর গোনে।
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() অক্ষর এককে কাটে, দুই-বাইট অক্ষর অর্ধেক হয় না।
# প্রথম 2 অক্ষর ঠিক 4 বাইটের স্ট্রিং।
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() বাইট নয়, অক্ষর অবস্থান দেয়। তৃতীয় অক্ষর বাইট 4
# থেকে শুরু, কিন্তু অক্ষর সূচক 2-এ।
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
