# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-VisualWidth-UTF8.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('Text::VisualWidth::UTF8') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# 文字コードはUTF-8

ok( Text::VisualWidth::UTF8::width("123abcあいうｱｲｳ") == 15, 'UTF8 width');
ok( Text::VisualWidth::UTF8::width("0") == 1, 'UTF width string zero');
ok( Text::VisualWidth::UTF8::width("") == 0, 'UTF width empty string');
ok( Text::VisualWidth::UTF8::trim("123ｱｲｳあいう",8) eq '123ｱｲｳあ', 'UTF8 trim');
ok( Text::VisualWidth::UTF8::trim("0",8) eq '0', 'UTF8 trim string zero');
ok( Text::VisualWidth::UTF8::trim("",8) eq '', 'UTF8 trim empty string');
