# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 06_XML_XML-XMetaL-Utilities.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;

BEGIN {
    use lib ('lib', '../lib');
    use_ok('XML::XMetaL::Utilities::Abstract');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

package TestClass::Abstract;

use base 'XML::XMetaL::Utilities::Abstract';

use constant TRUE  => 1;
use constant FALSE => 0;

sub new {bless {}, $_[0];};

sub test_method {$_[0]->abstract}

package TestClass::Concrete;

use base 'TestClass::Abstract';

sub test_method {1}


package main;

my $test;
is(eval{ref($test = TestClass::Abstract->new())},
   "TestClass::Abstract",
   "TestClass::Abstract constructor test");

eval{$test->test_method()};
ok($@,"Abstract keyword test 1");
#diag($@) if $@;

is(eval{ref($test = TestClass::Concrete->new())},
   "TestClass::Concrete",
   "TestClass::Concrete constructor test");

ok(eval{$test->test_method()},"Abstract keyword test 2");
