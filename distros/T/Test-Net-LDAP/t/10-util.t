#!perl -T
use strict;
use warnings;

use Test::More tests => 8;

use Net::LDAP::Constant qw(
    LDAP_SUCCESS LDAP_NO_SUCH_OBJECT LDAP_ALREADY_EXISTS
);
use Test::Net::LDAP::Mock;
use Test::Net::LDAP::Util qw(
    ldap_result_ok ldap_result_is
);

# Result - status code only
ldap_result_ok(LDAP_SUCCESS);
ldap_result_is(LDAP_NO_SUCH_OBJECT, LDAP_NO_SUCH_OBJECT);

# Result - message object
my $ldap = Test::Net::LDAP::Mock->new;

my $mesg = $ldap->message('Net::LDAP::Message' => {});
$mesg->{resultCode} = LDAP_SUCCESS;
ldap_result_ok($mesg);

$mesg = $ldap->message('Net::LDAP::Message' => {});
$mesg->{resultCode} = LDAP_ALREADY_EXISTS;
ldap_result_is($mesg, LDAP_ALREADY_EXISTS);

# Export
{
    package TestPackage1;
    use Test::Net::LDAP::Util qw(ldap_result_is);
}

ok(TestPackage1->can('ldap_result_is'));
ok(!TestPackage1->can('ldap_result_ok'));

{	
    package TestPackage2;
    use Test::Net::LDAP::Util qw(:all);
}

ok(TestPackage2->can('ldap_result_is'));
ok(TestPackage2->can('ldap_result_ok'));
