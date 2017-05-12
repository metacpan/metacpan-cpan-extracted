#!perl -T
use strict;
use warnings;

use Test::More tests => 18;

use Test::Net::LDAP;
use Test::Net::LDAP::Mock;
use Test::Net::LDAP::Mock::Data;

ok(Test::Net::LDAP->can('search_ok'));
ok(Test::Net::LDAP->can('compare_ok'));
ok(Test::Net::LDAP->can('add_ok'));
ok(Test::Net::LDAP->can('modify_ok'));
ok(Test::Net::LDAP->can('delete_ok'));
ok(Test::Net::LDAP->can('moddn_ok'));
ok(Test::Net::LDAP->can('bind_ok'));
ok(Test::Net::LDAP->can('unbind_ok'));
ok(Test::Net::LDAP->can('abandon_ok'));

ok(Test::Net::LDAP->can('search_is'));
ok(Test::Net::LDAP->can('compare_is'));
ok(Test::Net::LDAP->can('add_is'));
ok(Test::Net::LDAP->can('modify_is'));
ok(Test::Net::LDAP->can('delete_is'));
ok(Test::Net::LDAP->can('moddn_is'));
ok(Test::Net::LDAP->can('bind_is'));
ok(Test::Net::LDAP->can('unbind_is'));
ok(Test::Net::LDAP->can('abandon_is'));
