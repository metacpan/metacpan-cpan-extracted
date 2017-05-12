#!perl -T
use strict;
use warnings;

use Test::More tests => 77;

use Net::LDAP::Constant qw(
    LDAP_SUCCESS
    LDAP_PARAM_ERROR
    LDAP_INVALID_DN_SYNTAX
    LDAP_NO_SUCH_OBJECT
);
use Net::LDAP::Entry;
use Test::Net::LDAP::Mock::Data;
use Test::Net::LDAP::Util qw(ldap_dn_is);

my $data = Test::Net::LDAP::Mock::Data->new;
my $search;

# Prepare entry
$data->add_ok('uid=user1, dc=example, dc=com');

# Add attributes (1)
$data->modify_ok('uid=user1, dc=example, dc=com',
    add => {myattr1 => 'value1.1', myattr2 => ['value2.1', 'value2.2']}
);

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => [qw(myattr1 myattr2)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user1,dc=example,dc=com');
is_deeply([$search->entry->get_value('myattr1')], ['value1.1']);
is_deeply([$search->entry->get_value('myattr2')], ['value2.1', 'value2.2']);

# Add attributes (2)
$data->modify_ok('uid=user1, dc=example, dc=com',
    add => [myattr1 => ['value1.2'], myattr2 => 'value2.3']
);

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => [qw(myattr1 myattr2)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user1,dc=example,dc=com');
is_deeply([$search->entry->get_value('myattr1')], ['value1.1', 'value1.2']);
is_deeply([$search->entry->get_value('myattr2')], ['value2.1', 'value2.2', 'value2.3']);

# Replace attributes (1)
$data->modify_ok('uid=user1, dc=example, dc=com',
    replace => {myattr2 => 'value2.4', myattr3 => ['value3.1', 'value3.2']}
);

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => [qw(myattr1 myattr2 myattr3)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user1,dc=example,dc=com');
is_deeply([$search->entry->get_value('myattr1')], ['value1.1', 'value1.2']);
is_deeply([$search->entry->get_value('myattr2')], ['value2.4']);
is_deeply([$search->entry->get_value('myattr3')], ['value3.1', 'value3.2']);

# Replace attributes (2)
$data->modify_ok('uid=user1, dc=example, dc=com',
    replace => [myattr3 => ['value3.3', 'value3.4'], myattr4 => 'value4.1']
);

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => [qw(myattr1 myattr2 myattr3 myattr4)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user1,dc=example,dc=com');
is_deeply([$search->entry->get_value('myattr1')], ['value1.1', 'value1.2']);
is_deeply([$search->entry->get_value('myattr2')], ['value2.4']);
is_deeply([$search->entry->get_value('myattr3')], ['value3.3', 'value3.4']);
is_deeply([$search->entry->get_value('myattr4')], ['value4.1']);

# Delete attributes (1)
$data->modify_ok('uid=user1, dc=example, dc=com',
    delete => ['myattr1', 'myattr2']
);

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => [qw(myattr1 myattr2 myattr3 myattr4)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user1,dc=example,dc=com');
is($search->entry->get_value('myattr1'), undef);
is($search->entry->get_value('myattr2'), undef);
is_deeply([$search->entry->get_value('myattr3')], ['value3.3', 'value3.4']);
is_deeply([$search->entry->get_value('myattr4')], ['value4.1']);

# Delete attributes (2)
$data->modify_ok('uid=user1, dc=example, dc=com',
    delete => {myattr3 => ['value3.4'], myattr4 => []}
);

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => [qw(myattr1 myattr2 myattr3 myattr4)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user1,dc=example,dc=com');
is($search->entry->get_value('myattr1'), undef);
is($search->entry->get_value('myattr2'), undef);
is_deeply([$search->entry->get_value('myattr3')], ['value3.3']);
is($search->entry->get_value('myattr4'), undef);

# Increment attributes (1)
$data->modify_ok('uid=user1, dc=example, dc=com',
    add => {mynum1 => 100, mynum2 => [200, 300]}
);

$data->modify_ok('uid=user1, dc=example, dc=com',
    increment => {mynum1 => 22, mynum2 => 55}
);

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => [qw(mynum1 mynum2)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user1,dc=example,dc=com');
is_deeply([$search->entry->get_value('mynum1')], [122]);
is_deeply([$search->entry->get_value('mynum2')], [255, 355]);

# Increment attributes (2)
$data->modify_ok('uid=user1, dc=example, dc=com',
    increment => [mynum1 => -11, mynum2 => -22]
);

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => [qw(mynum1 mynum2)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user1,dc=example,dc=com');
is_deeply([$search->entry->get_value('mynum1')], [111]);
is_deeply([$search->entry->get_value('mynum2')], [233, 333]);

# Changes
$data->modify_ok('uid=user1, dc=example, dc=com',
    add => {
        a1 => 'v1.1',
        r1 => ['v1.1', 'v1.2'],
        d1 => ['v1.1', 'v1.2'],
        d2 => ['v2.1', 'v2.2'],
    }
);

$data->modify_ok('uid=user1, dc=example, dc=com', changes => [
    add     => [a1 => 'v1.2', a2 => 'v2.1'],
    replace => [r1 => 'v1.3', r2 => ['v2.1', 'v2.2']],
    delete  => [d1 => 'v1.1', d2 => []],
]);

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => [qw(a1 a2 r1 r2 d1 d2)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user1,dc=example,dc=com');
is_deeply([$search->entry->get_value('a1')], ['v1.1', 'v1.2']);
is_deeply([$search->entry->get_value('a2')], ['v2.1']);
is_deeply([$search->entry->get_value('r1')], ['v1.3']);
is_deeply([$search->entry->get_value('r2')], ['v2.1', 'v2.2']);
is_deeply([$search->entry->get_value('d1')], ['v1.2']);
is_deeply([$search->entry->get_value('d2')], []);

# Callback
my @callback_args;

my $mesg = $data->modify_ok('uid=user1, dc=example, dc=com',
    add => [
        callback1 => 'value1',
    ],
    callback => sub {
        push @callback_args, \@_;
    }
);

is(scalar(@callback_args), 1);
is(scalar(@{$callback_args[0]}), 1);
cmp_ok($callback_args[0][0], '==', $mesg);

# Error: dn is missing
$data->modify_is([
    replace => [cn => 'Test']
], LDAP_PARAM_ERROR);

# Error: dn is invalid
$data->modify_is(['invalid',
    replace => [cn => 'Test']
], LDAP_INVALID_DN_SYNTAX);

$data->modify_is([
    dn => 'invalid',
    replace => [cn => 'Test']
], LDAP_INVALID_DN_SYNTAX);

# Error: change type is invalid
$data->modify_is(['uid=user1, dc=example, dc=com',
    changes => [invalid => 'test']
], LDAP_PARAM_ERROR);

# Error: Attempt to modify an entry that does not exist
$data->modify_is(['uid=nobody, dc=example, dc=com',
    add => {myattr1 => 'value1.1', myattr2 => ['value2.1', 'value2.2']}
], LDAP_NO_SUCH_OBJECT);
