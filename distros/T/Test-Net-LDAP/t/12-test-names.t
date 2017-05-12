#!perl -T
use strict;
use warnings;

use Test::More tests => 4;

use Net::LDAP::Constant qw(
    LDAP_ALREADY_EXISTS
);
use Test::Builder;
use Test::Net::LDAP::Mock;

sub test_name_is(&$) {
    my ($callback, $expected) = @_;
    my $last_name;
    {
        no warnings 'redefine';
        
        local *Test::Builder::ok = sub {
            my ($self, $test, $name) = @_;
            $last_name = $name;
        };
        
        local *Test::Builder::diag = sub {};
        
        $callback->();
    }
    
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is $last_name, $expected;
}

my $ldap = Test::Net::LDAP::Mock->new;

test_name_is {
    $ldap->method_ok('search', base => 'dc=example, dc=com');
} 'search(base => "dc=example, dc=com")';

test_name_is {
    $ldap->method_ok('search', [
        base => 'dc=example, dc=com', scope => 'sub',
        filter => '(uid=*)', attrs => [qw(uid cn)],
    ]);
} qq{search(base => "dc=example, dc=com", scope => "sub", filter => "(uid=*)")};

test_name_is {
    $ldap->method_ok('add', 'uid=user, dc=example, dc=com');
} qq{add(dn => "uid=user, dc=example, dc=com")};

test_name_is {
    $ldap->method_is('add', [
        dn => 'uid=user, dc=example, dc=com',
        attrs => [cn => 'User'],
    ], LDAP_ALREADY_EXISTS);
} qq{add(dn => "uid=user, dc=example, dc=com")};
