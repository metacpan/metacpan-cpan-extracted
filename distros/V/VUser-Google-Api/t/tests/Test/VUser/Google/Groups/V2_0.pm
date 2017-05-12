package Test::VUser::Google::Groups::V2_0;
use warnings;
use strict;

use Test::Most;
use base 'Test::VUser::Google::Groups';

sub CreateGroup : Tests(8) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);
    can_ok $api, 'CreateGroup';

    my $group = $test->get_test_group;

    my $entry = $api->CreateGroup(
	groupId         => $group,
	groupName       => "test group $group",
	description     => 'test group descr',
	emailPermission => 'Domain',
    );

    isa_ok $entry, 'VUser::Google::Groups::GroupEntry',
	'... and the create succeeded';

    is $entry->GroupId, $group,
	'... and group id matches';

    is $entry->GroupName, "test group $group",
	'... and group name matches';

    is $entry->Description, 'test group descr',
	'... and description matches';

    is $entry->EmailPermission, 'Domain',
	'... and email permission matches';

    ## Clean up
    can_ok $api, 'DeleteGroup';
    ok $api->DeleteGroup($group),
	'... and delete suceeded';
}

sub RetrieveGroup : Tests(6) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);
    can_ok $api, 'UpdateGroup';

    my $group = $test->get_test_group;

    my $entry = $api->CreateGroup(
	groupId         => $group,
	groupName       => "test group $group",
	description     => 'test group descr',
	emailPermission => 'Domain',
    );

    my $new_entry = $api->RetrieveGroup($group);

    is $new_entry->GroupId, $group.'@'.$api->google->domain,
	'... and group id matches';

    is $new_entry->GroupName, "test group $group",
	'... and group name matches';

    is $new_entry->Description, 'test group descr',
	'... and description matches';

    is $new_entry->EmailPermission, 'Domain',
	'... and email permission matches';

    ok $api->DeleteGroup($group),
	'... and delete suceeded';
}

sub UpdateGroup : Tests(7) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);
    can_ok $api, 'UpdateGroup';

    my $group = $test->get_test_group;

    my $entry = $api->CreateGroup(
	groupId         => $group,
	groupName       => "test group $group",
	description     => 'test group descr',
	emailPermission => 'Domain',
    );

    my $new_entry = $api->UpdateGroup(
	groupId         => $group,
	#newGroupId      => $group.'.new',
	groupName       => "test group $group.new",
	description     => 'test group descr new',
	emailPermission => 'Member',

    );


    # Can't rename groups
    #$entry = $api->RetrieveGroup($group);
    #ok !defined $entry,
    #	'... and the old group is gone';

    isa_ok $new_entry, 'VUser::Google::Groups::GroupEntry',
	'... and the create succeeded';

    # Can't rename group
    #is $new_entry->GroupId, $group.'.new' #.'@'.$api->google->domain,,
    #    '... and group id matches';

    is $new_entry->GroupName, "test group $group.new",
	'... and group name matches';

    is $new_entry->Description, 'test group descr new',
	'... and description matches';

    is $new_entry->EmailPermission, 'Member',
	'... and email permission matches';

    ok $api->DeleteGroup($group),
	'... and delete suceeded';
}

sub AddMemberToGroup : Tests(8) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);

    ## create test group
    my $group = $test->get_test_group;

    my $entry = $api->CreateGroup(
	groupId         => $group,
	groupName       => "test group $group",
	description     => 'test group descr',
	emailPermission => 'Domain',
    );

    isa_ok $entry, 'VUser::Google::Groups::GroupEntry',
	'... and the create succeeded';

    ## add member to group
    can_ok $api, 'AddMemberToGroup';
    $api->AddMemberToGroup(
	'member' => 'test@example.com',
	'group'  => $group
    );

    ## get group members
  TODO: {
        local $TODO = '...';
        is 0, '2048',
            '... and member is in the group';
    }

    ## remove group member
  TODO: {
	local $TODO = 'RemoveMemberOfGroup not written';
	can_ok $api, 'RemoveMemberOfGroup';
	ok $api->RemoveMemberOfGroup(
	    'member' => 'test@example.com',
	    'group'  => $group
	);
    }

    ## get group members, member deleted?
  TODO: {
        local $TODO = '...';
        is 0, '2048',
            '... and member is in the group';
    }

    ## delete group
    can_ok $api, 'DeleteGroup';
    ok $api->DeleteGroup($group),
	'... and delete suceeded';
}

sub RetrieveAllGroupsInDomain : Tests(13) {
    my $test = shift;
    my $class = $test->class;

    my $api = $class->new(google => $test->create_google);
    can_ok $api, 'RetrieveAllGroupsInDomain';

    my @c_groups = (); # created groups

    my $base_group = $test->get_test_group;

    for my $i (0 .. 3) {
	my $entry = $api->CreateGroup(
	    groupId         => $base_group.$i,
	    groupName       => "test group $base_group$i",
	    description     => 'test group descr'.$i,
	    emailPermission => 'Domain',
	);

	push @c_groups, $entry;
    }

    my @r_groups = $api->RetrieveAllGroupsInDomain;

    for my $i (0 .. 3) {
	is $r_groups[$i]->GroupId, $c_groups[$i]->GroupId.'@'.$api->google->domain,
	    "... [$i] groupId matches";

	is $r_groups[$i]->GroupName, $c_groups[$i]->GroupName,
	    "... [$i] groupName matches";

	is $r_groups[$i]->Description, $c_groups[$i]->Description,
	    "... [$i] description matches";
    }

    ## Clean up
    foreach my $group (@c_groups) {
	$api->DeleteGroup($group->GroupId);
    }
}

1;
