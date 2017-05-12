#!perl -T
use strict;
use warnings;

use Test::More tests => 12;

use Test::Net::LDAP::Mock;

do {
    Test::Net::LDAP::Mock->mock_target('ldap.example.com');
    is(Test::Net::LDAP::Mock->mock_target(), 'ldap.example.com');
    my $ldap1 = Test::Net::LDAP::Mock->new('ldap1.example.com');
    my $ldap2 = Test::Net::LDAP::Mock->new('ldap2.example.com');
    my $ldap3 = Test::Net::LDAP::Mock->new('ldap3.example.com');
    my $ldap4 = Test::Net::LDAP::Mock->new('ldap1.example.com', port => 3389);
    is($ldap1->mock_data, $ldap2->mock_data);
    is($ldap1->mock_data, $ldap3->mock_data);
    isnt($ldap1->mock_data, $ldap4->mock_data);
};

do {
    Test::Net::LDAP::Mock->mock_target('ldap.example.com', port => 389);
    is_deeply(Test::Net::LDAP::Mock->mock_target(), ['ldap.example.com', {port => 389}]);
    my $ldap1 = Test::Net::LDAP::Mock->new('ldap1.example.com');
    my $ldap2 = Test::Net::LDAP::Mock->new('ldap2.example.com');
    my $ldap3 = Test::Net::LDAP::Mock->new('ldap3.example.com', port => 3389);
    my $ldap4 = Test::Net::LDAP::Mock->new('ldap1.example.com', port => 3389, scheme => 'ldaps');
    is($ldap1->mock_data, $ldap2->mock_data);
    is($ldap1->mock_data, $ldap3->mock_data);
    isnt($ldap1->mock_data, $ldap4->mock_data);
};

do {
    Test::Net::LDAP::Mock->mock_target(sub {
        my ($host, $arg) = @_;
        $host = 'ldap.example.com' if $host =~ /^ldap\d+\.example\.com$/;
        $arg->{port} = 389;
        return ($host, $arg);
    });
    is(ref(Test::Net::LDAP::Mock->mock_target()), 'CODE');

    my $ldap1 = Test::Net::LDAP::Mock->new('ldap1.example.com');
    my $ldap2 = Test::Net::LDAP::Mock->new('ldap2.example.com');
    my $ldap3 = Test::Net::LDAP::Mock->new('ldap3.example.com');
    my $ldap4 = Test::Net::LDAP::Mock->new('other.example.com');
    is($ldap1->mock_data, $ldap2->mock_data);
    is($ldap1->mock_data, $ldap3->mock_data);
    isnt($ldap1->mock_data, $ldap4->mock_data);
};
