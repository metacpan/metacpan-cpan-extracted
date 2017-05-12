# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Test-Mock-Simple.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use lib 't/';

use Test::More tests => 6;

BEGIN {
  use_ok('Test::Mock::Simple');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

eval { my $mock = Test::Mock::Simple->new(); };
like($@, qr/^No module name provided/, 'new with no args');

my $mock = Test::Mock::Simple->new(module => 'TestModule');
my $mock2 = $mock->new(module => 'TestModule');

eval { $mock->add(); };
like($@, qr/^No method name provided/, 'add with no args');

eval { $mock->add( 'sub' ); };
like($@, qr/^No sub ref provided/, 'add with no sub ref provided');

eval { require Mock::StrictModule; };
like($@, qr/^Module \(StrictModule\) does not have a method named 'add'/,
  'create method that does not exist');

ok($mock->add('one' => sub { return 'This is a test'; }), 'making sure add still works');
