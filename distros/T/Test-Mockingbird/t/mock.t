use strict;
use warnings;

use Test::Most tests => 7;

use Test::Mockingbird;

# MyClass has no methods of its own at this point.
# Use defined(&...) rather than ->can() -- after any mock/unmock cycle
# the GV is auto-vivified and ->can() may return the undef-stub.  See
# LIMITATIONS in Test::Mockingbird for the full explanation.
ok !defined(&MyClass::greet), 'greet not defined before mock';

# Install a mock for a method that did not previously exist
Test::Mockingbird::mock('MyClass', 'greet', sub { 'Hello, Mock!' });
ok defined(&MyClass::greet), 'greet defined after mock';
is MyClass::greet(), 'Hello, Mock!', 'mock returns expected value';

Test::Mockingbird::unmock('MyClass', 'greet');

# After unmocking, defined(&...) must return false and calls must die.
ok !defined(&MyClass::greet), 'greet not defined after unmock';
dies_ok { MyClass::greet() } 'greet() dies after unmock';
like $@, qr/Undefined subroutine &MyClass::greet/, 'correct error message';

# Verify restore_all also properly removes the mock
Test::Mockingbird::mock('MyClass', 'greet', sub { 'again' });
Test::Mockingbird::restore_all();
ok !defined(&MyClass::greet), 'greet not defined after restore_all';

package MyClass;
1;
