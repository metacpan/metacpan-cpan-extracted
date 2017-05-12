# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-AI-CRM114-libcrm114.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 28;
BEGIN { use_ok('Text::AI::CRM114') };
use lib "t";
BEGIN { use_ok('SampleText') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# check some constants
is(Text::AI::CRM114::libcrm114::MARKOVIAN,  1<<21);
is(Text::AI::CRM114::libcrm114::OSB,        1<<22);
is(Text::AI::CRM114::libcrm114::WINNOW,     1<<24);
is(Text::AI::CRM114::libcrm114::OSBF,       1<<28);
is(Text::AI::CRM114::libcrm114::HYPERSPACE, 1<<29);
is(Text::AI::CRM114::libcrm114::SVM,        1<<35);

# enum
ok(defined(Text::AI::CRM114::libcrm114::OK));
ok(defined(Text::AI::CRM114::libcrm114::UNK));
ok(defined(Text::AI::CRM114::libcrm114::NOMEM));
# one should not rely on enum value, but some code might still rely on it
is(Text::AI::CRM114::libcrm114::OK, 0);
is(0, Text::AI::CRM114::libcrm114::OK);

# test low-level interface, especially memory mallloc/realloc/free
my $cb = Text::AI::CRM114::libcrm114::new_cb();
ok(defined($cb));
ok($cb);

Text::AI::CRM114::libcrm114::cb_setflags($cb, Text::AI::CRM114::libcrm114::HYPERSPACE);
Text::AI::CRM114::libcrm114::cb_setclassdefaults($cb);
Text::AI::CRM114::libcrm114::cb_setdatablock_size($cb, 25200);
Text::AI::CRM114::libcrm114::cb_setblockdefaults($cb);
Text::AI::CRM114::libcrm114::cb_setclassname($cb, 0, 'A');
Text::AI::CRM114::libcrm114::cb_setclassname($cb, 1, 'B');
my $db = Text::AI::CRM114::libcrm114::new_db($cb);
ok($db);

my $uid_string = "Text::AI::CRM114";
is(Text::AI::CRM114::libcrm114::db_getuserid_text($db), "");
Text::AI::CRM114::libcrm114::db_setuserid_text($db, $uid_string);
is(Text::AI::CRM114::libcrm114::db_getuserid_text($db), $uid_string);

my ($size, $addr) = Text::AI::CRM114::libcrm114::db_getinfo($db);
my $original_addr = $addr;
# not a nice test, but on i386 this is 25200 and on amd64 it becomes 29304
ok($size >= 25200 && $size <= 32000);

my ($err, $class, $prob, $pR, $unk);
$err = Text::AI::CRM114::libcrm114::learn_text($db, 0, SampleText::Alice(), length(SampleText::Alice()));
is($err, Text::AI::CRM114::libcrm114::OK);
$err = Text::AI::CRM114::libcrm114::learn_text($db, 1, SampleText::Macbeth(), length(SampleText::Macbeth()));
is($err, Text::AI::CRM114::libcrm114::OK);
# check successful resize
($size, $addr) = Text::AI::CRM114::libcrm114::db_getinfo($db);
ok($original_addr != $addr);
ok($size > 25200);

($err, $class, $prob, $pR, $unk) = Text::AI::CRM114::libcrm114::classify($db, SampleText::Hound_frag(), length(SampleText::Hound_frag()));
is($err, Text::AI::CRM114::libcrm114::OK);
is($class, "B");
is(sprintf("%.3f", $prob), "0.458");
is(sprintf("%.6f", $pR), "-0.073242");
is($unk, 180);

