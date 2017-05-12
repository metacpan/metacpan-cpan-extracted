#!perl -T
use strict;
use warnings;

use Test::More tests => 35;

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
my @entries;

# Prepare user1, user2, user3
$data->add_ok('uid=user1, dc=example, dc=com', attrs => [
    uid => 'user1',
]);

$data->add_ok('uid=user2, dc=example, dc=com', attrs => [
    uid => 'user2',
]);

$data->add_ok('uid=user3, dc=example, dc=com', attrs => [
    uid => 'user3',
]);

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=*)', attrs => [qw(uid)],
);

is(scalar($search->entries), 3);
@entries = sort {$a->get_value('uid') cmp $b->get_value('uid')} $search->entries;
ldap_dn_is($entries[0]->dn, 'uid=user1,dc=example,dc=com');
is($entries[0]->get_value('uid'), 'user1');
ldap_dn_is($entries[1]->dn, 'uid=user2,dc=example,dc=com');
is($entries[1]->get_value('uid'), 'user2');
ldap_dn_is($entries[2]->dn, 'uid=user3,dc=example,dc=com');
is($entries[2]->get_value('uid'), 'user3');

# Delete user2
$data->delete_ok('uid=user2, dc=example, dc=com');

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=*)', attrs => [qw(uid)],
);

is(scalar($search->entries), 2);
@entries = sort {$a->get_value('uid') cmp $b->get_value('uid')} $search->entries;
ldap_dn_is($entries[0]->dn, 'uid=user1,dc=example,dc=com');
is($entries[0]->get_value('uid'), 'user1');
ldap_dn_is($entries[1]->dn, 'uid=user3,dc=example,dc=com');
is($entries[1]->get_value('uid'), 'user3');

# Delete user1
$data->delete_ok('uid=user1, dc=example, dc=com');

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=*)', attrs => [qw(uid)],
);

is(scalar($search->entries), 1);
@entries = sort {$a->get_value('uid') cmp $b->get_value('uid')} $search->entries;
ldap_dn_is($entries[0]->dn, 'uid=user3,dc=example,dc=com');
is($entries[0]->get_value('uid'), 'user3');

# Delete user3
$data->delete_ok('uid=user3, dc=example, dc=com');

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'one',
    filter => '(uid=*)', attrs => [qw(uid)],
);

is(scalar($search->entries), 0);

# Callback
$data->add_ok('uid=cb1, dc=example, dc=com');
my @callback_args;

my $mesg = $data->delete_ok('uid=cb1, dc=example, dc=com',
    callback => sub {
        push @callback_args, \@_;
    }
);

is(scalar(@callback_args), 1);
is(scalar(@{$callback_args[0]}), 1);
cmp_ok($callback_args[0][0], '==', $mesg);

# Error: dn is missing
$data->delete_is([], LDAP_PARAM_ERROR);

# Error: dn is invalid
$data->delete_is(['invalid'], LDAP_INVALID_DN_SYNTAX);
$data->delete_is([dn => 'invalid'], LDAP_INVALID_DN_SYNTAX);

# Error: Attempt to delete an entry that does not exist
$data->delete_is(['uid=invalid, dc=example, dc=com'], LDAP_NO_SUCH_OBJECT);

