use Test::Tester;
use Test::More qw(no_plan);
use User::pwent;
use Cwd;

use strict;
use warnings;
no warnings qw(once redefine); # stop complaints about getpwnam() changes

use_ok('Test::Unix::User');

# Create a User::pwent user
my $U = User::pwent->new();

$U->name('test');
$U->dir(getcwd());

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

# Get stat() info for the current directory
use File::stat;
my $sb = stat(getcwd());

# Things that should pass
check_test(sub { homedir_ok({ name => 'test' }, "'test' home directory"); },
  { ok => 1, name => "'test' home directory", }, "Test for home dir existence");

check_test(sub { homedir_ok({ name => 'test' }) },
  { ok => 1, name => "Home directory for user 'test' (name)", }, 
  "Test for home dir existence (1 arg form)");

check_test(sub { homedir_ok({ name => 'test', uid => $sb->uid,
                              gid => $sb->gid, perm => $sb->mode & 07777}); },
  { ok => 1, name => "Home directory for user 'test' (gid, name, perm, uid)", },
  "Test for home dir existence with all attributes");

# Get the current owner/group for the directory and make sure that they
# pass
my $owner = getpwuid($sb->uid)->name();
my $group = getgrgid($sb->gid);

check_test(sub { homedir_ok({ name => 'test', owner => $owner }); },
  { ok => 1, name => "Home directory for user 'test' (name, owner)", 
    diag => ''},
  "Test for home dir existence with owner");

check_test(sub { homedir_ok({ name => 'test', group => $group }); },
  { ok => 1, name => "Home directory for user 'test' (group, name)", },
  "Test for home dir existence with group");

# Find another valid owner/group, and make sure they fail
my $real_uid = $sb->uid;
my $real_gid = $sb->gid;
my($wrong_uid, $wrong_owner, $wrong_gid, $wrong_group);

for($wrong_uid = 0; $wrong_uid <= 32766; $wrong_uid++) {
  next if $wrong_uid == $real_uid;
  $wrong_owner = getpwuid($wrong_uid)->name();
  last if defined $wrong_owner;
}

for($wrong_gid = 0; $wrong_gid <= 32768; $wrong_gid++) {
  next if $wrong_gid == $real_gid;
  $wrong_group = getgrgid($wrong_gid);
  last if defined $wrong_group;
}

check_test(sub { homedir_ok({ name => 'test', owner => $wrong_owner }); },
  { ok => 0, name => "Home directory for user 'test' (name, owner)", 
    diag => "    Field: owner\n    expected: $wrong_owner\n         got: $owner", },
  "Test for home dir existence with wrong owner");

check_test(sub { homedir_ok({ name => 'test', group => $wrong_group }); },
  { ok => 0, name => "Home directory for user 'test' (group, name)",
    diag => "    Field: group\n    expected: $wrong_group\n         got: $group"
, },
  "Test for home dir existence with wrong group");


#
# Can safely bypass many of the specification checks.  They're duplicated
# in the tests for user_ok, and the code calls down to _check_spec().
#

# One test to verify that _check_spec() does the right thing
check_test(sub { homedir_ok(); },
  { ok => 0, name => 'homedir_ok()', 
    diag => '    homedir_ok() called with no arguments', }, 
  "homedir_ok(), no arguments");

# Make sure that bogus fields are caught
check_test(sub { homedir_ok({ name => 'test', foo => 'bar', }); },
  { ok => 0, name => "Home directory for user 'test' (foo, name)",
    diag => "    Invalid field 'foo' given" },
  "Test for bogus field in specification");

check_test(sub { homedir_ok({ name => 'test', uid => undef, }); },
  { ok => 0, name => "Home directory for user 'test' (name, uid)",
    diag => "    Empty field 'uid' given" },
  "Test for undefined field in specification");

check_test(sub { homedir_ok({ name => 'test', uid => '', }); },
  { ok => 0, name => "Home directory for user 'test' (name, uid)",
    diag => "    Empty field 'uid' given" },
  "Test for empty field in specification");

check_test(sub { homedir_ok({ name => 'nik' }); },
  { ok => 0, name => "Home directory for user 'nik' (name)",
    diag => "    User 'nik' does not exist" , },
  "Test that it fails correctly for non-existent users");

# Make sure it fails when the home directory isn't actually a directory
my $olddir = $U->dir;
$U->dir('Build.PL');

check_test(sub { homedir_ok({ name => 'test' }); },
  { ok => 0, name => "Home directory for user 'test' (name)",
    diag => "    Home directory 'Build.PL' for 'test' is not a directory" , },
  "Test that it fails correctly for non-existent home directories");

$U->dir($olddir);

# Make sure that things fail when permissions, uids and gids
my $correct_perm = $sb->mode & 07777;
my $funky_perm   = $correct_perm ^ 1;
check_test(sub { homedir_ok({ name => 'test', uid => $sb->uid,
                              gid => $sb->gid, perm => $funky_perm}); },
  { ok => 0, name => "Home directory for user 'test' (gid, name, perm, uid)", 
    diag => sprintf("    Field: perm\n    expected: %04o\n         got: %04o\n", $funky_perm, $correct_perm), },
  "Test that incorrect permissions generate an error");

my $correct_uid = $sb->uid;
my $funky_uid = $correct_uid == 0 ? $correct_uid + 1 : $correct_uid - 1;

check_test(sub { homedir_ok({ name => 'test', uid => $funky_uid,
                              gid => $sb->gid, perm => $correct_perm}); },
  { ok => 0, name => "Home directory for user 'test' (gid, name, perm, uid)",
    diag => "    Field: uid\n    expected: $funky_uid\n         got: $correct_uid\n", },
  "Test that incorrect uid generates an error");
