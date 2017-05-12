#!perl -T
use strict;
use warnings;

use Test::More tests => 41;

use Net::LDAP::Constant qw(
    LDAP_SUCCESS
    LDAP_PARAM_ERROR
    LDAP_INVALID_DN_SYNTAX
    LDAP_NO_SUCH_OBJECT
    LDAP_ALREADY_EXISTS
);
use Net::LDAP::Entry;
use Test::Net::LDAP::Mock::Data;
use Test::Net::LDAP::Util qw(ldap_dn_is);

my $data = Test::Net::LDAP::Mock::Data->new;
my $mesg;
my $search;

# Prepare entry
$data->add_ok('uid=user1, dc=example, dc=com');

$search = $data->search_ok(
    base => 'dc=com', scope => 'sub',
    filter => '(uid=user*)', attrs => [qw(uid)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user1,dc=example,dc=com');
is($search->entry->get_value('uid'), 'user1');

# newrdn
$data->moddn_ok('uid=user1, dc=example, dc=com',
    newrdn => 'uid=user2',
    deleteoldrdn => 0,
);

$search = $data->search_ok(
    base => 'dc=com', scope => 'sub',
    filter => '(uid=user*)', attrs => [qw(uid)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user2,dc=example,dc=com');
is_deeply([sort $search->entry->get_value('uid')], ['user1', 'user2']);

# newrdn, deleteoldrdn
$data->moddn_ok('uid=user2, dc=example, dc=com',
    newrdn => 'uid=user3',
    deleteoldrdn => 1,
);

$search = $data->search_ok(
    base => 'dc=com', scope => 'sub',
    filter => '(uid=user*)', attrs => [qw(uid)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user3,dc=example,dc=com');
is_deeply([sort $search->entry->get_value('uid')], ['user1', 'user3']);

# newsuperior
$data->moddn_ok('uid=user3, dc=example, dc=com',
    newsuperior => 'dc=example2, dc=com',
);

$search = $data->search_ok(
    base => 'dc=com', scope => 'sub',
    filter => '(uid=user*)', attrs => [qw(uid)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user3,dc=example2,dc=com');
is_deeply([sort $search->entry->get_value('uid')], ['user1', 'user3']);

# newsuperior, newrdn
$data->moddn_ok('uid=user3, dc=example2, dc=com',
    newsuperior => 'dc=example3, dc=com',
    newrdn => 'uid=user4',
    deleteoldrdn => 1,
);

$search = $data->search_ok(
    base => 'dc=com', scope => 'sub',
    filter => '(uid=user*)', attrs => [qw(uid)],
);

is(scalar($search->entries), 1);
ldap_dn_is($search->entry->dn, 'uid=user4,dc=example3,dc=com');
is_deeply([sort $search->entry->get_value('uid')], ['user1', 'user4']);

# Callback
$data->add_ok('uid=cb1, dc=example, dc=com');
my @callback_args;

$mesg = $data->modify_ok('uid=cb1, dc=example, dc=com',
    newrdn => 'uid=cb2',
    callback => sub {
        push @callback_args, \@_;
    }
);

is(scalar(@callback_args), 1);
is(scalar(@{$callback_args[0]}), 1);
cmp_ok($callback_args[0][0], '==', $mesg);

# Prepare entries for error cases
$data->add_ok('uid=user1, dc=example1, dc=com');
$data->add_ok('uid=user2, dc=example1, dc=com');
$data->add_ok('uid=user2, dc=example2, dc=com');

# Error: dn is missing
$data->moddn_is([
    newrdn => 'uid=user2'
], LDAP_PARAM_ERROR);

# Error: dn is invalid
$data->moddn_is(['invalid',
    newrdn => 'uid=user2'
], LDAP_INVALID_DN_SYNTAX);

$data->moddn_is([
    dn => 'invalid',
    newrdn => 'uid=user2'
], LDAP_INVALID_DN_SYNTAX);

# Error: newrdn is invalid
$data->moddn_is([
    dn => 'uid=user1, dc=example1, dc=com',
    newrdn => 'invalid'
], LDAP_INVALID_DN_SYNTAX);

# Error: newsuperior is invalid
$data->moddn_is([
    dn => 'uid=user1, dc=example1, dc=com',
    newrdn => 'uid=user3',
    newsuperior => 'invalid',
], LDAP_INVALID_DN_SYNTAX);

# Error: Attempt to modify an entry that does not exist
$data->moddn_is(['uid=invalid, dc=example, dc=com',
    newrdn => 'uid=user1',
], LDAP_NO_SUCH_OBJECT);

# Error: Attempt to move DN to an already existing destination
$data->moddn_is(['uid=user1, dc=example1, dc=com',
    newrdn => 'uid=user2',
], LDAP_ALREADY_EXISTS);

$data->moddn_is(['uid=user1, dc=example1, dc=com',
    newrdn => 'uid=user2',
    newsuperior => 'dc=example2, dc=com',
], LDAP_ALREADY_EXISTS);
