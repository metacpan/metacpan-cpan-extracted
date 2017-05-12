#!perl -T
use strict;
use warnings;

use Test::More tests => 91;

use Net::LDAP::Constant qw(
    LDAP_SUCCESS LDAP_NO_SUCH_OBJECT
    LDAP_PARAM_ERROR LDAP_INVALID_DN_SYNTAX
);
use Test::Net::LDAP::Mock::Data;
use Test::Net::LDAP::Util qw(ldap_dn_is);

my $data = Test::Net::LDAP::Mock::Data->new;
my $search;
my $entries;
my $attrs;

# Prepare entries
$data->add_ok('uid=user1, ou=abc, dc=example, dc=com', attrs => [
    cn => 'foo',
    sn => 'user',
]);

$data->add_ok('uid=user2, ou=abc, dc=example, dc=com', attrs => [
    cn => 'bar',
    sn => 'user',
]);

$data->add_ok('uid=user3, ou=def, dc=example, dc=com', attrs => [
    cn => 'foo',
    sn => 'user',
]);

$data->add_ok('uid=user4, ou=def, dc=example, dc=com', attrs => [
    cn => 'bar',
    sn => 'user',
]);

# scope => 'base'
$search = $data->search_ok(
    base => 'uid=user1, ou=abc, dc=example, dc=com', scope => 'base'
);

$entries = [sort {$a->dn cmp $b->dn} $search->entries];
is($search->count, 1);
is(scalar(@$entries), 1);
ldap_dn_is($entries->[0]->dn, 'uid=user1,ou=abc,dc=example,dc=com');

# scope => 'one'
$search = $data->search_ok(
    base => 'ou=abc, dc=example, dc=com', scope => 'one'
);

$entries = [sort {$a->dn cmp $b->dn} $search->entries];
is($search->count, 2);
is(scalar(@$entries), 2);
ldap_dn_is($entries->[0]->dn, 'uid=user1,ou=abc,dc=example,dc=com');
ldap_dn_is($entries->[1]->dn, 'uid=user2,ou=abc,dc=example,dc=com');

$search = $data->search_ok(
    base => 'ou=abc, dc=example, dc=com', scope => 'one',
    filter => '(cn=bar)'
);

$entries = [sort {$a->dn cmp $b->dn} $search->entries];
is($search->count, 1);
is(scalar(@$entries), 1);
ldap_dn_is($entries->[0]->dn, 'uid=user2,ou=abc,dc=example,dc=com');

# scope => 'sub'
$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'sub'
);

$entries = [sort {$a->dn cmp $b->dn} $search->entries];
is($search->count, 4);
is(scalar(@$entries), 4);
ldap_dn_is($entries->[0]->dn, 'uid=user1,ou=abc,dc=example,dc=com');
ldap_dn_is($entries->[1]->dn, 'uid=user2,ou=abc,dc=example,dc=com');
ldap_dn_is($entries->[2]->dn, 'uid=user3,ou=def,dc=example,dc=com');
ldap_dn_is($entries->[3]->dn, 'uid=user4,ou=def,dc=example,dc=com');

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'sub',
    filter => '(cn=bar)'
);

$entries = [sort {$a->dn cmp $b->dn} $search->entries];
is($search->count, 2);
is(scalar(@$entries), 2);
ldap_dn_is($entries->[0]->dn, 'uid=user2,ou=abc,dc=example,dc=com');
ldap_dn_is($entries->[1]->dn, 'uid=user4,ou=def,dc=example,dc=com');

# Default scope => 'sub'
$search = $data->search_ok(
    base => 'dc=example, dc=com',
    filter => '(cn=bar)',
);

$entries = [sort {$a->dn cmp $b->dn} $search->entries];
is($search->count, 2);
is(scalar(@$entries), 2);
ldap_dn_is($entries->[0]->dn, 'uid=user2,ou=abc,dc=example,dc=com');
ldap_dn_is($entries->[1]->dn, 'uid=user4,ou=def,dc=example,dc=com');

# All attributes (attrs => undef)
$search = $data->search_ok(
    base => 'ou=abc, dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)'
);

