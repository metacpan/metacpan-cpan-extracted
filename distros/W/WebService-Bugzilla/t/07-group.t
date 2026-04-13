#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::Group;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'Get group' => sub {
    my $group = $bz->group->get(5);
    isa_ok($group, 'WebService::Bugzilla::Group', 'get group returns group object');
    is($group->name, 'devs', 'group name is correct');
};

subtest 'Search groups' => sub {
    my $groups = $bz->group->search;
    isa_ok($groups, 'ARRAY', 'search returns arrayref of groups');
    is(scalar @{$groups}, 1, 'one group returned');
};

subtest 'Create group' => sub {
    my $new_group = $bz->group->create(name => 'newgroup', description => 'A group');
    isa_ok($new_group, 'WebService::Bugzilla::Group', 'create returns group object');
    is($new_group->id, 30, 'new group id is correct');
};

subtest 'Update group' => sub {
    my $updated_group = $bz->group->update(5, name => 'updated-devs');
    isa_ok($updated_group, 'WebService::Bugzilla::Group', 'update returns group object');
    is($updated_group->name, 'updated-devs', 'group name updated');
};

subtest 'Update group via instance method' => sub {
    my $group = $bz->group->get(5);
    my $inst_updated_group = $group->update(name => 'inst-devs');
    isa_ok($inst_updated_group, 'WebService::Bugzilla::Group', 'instance update returns group object');
};

done_testing();
