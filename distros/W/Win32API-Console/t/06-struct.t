use strict;
use warnings;

use Test::More tests => 12;

use Hash::Util qw( hashref_locked );

BEGIN {
  use_ok 'Win32API::Console', qw( :Struct );
}

# Test 1: No arguments - should return default COORD with locked keys
my $coord1 = COORD();
is_deeply($coord1, { X => 0, Y => 0 }, 'COORD() returns default');
ok(hashref_locked($coord1), 'COORD() result has locked keys');

# Test 2: Valid hashref with matching keys
my $input2 = { X => 5, Y => 10 };
my $coord2 = COORD($input2);
is_deeply($coord2, $input2, 'COORD({X,Y}) returns same keys');
ok(hashref_locked($coord2), 'COORD({X,Y}) result has locked keys');

# Test 3: Two arguments - should return new hash with locked keys
my $coord3 = COORD(7, 8);
is_deeply($coord3, { X => 7, Y => 8 }, 'COORD(7,8) returns correct hash');
ok(hashref_locked($coord3), 'COORD(7,8) result has locked keys');

# Test 4: Invalid hashref (missing key)
my $coord4 = COORD({ X => 1 });
ok(!defined($coord4), 'COORD({X}) returns undef');

# Test 5: Too many arguments
my $coord5 = COORD(1, 2, 3);
ok(!defined($coord5), 'COORD(1,2,3) returns undef');

# Test 6: Test valid and invalid key access to locked hash
my $coord6 = COORD(1, 2);
ok(hashref_locked($coord6), 'COORD(1,2) result has locked keys');
eval { $coord6->{X} = 5 };
ok(!$@, 'Adjust valid key to locked hash dies not');
eval { $coord6->{Z} = 99 };
ok($@, 'Adding invalid key to locked hash dies');

done_testing();
