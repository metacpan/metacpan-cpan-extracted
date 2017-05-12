# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;
BEGIN { plan tests => 3 }

use User;

use Cwd qw( getcwd abs_path);

# Test 1: Check out Home using chdir()
my $oldpwd = getcwd;
$ENV{HOME} = $ENV{USERPROFILE} if ($^O eq 'MSWin32');
chdir();
ok( abs_path( User->Home ), getcwd );
chdir( $oldpwd );

# Test 2: Make sure Login returns something
ok( User->Login );

# Test 3: Make sure Login isn't unknown
ok( User->Login ne 'unknown' );
