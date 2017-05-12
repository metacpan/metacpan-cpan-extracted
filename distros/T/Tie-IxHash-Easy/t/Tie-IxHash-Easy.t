# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tie-IxHash-Easy.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Tie::IxHash::Easy') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

tie my(%hash), 'Tie::IxHash::Easy';

$hash{jeff}{age} = 22;
$hash{jeff}{lang} = 'Perl';
$hash{jeff}{brothers} = 3;
$hash{jeff}{sisters} = 4;

$hash{kristin}{age} = 22;
$hash{kristin}{lang} = 'Latin';
$hash{kristin}{brothers} = 1;
$hash{kristin}{sisters} = 0;

ok(join(" ", keys %hash) eq "jeff kristin");
ok(join(" ", keys %{ $hash{jeff} }) eq "age lang brothers sisters");
ok(join(" ", keys %{ $hash{kristin} }) eq "age lang brothers sisters");

