use Test::Tester;
use Test::More qw(no_plan);

use User::grent;

use strict;
use warnings;

no warnings qw(once redefine);

use_ok('Test::Unix::Group');

my $G = User::grent->new();
$G->name('wheel');
$G->gid(0);
$G->members(['root','nik']);

my %U = ();
$U{'test'} = User::pwent->new();
$U{'test'}->name('test');
$U{'test'}->gid(0);

$U{'test2'} = User::pwent->new();
$U{'test2'}->name('test2');
$U{'test2'}->gid(1);

# Override Test::Unix::Group::getgrent and return our test group if asked for,
# otherwise return undef
*Test::Unix::Group::getgrnam = sub ($) {
  if($_[0] eq 'wheel') {
    return $G;
  } else {
    return undef;
  }
};

*Test::Unix::Group::getpwnam = sub ($) {
  if(exists $U{$_[0]}) {
    return $U{$_[0]};
  }

  return undef;
};

# Things that should pass

# Basic test for group existence
check_test(sub { group_ok({ name => 'wheel' }, "Check for 'wheel'"); },
	   { ok => 1, name => "Check for 'wheel'" },
	   "Test for group existence");

check_test(sub { group_ok({ name => 'wheel' }); },
	   { ok => 1, name => "Checking group 'wheel' (name)" },
	   "Test for group existence (1 arg form)");

check_test(sub { group_ok({ name => 'wheel', gid => 0}); }, 
	   { ok => 1, name => "Checking group 'wheel' (gid, name)" },
	   "Test for group and gid");

check_test(sub { group_ok({ name => 'wheel', members => [qw(nik root)] }); },
	   { ok => 1, name => "Checking group 'wheel' (members, name)" },
	   "Test for group and members");

check_test(sub { group_ok({ name => 'wheel', members => [qw(nik test root)] }); },
	   { ok => 1, name => "Checking group 'wheel' (members, name)" },
	   "Test for group and members (one is member in passwd file)");

# Things that should fail
check_test(sub { group_ok(); },
	   { ok => 0, name => "group_ok()",
	     diag => "    group_ok() called with no arguments", },
	   "group_ok() with no arguments");

check_test(sub { group_ok('wheel', 'root'); },
	   { ok => 0, name => "group_ok()",
	     diag => "    First argument to group_ok() must be a hash ref", },
	   "group_ok(SCALAR, SCALAR)");

check_test(sub { group_ok('wheel'); },
	   { ok => 0, name => "group_ok()",
	     diag => "    First argument to group_ok() must be a hash ref", },
	   "group_ok(SCALAR)");

check_test(sub { group_ok({ gid => 0}); },
	   { ok => 0, name => "group_ok(...)",
	     diag => "    group_ok() called with no group name" },
	   "group_ok(HASHREF) with no 'name' key");

check_test(sub { group_ok({ name => undef }); },
	   { ok => 0, name => "group_ok(...)",
	     diag => "    group_ok() called with no group name" },
	   "group_ok(HASHREF) with 'name' key where value is undef");

check_test(sub { group_ok({ name => '' }); },
	   { ok => 0, name => "group_ok(...)",
	     diag => "    group_ok() called with no group name" },
	   "group_ok(HASHREF) with 'name' key where value is empty");

check_test(sub { group_ok({ name => '' }, "Testing empty name"); },
	   { ok => 0, name => "Testing empty name",
	     diag => "    group_ok() called with no group name" },
	   "group_ok(HASHREF, SCALAR) with 'name' key where value is empty");

check_test(sub { group_ok({ name => 'missing' }); },
	   { ok => 0, name => "Checking group 'missing' (name)",
	     diag => "    Group 'missing' does not exist", },
	   "group_ok() called with non-existent group name");

check_test(sub { group_ok({ name => 'wheel', gid => undef }); },
	   { ok => 0, name => "Checking group 'wheel' (gid, name)",
	     diag => "    Empty field 'gid' given" },
	   "group_ok() with a valid group, undefined other value");

check_test(sub { group_ok({ name => 'wheel', gid => '' }); },
	   { ok => 0, name => "Checking group 'wheel' (gid, name)",
	     diag => "    Empty field 'gid' given" },
	   "group_ok() with a valid group, undefined other value");

check_test(sub { group_ok({ name => 'wheel', foo => 'bar' }); },
	   { ok => 0, name => "Checking group 'wheel' (foo, name)",
	     diag => "    Invalid field 'foo' given" },
	   "group_ok() with a valid group, invalid other field");

check_test(sub { group_ok({ name => 'wheel', gid => 1, members => [qw(nik root)] }); },
	   { ok => 0, name => "Checking group 'wheel' (gid, members, name)",
	     diag => "    Field: gid\n    expected: 1\n         got: 0", },
	   "Test for multiple items, one of which will fail");

# Looking for a non-existent user in a group
check_test(sub { group_ok({ name => 'wheel', members => [qw(test1)] }); },
	   { ok => 0, name => "Checking group 'wheel' (members, name)",
	     diag => "    You looked for user 'test1' in group 'wheel'\n    That account does not exist on this system", },
	   "Checking for non-existent user in a group");

# Look for user who exists but is not in the group
check_test(sub { group_ok({ name => 'wheel', members => [qw(test2)] }); },
	   { ok => 0, name => "Checking group 'wheel' (members, name)",
	     diag => "    Field: members\n    expected: user 'test2' with gid 0\n         got: user 'test2' with gid 1" },
	   "Checking for non-existent user in a group");
