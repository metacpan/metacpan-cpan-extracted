use strict;

use Test::Builder::Tester;
use Test::More;
use Test::File;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#let's test with the first file we find in the current dir
my( $filename, $file_gid, $owner_uid, $owner_name, $file_group_name );
eval
	{
	$filename = glob( "*" );

	die "Could not find a file" unless defined $filename;

	$owner_uid = ( stat $filename )[4];
	die "failed to find $filename's owner\n" unless defined $owner_uid;

	$file_gid = ( stat $filename )[5];
	die "failed to find $filename's owner\n" unless defined $file_gid;

	$owner_name = ( getpwuid $owner_uid )[0];
	die "failed to find $filename's owner as name\n" unless defined $owner_name;

	$file_group_name = ( getgrgid $file_gid )[0];
	die "failed to find $filename's group as name\n" unless defined $file_group_name;
	};
plan skip_all => "I can't find a file to test with: $@" if $@;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# find some name that isn't the one we found before
my( $other_name, $other_uid, $other_group_name, $other_gid );
eval
	{
	for( my $i = 0; $i < 65535; $i++ )
		{
		next if $i == $owner_uid;

		my @stats = getpwuid $i;
		next unless @stats;

		( $other_uid, $other_name )  = ( $i, $stats[0] );
		last;
		}

 	# XXX: why the for loop?
	for( my $i = 0; $i < 65535; $i++ )
		{
		next if $i == $file_gid;

		my @stats = getgrgid $i;
		next unless @stats;

		( $other_gid, $other_group_name )  = ( $i, $stats[0] );
 		last;
 		}

	die "Failed to find another uid" unless defined $other_uid;
	die "Failed to find name for other uid ($other_uid)"
		unless defined $other_name;
	die "Failed to find another gid" unless defined $other_gid;
	die "Failed to find name for other gid ($other_gid)"
		unless defined $other_group_name;
	};
plan skip_all => "I can't find a second user id to test with: $@" if $@;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# find some names that don't exist, to test bad input
my( $invalid_user_name, $invalid_group_name );
eval
	{
	foreach my $user ( 'aaaa' .. 'zzzz' )
		{
		my @stats = getpwnam $user;
		next if @stats;

		$invalid_user_name  = $user;
		#diag "Using invalid user [$user] for tests";
		last;
		}

	foreach my $group ( 'aaaa' .. 'zzzz' )
		{
		my @stats = getpwnam $group;
		next if @stats;

		$invalid_group_name  = $group;
		#diag "Using invalid group [$group] for tests";
		last;
		}

	diag "Failed to find an invalid username" unless defined $other_uid;

	diag "Failed to find another gid" unless defined $other_gid;
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# test owner stuff
owner_is(   $filename, $owner_name, 'owner_is with text username'   );
owner_is(   $filename, $owner_uid,  'owner_is with numeric UID'     );
owner_isnt( $filename, $other_name, 'owner_isnt with text username' );
owner_isnt( $filename, $other_uid,  'owner_isnt with numeric UID'   );


my $name = 'Intentional owner_is failure with wrong user';
my $testname = "$filename belongs to $other_name";
test_out( "not ok 1 - $testname");
test_diag(
	"File [$filename] belongs to $owner_name ($owner_uid), not $other_name " .
	"($other_uid)!\n" .
	"#   Failed test '$testname'\n".
	"#   at t/owner.t line " . line_num(+6) . "."
	);
owner_is( $filename, $other_name );
test_test( $name );


$name = "Intentional owner_is failure with invalid user [$invalid_user_name]";
$testname = "$filename belongs to $invalid_user_name";
test_out( "not ok 1 - $testname");
test_diag(
	"User [$invalid_user_name] does not exist on this system!\n" .
	"#   Failed test '$testname'\n".
	"#   at t/owner.t line " . line_num(+5) . "."
	);
owner_is( $filename, $invalid_user_name );
test_test( $name );


$name = 'owner_isnt for non-existent name';
$testname = "$filename doesn't belong to $invalid_user_name";
test_out( "ok 1 - $testname");
owner_isnt( $filename, $invalid_user_name );
test_test( $name );


$name = 'Intentional owner_isnt failure';
$testname = "$filename doesn't belong to $owner_name";
test_out( "not ok 1 - $testname");
test_diag(
	"File [$filename] belongs to $owner_name ($owner_uid)!\n" .
	"#   Failed test '$testname'\n" .
	"#   at t/owner.t line " . line_num(+5) . "."
	);
owner_isnt( $filename, $owner_name );
test_test( $name );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# test group stuff
group_is(   $filename, $file_group_name, 'group_is with text groupname'    );
group_is(   $filename, $file_gid,  'group_is with numeric GID'             );
group_isnt( $filename, $other_group_name, 'group_isnt with text groupname' );
group_isnt( $filename, $other_gid,  'group_isnt with numeric GID'          );


$name = 'Intentional group_is failure';
test_out( "not ok 1 - $name");
test_diag(
	"File [$filename] belongs to $file_group_name ($file_gid), not ".
	"$other_group_name " .
	"($other_gid)!\n" .
	"#   Failed test '$name'\n".
	"#   at t/owner.t line " . line_num(+7) . "."
	);
group_is( $filename, $other_group_name, $name );
test_test( $name );


$name = "Intentional group_is failure with invalid group [$invalid_group_name]";
test_out( "not ok 1 - $name");
test_diag(
	"Group [$invalid_group_name] does not exist on this system!\n" .
	"#   Failed test '$name'\n".
	"#   at t/owner.t line " . line_num(+5) . "."
	);
group_is( $filename, $invalid_group_name, $name );
test_test( $name );


$name = 'Intentional group_isnt failure';
test_out( "not ok 1 - $name");
test_diag(
	"File [$filename] belongs to $file_group_name ($file_gid)!\n" .
	"#   Failed test '$name'\n" .
	"#   at t/owner.t line " . line_num(+5) . "."
	);
group_isnt( $filename, $file_group_name, $name );
test_test( $name );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

done_testing();
