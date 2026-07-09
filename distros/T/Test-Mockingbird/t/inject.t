use strict;
use warnings;

use Test::Most tests => 3;

use Test::Mockingbird;

is MyClass::db_connect(), 'Original code', 'original behaviour confirmed';

# inject() stores the coderef itself; caller must invoke it
my $mock_db = sub { 'Mock DB Connection' };
Test::Mockingbird::inject('MyClass', 'db_connect', $mock_db);
is MyClass::db_connect()->(), 'Mock DB Connection', 'injected coderef invokable';

Test::Mockingbird::restore_all();
is MyClass::db_connect(), 'Original code', 'original restored after restore_all';

package MyClass;

sub db_connect { 'Original code' }

1;
