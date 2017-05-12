# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Time-LST.t'

#########################

use Test::More tests => 5;
BEGIN { use_ok('Time::LST') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


$lst_from_string = datetime2lst('1942:8:7T17:00:00', -3.21145, 'BST'); # 12:50:11

ok($lst_from_string eq '12:50:11', 'datetime2lst');


$lst_from_string = ymdhms2lst([1941, 11, 14, 17, 0, 0], -3.21145, 'BST'); 

ok($lst_from_string eq '19:20:30', 'ymdhms2lst');

eval {now2lst(147.333);};
ok(!$@, $@);

eval {time2lst(time(), '147:19:58.8')};
ok(!$@, $@);