$entries = [sort {$a->dn cmp $b->dn} $search->entries];
is($search->count, 1);
is(scalar(@$entries), 1);
ldap_dn_is($entries->[0]->dn, 'uid=user1,ou=abc,dc=example,dc=com');
$attrs = [sort $entries->[0]->attributes];
is(scalar(@$attrs), 3);
is($attrs->[0], 'cn');
is($attrs->[1], 'sn');
is($attrs->[2], 'uid');
is($entries->[0]->get_value('cn'), 'foo');
is($entries->[0]->get_value('sn'), 'user');
is($entries->[0]->get_value('uid'), 'user1');

# All attributes (attrs => [])
$search = $data->search_ok(
    base => 'ou=abc, dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => []
);

$entries = [sort {$a->dn cmp $b->dn} $search->entries];
$attrs = [sort $entries->[0]->attributes];
is(scalar(@$attrs), 3);
is($attrs->[0], 'cn');
is($attrs->[1], 'sn');
is($attrs->[2], 'uid');
is($entries->[0]->get_value('cn'), 'foo');
is($entries->[0]->get_value('sn'), 'user');
is($entries->[0]->get_value('uid'), 'user1');

# All attributes (attrs => ['*'])
$search = $data->search_ok(
    base => 'ou=abc, dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => ['*']
);

$entries = [sort {$a->dn cmp $b->dn} $search->entries];
$attrs = [sort $entries->[0]->attributes];
is(scalar(@$attrs), 3);
is($attrs->[0], 'cn');
is($attrs->[1], 'sn');
is($attrs->[2], 'uid');
is($entries->[0]->get_value('cn'), 'foo');
is($entries->[0]->get_value('sn'), 'user');
is($entries->[0]->get_value('uid'), 'user1');

# Limited attributes
$search = $data->search_ok(
    base => 'ou=abc, dc=example, dc=com', scope => 'one',
    filter => '(uid=user1)', attrs => [qw(cn sn)],
);

$entries = [sort {$a->dn cmp $b->dn} $search->entries];
is($search->count, 1);
is(scalar(@$entries), 1);
ldap_dn_is($entries->[0]->dn, 'uid=user1,ou=abc,dc=example,dc=com');
$attrs = [sort $entries->[0]->attributes];
is(scalar(@$attrs), 2);
is($attrs->[0], 'cn');
is($attrs->[1], 'sn');
is($entries->[0]->get_value('cn'), 'foo');
is($entries->[0]->get_value('sn'), 'user');
is($entries->[0]->get_value('uid'), undef);

# Callback
my @callback_args;

$search = $data->search_ok(
    base => 'dc=example, dc=com', scope => 'sub',
    filter => '(cn=foo)', attrs => [qw(cn sn)],
    callback => sub {
        push @callback_args, \@_;
    },
);

is(scalar(@callback_args), 3);

is(scalar(@{$callback_args[0]}), 1);
cmp_ok($callback_args[0][0], '==', $search);

is(scalar(@{$callback_args[1]}), 2);
cmp_ok($callback_args[1][0], '==', $search);
is($callback_args[1][1]->get_value('cn'), 'foo');

is(scalar(@{$callback_args[2]}), 2);
cmp_ok($callback_args[2][0], '==', $search);
is($callback_args[2][1]->get_value('cn'), 'foo');

# Error: base dn is invalid
$data->search_is([base => 'invalid'], LDAP_INVALID_DN_SYNTAX);
$data->search_is([base => ''], LDAP_SUCCESS);
$data->search_is([base => undef], LDAP_SUCCESS);

# Error: scope is invalid
$data->search_is([scope => 'invalid'], LDAP_PARAM_ERROR);
$data->search_is([scope => 3], LDAP_PARAM_ERROR);
$data->search_is([scope => 0], LDAP_SUCCESS);

# Error: filter is invalid
$data->search_is([filter => 'invalid'], LDAP_PARAM_ERROR);
$data->search_is([filter => ''], LDAP_SUCCESS);
$data->search_is([filter => undef], LDAP_SUCCESS);

# Error: base dn does not exist
$data->search_is([
    base => 'ou=invalid, dc=example, dc=com', scope => 'one',
], LDAP_NO_SUCH_OBJECT);
