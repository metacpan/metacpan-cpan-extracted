package Test::VUser::Google::Provisioning::V2_0;
use warnings;
use strict;

use Test::Most;
use base 'Test::VUser::Google::Provisioning';

use vars qw($SKIP_LONG_TESTS);

sub CreateUser : Tests(12) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);
    can_ok $api, 'CreateUser';

    my $user = $test->get_test_user;

    my $res = $api->CreateUser(
	userName   => $user,
	givenName  => 'Test',
	familyName => 'User',
	password   => 'testing',
	quota      => 2048,
	changePasswordAtNextLogin => 1,
    );

    isa_ok $res, 'VUser::Google::Provisioning::UserEntry',
	'... and the account was created';

    is $res->UserName, $user, "... and the username is $user";

    ## Retrieve Test
    can_ok $api, 'RetrieveUser';
    $res = $api->RetrieveUser($user);
    isa_ok $res, 'VUser::Google::Provisioning::UserEntry',
	'... and the account was retrieved';

    is $res->GivenName, 'Test',
	'... and retrieved given name matches';

    is $res->FamilyName, 'User',
	'... and retrieved family name matches';

  TODO: {
	local $TODO = 'How to check if quota updates are disabled?';
	is $res->Quota, '2048',
	    '... and retrieved quota matches';
    }

    is $res->ChangePasswordAtNextLogin, 1,
	'... and retrieved change pw matches';

    ## clean up
    can_ok $api, 'DeleteUser';
    my $rc = $api->DeleteUser($res->UserName);
    is $rc, 1, '... and delete reports successful';

    $res = $api->RetrieveUser($user);
    ok !defined $res,
	'... and there\'s nothing to retrieve';
}

sub RetrieveUsers : Tests(5) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);

    can_ok $api, 'RetrieveUsers';
    can_ok $api, 'RetrieveAllUsers';

    my $num_users = 110;

  SKIP: {
	if ($Test::VUser::Google::SKIP_LONG_TESTS) {
	    skip "Skipping long tests at user request.", 3;
	}

	## Create 110 test users
	note "Creating $num_users test users. This will take a while.";
	my $user = $test->get_test_user;
	print STDERR "Creating test users: ";
	foreach my $i (1 .. $num_users) {
	    print STDERR "." if $i%10 == 0;
	    my $res = $api->CreateUser(
		userName   => $user.".$i",
		givenName  => 'Test',
		familyName => 'User',
		password   => 'testing',
		quota      => 2048,
		changePasswordAtNextLogin => 1,
	    );
	}
	print "\n";

	## Fetch first page of users
	my %results = $api->RetrieveUsers;
	is @{ $results{'entries'} }, 100,
	    '... and we have 100 users';
	my $next = $results{next};


	## Fetch second page of users
	%results = $api->RetrieveUsers($next);
	is $results{'entries'}[0]->UserName, $next,
	    '... and the first result of the second page is the "next" from the first page';

	## Retrieve all users
	my @entries = $api->RetrieveAllUsers;
      TODO: {
	    local $TODO = 'How many users already existed?';
	    ok @entries >= $num_users+1,
		'... and there are the expected number of users';
	}

	## Delete test users
	note "Deleting $num_users test users. This will also take a while.";
	print STDERR "\nDeleting test users: ";
	foreach my $i (1 .. $num_users) {
	    print STDERR "." if $i%10 == 0;
	    my $rc = $api->DeleteUser($user.".$i");
	}
    } # END SKIP
}

sub UpdateUser : Tests(7) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);

    can_ok $api, 'UpdateUser';

    my $user = $test->get_test_user;

    my $entry = $api->CreateUser(
	userName   => $user,
	givenName  => 'Test',
	familyName => 'User',
	password   => 'testing',
	quota      => 2048,
	changePasswordAtNextLogin => 1,
    );

    my $updated = $api->UpdateUser(
	userName   => $user,
	givenName  => 'GName'
    );

    is $updated->GivenName, 'GName',
	'... and given name matches';

    $updated = $api->UpdateUser(
	userName   => $user,
	familyName => 'Fname',
    );

    is $updated->FamilyName, 'Fname',
	'... and family name matches';

    $updated = $api->UpdateUser(
	userName   => $user,
	suspended  => 1,
    );

    is $updated->Suspended, 1,
	'... and suspended matches';

    $updated = $api->UpdateUser(
	userName   => $user,
	quota      => 1024,
    );

  TODO: {
	local $TODO = 'May not be allowed to change quotas.';
	is $updated->Quota, 1024,
	    '... and quota matches';
    }

    $updated = $api->UpdateUser(
	userName   => $user,
	changePasswordAtNextLogin => 0,
    );

    is $updated->ChangePasswordAtNextLogin, 0,
	'... and changePasswordAtNextLogin matches';

    can_ok $api, 'ChangePassword';

  TODO: {
	local $TODO = 'How can we test if setting the password actually worked?';

	# Use ClientLogin API to test Auth?
	# http://code.google.com/apis/accounts/docs/AuthForInstalledApps.html

	$updated = $api->ChangePassword(
	    $user, 'new-password',
	);

	$updated = $api->ChangePassword(
	    $user, 'd27117a019717502efe307d110f5eb3d', 'MD5'
	);

	$updated = $api->ChangePassword(
	    $user, '51eea05d46317fadd5cad6787a8f562be90b4446', 'SHA-1'
	);
    }

    my $rc = $api->DeleteUser($user);
}

sub RenameUser : Tests(6) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);

    can_ok $api, 'RenameUser';

    my $user = $test->get_test_user;

    my $old_user = $api->CreateUser(
	userName    => $user,
	givenName   => 'Test',
	familyName  => 'User',
	password    => 'testing',
    );

    my $new_user = $api->RenameUser($user, $user.'.new');

    isa_ok $new_user, 'VUser::Google::Provisioning::UserEntry',
	'... and the account was renamed';

    is $new_user->UserName, $user.'.new',
	'... and the user name has been updated';

    ## Double-check that settings match
    is $new_user->GivenName, $old_user->GivenName,
	'... and the given names match';

    is $new_user->FamilyName, $old_user->FamilyName,
	'... and the family names match';

    is $new_user->Quota, $old_user->Quota,
	'... and the quotas match';

    my $rc = $api->DeleteUser($user.'.new');
}

1;
