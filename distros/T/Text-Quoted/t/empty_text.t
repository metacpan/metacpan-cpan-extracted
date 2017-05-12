# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Text::Quoted') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$a = '';
use Data::Dumper;

$empty_deeply = [
          {
            'text' => undef,
            'quoter' => undef,
            'raw' => undef
          }
        ];

is_deeply(extract($a),$empty_deeply) or diag Dumper(extract($a));
$b = undef;
is_deeply(extract($b),$empty_deeply) or diag Dumper(extract($b));

