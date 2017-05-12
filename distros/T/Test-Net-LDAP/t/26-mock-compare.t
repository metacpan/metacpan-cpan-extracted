#!perl -T
use strict;
use warnings;

use Test::More tests => 14;

use Net::LDAP::Constant qw(
    LDAP_COMPARE_TRUE LDAP_COMPARE_FALSE
    LDAP_PARAM_ERROR LDAP_INVALID_DN_SYNTAX LDAP_NO_SUCH_OBJECT
);
use Test::Net::LDAP::Mock::Data;

my $data = Test::Net::LDAP::Mock::Data->new;

# Prepare data
$data->add_ok('uid=compare1, ou=compare, dc=example, dc=com', attrs => [
    cn => 'Compare 1'
]);

# Compare
$data->compare_is(['uid=compare1, ou=compare, dc=example, dc=com',
    attr => 'uid',
    value => 'compare1',
], LDAP_COMPARE_TRUE);

$data->compare_is(['uid=compare1, ou=compare, dc=example, dc=com',
    attr => 'cn',
    value => 'Compare 1',
], LDAP_COMPARE_TRUE);

$data->compare_is(['uid=compare1, ou=compare, dc=example, dc=com',
    attr => 'cn',
    value => 'Compare 2',
], LDAP_COMPARE_FALSE);

$data->compare_is(['uid=compare1, ou=compare, dc=example, dc=com',
    attr => 'sn',
    value => 'Compare 1',
], LDAP_COMPARE_FALSE);

# Callback
$data->add_ok('uid=cb1, dc=example, dc=com');
my @callback_args;

my $mesg = $data->compare_is(['uid=cb1, dc=example, dc=com',
    attr => 'uid',
    value => 'cb1',
    callback => sub {
        push @callback_args, \@_;
    }
], LDAP_COMPARE_TRUE);

is(scalar(@callback_args), 1);
is(scalar(@{$callback_args[0]}), 1);
cmp_ok($callback_args[0][0], '==', $mesg);

# Error: dn is missing
$data->compare_is([
    attr => 'uid',
    value => 'compare1',
], LDAP_PARAM_ERROR);

# Error: dn is invalid
$data->compare_is(['invalid',
    attr => 'uid',
    value => 'compare1',
], LDAP_INVALID_DN_SYNTAX);

$data->compare_is([
    dn => 'invalid',
    attr => 'uid',
    value => 'compare1',
], LDAP_INVALID_DN_SYNTAX);

# Error: Attempt to compare an entry that does not exist
$data->modify_is(['uid=nobody, dc=example, dc=com',
    attr => 'uid',
    value => 'compare1',
], LDAP_NO_SUCH_OBJECT);
