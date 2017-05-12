use Test::Tester;
use Test::More qw(no_plan);
use User::pwent;

use strict;
use warnings;
no warnings qw(once redefine); # stop complaints about getpwnam() changes

use_ok('Test::Unix::User');

# Create a User::pwent user, populate the fields with default
# information
my $U = User::pwent->new();

foreach my $field qw(name passwd uid gid change age quota
           comment class gecos dir shell expire) {
  $U->$field('x');
}

$U->name('test');
$U->uid('1000');
$U->shell('/bin/csh');
$U->dir('/home/test');

# Override the version of getpwnam() in Test::Unix::User's namespace, and
# return our testing user if the user asked for is 'test', otherwise 
# return undef.
*Test::Unix::User::getpwnam = sub ($) { 
  if($_[0] eq 'test') {
    return $U;
  } else {
    return undef;
  }
};

# Things that should pass
check_test(sub { user_ok({ name => 'test' }, "'test' exists") },
  { ok => 1, name => "'test' exists", }, "Test for user existence");

check_test(sub { user_ok({ name => 'test' }) },
  { ok => 1, name => "Checking user 'test' (name)", }, 
  "Test for user existence (1 arg form)");

check_test(sub { user_ok({ name => 'test', shell => '/bin/csh',
                           uid => 1000, dir => '/home/test'}) },
  { ok => 1, name => "Checking user 'test' (dir, name, shell, uid)", },
  'Check for multiple items (and pass all)');

# Tests that should fail
check_test(sub { user_ok() },
  { ok => 0, name => 'user_ok()', diag => '    user_ok() called with no arguments', },
  'user_ok() with no arguments');

check_test(sub { user_ok(name => 'test', 'Check test user'); },
  { ok => 0, name => 'test',
    diag => '    First argument to user_ok() must be a hash ref'}, 
  'user_ok(SCALAR, SCALAR)');

check_test(sub { user_ok('test'); },
  { ok => 0, name => 'user_ok(...)',
    diag => '    First argument to user_ok() must be a hash ref'},
  'user_ok(SCALAR)');

check_test(sub { user_ok({ uid => 1000 }, 'Check uid 1000'); },
  { ok => 0, name => 'Check uid 1000',
    diag => '    user_ok() called with no user name', },
  "user_ok(HASHREF, SCALAR) with no 'name' key");

check_test(sub { user_ok({ uid => 1000 }); },
  { ok => 0, name => 'user_ok(...)',
    diag => '    user_ok() called with no user name', },
  "user_ok(HASHREF) with no 'name' key");

check_test(sub { user_ok({ name => undef }); },
  { ok => 0, name => 'user_ok(...)',
    diag => '    user_ok() called with no user name', },
  "user_ok(HASHREF) with 'name' key where value is undef");

check_test(sub { user_ok({ name => '' }); },
  { ok => 0, name => 'user_ok(...)',
    diag => '    user_ok() called with no user name', },
  "user_ok(HASHREF) with 'name' key where value is empty");

check_test(sub { user_ok({ name => 'test', shell => '/bin/csh',
			   uid => 1000, dir => '/home/test2'}), },
  { ok => 0, name => "Checking user 'test' (dir, name, shell, uid)", 
    diag => "    Field: dir\n    expected: /home/test2\n         got: /home/test", },
  'Check for multiple items (and fail one)');

check_test(sub { user_ok({ name => 'foo' }); },
  { ok => 0, name => "Checking user 'foo' (name)",
    diag => "    User 'foo' does not exist", },
  "user_ok(HASHREF) where 'name' key is not a valid user");

check_test(sub { user_ok({ name => 'test', bar => 'baz' }); },
  { ok => 0, name => "Checking user 'test' (bar, name)",
    diag => "    Invalid field 'bar' given", },
  "user_ok(HASHREF) valid user, nonsensical other key");

check_test(sub { user_ok({ name => 'test', uid => undef }); },
  { ok => 0, name => "Checking user 'test' (name, uid)",
    diag => "    Empty field 'uid' given", },
  "user_ok(HASHREF) valid user, undef uid");

check_test(sub { user_ok({ name => 'test', uid => '' }); },
  { ok => 0, name => "Checking user 'test' (name, uid)",
    diag => "    Empty field 'uid' given", },
  "user_ok(HASHREF) valid user, empty uid");

