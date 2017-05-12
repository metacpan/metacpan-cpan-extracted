#!perl -T
use strict;
use warnings;

use Test::More tests => 51;

use Net::LDAP;
use Test::Net::LDAP::Util qw(ldap_mockify ldap_dn_is);

ldap_mockify {
    # ldap1
    for my $ldap (Net::LDAP->new('ldap1.example.com')) {
        is ref($ldap), 'Test::Net::LDAP::Mock';
        
        $ldap->add('uid=user01, dc=example, dc=com');
        $ldap->add('uid=user02, dc=example, dc=com');
        
        my $search = $ldap->search_ok(scope => 'sub', filter => '(uid=*)');
        is scalar($search->entries), 2;
        
        my $entries = [sort {$a->dn cmp $b->dn} $search->entries];
        ldap_dn_is $entries->[0]->dn, 'uid=user01,dc=example,dc=com';
        ldap_dn_is $entries->[1]->dn, 'uid=user02,dc=example,dc=com';
    }
    
    # ldap2
    for my $ldap (Net::LDAP->new('ldap2.example.com')) {
        is ref($ldap), 'Test::Net::LDAP::Mock';
        
        $ldap->add('uid=user03, dc=example, dc=com');
        $ldap->add('uid=user04, dc=example, dc=com');
        
        my $search = $ldap->search_ok(scope => 'sub', filter => '(uid=*)');
        is scalar($search->entries), 2;
        
        my $entries = [sort {$a->dn cmp $b->dn} $search->entries];
        ldap_dn_is $entries->[0]->dn, 'uid=user03,dc=example,dc=com';
        ldap_dn_is $entries->[1]->dn, 'uid=user04,dc=example,dc=com';
    }
    
    # ldap1, port 3389
    for my $ldap (Net::LDAP->new('ldap1.example.com', port => 3389)) {
        is ref($ldap), 'Test::Net::LDAP::Mock';
        
        $ldap->add('uid=user05, dc=example, dc=com');
        $ldap->add('uid=user06, dc=example, dc=com');
        
        my $search = $ldap->search_ok(scope => 'sub', filter => '(uid=*)');
        is scalar($search->entries), 2;
        
        my $entries = [sort {$a->dn cmp $b->dn} $search->entries];
        ldap_dn_is $entries->[0]->dn, 'uid=user05,dc=example,dc=com';
        ldap_dn_is $entries->[1]->dn, 'uid=user06,dc=example,dc=com';
    }
    
    # ldap1, ldaps
    for my $ldap (Net::LDAP->new('ldap1.example.com', scheme => 'ldaps')) {
        is ref($ldap), 'Test::Net::LDAP::Mock';
        
        $ldap->add('uid=user07, dc=example, dc=com');
        $ldap->add('uid=user08, dc=example, dc=com');
        
        my $search = $ldap->search_ok(scope => 'sub', filter => '(uid=*)');
        is scalar($search->entries), 2;
        
        my $entries = [sort {$a->dn cmp $b->dn} $search->entries];
        ldap_dn_is $entries->[0]->dn, 'uid=user07,dc=example,dc=com';
        ldap_dn_is $entries->[1]->dn, 'uid=user08,dc=example,dc=com';
    }
    
    # /tmp/ldap1, ldapi
    for my $ldap (Net::LDAP->new('/tmp/ldap1', scheme => 'ldapi')) {
        is ref($ldap), 'Test::Net::LDAP::Mock';
        
        $ldap->add('uid=user09, dc=example, dc=com');
        $ldap->add('uid=user10, dc=example, dc=com');
        
        my $search = $ldap->search_ok(scope => 'sub', filter => '(uid=*)');
        is scalar($search->entries), 2;
        
        my $entries = [sort {$a->dn cmp $b->dn} $search->entries];
        ldap_dn_is $entries->[0]->dn, 'uid=user09,dc=example,dc=com';
        ldap_dn_is $entries->[1]->dn, 'uid=user10,dc=example,dc=com';
    }
    
    # /tmp/ldap2, ldapi
    for my $ldap (Net::LDAP->new('/tmp/ldap2', scheme => 'ldapi')) {
        is ref($ldap), 'Test::Net::LDAP::Mock';
        
        $ldap->add('uid=user11, dc=example, dc=com');
        $ldap->add('uid=user12, dc=example, dc=com');
        
        my $search = $ldap->search_ok(scope => 'sub', filter => '(uid=*)');
        is scalar($search->entries), 2;
        
        my $entries = [sort {$a->dn cmp $b->dn} $search->entries];
        ldap_dn_is $entries->[0]->dn, 'uid=user11,dc=example,dc=com';
        ldap_dn_is $entries->[1]->dn, 'uid=user12,dc=example,dc=com';
    }
};

ldap_mockify {
    # ldap1 (again)
    for my $ldap (Net::LDAP->new('ldap1.example.com')) {
        is ref($ldap), 'Test::Net::LDAP::Mock';
        
        my $search = $ldap->search_ok(scope => 'sub', filter => '(uid=*)');
        is scalar($search->entries), 2;
        
        my $entries = [sort {$a->dn cmp $b->dn} $search->entries];
        ldap_dn_is $entries->[0]->dn, 'uid=user01,dc=example,dc=com';
        ldap_dn_is $entries->[1]->dn, 'uid=user02,dc=example,dc=com';
    }
};

ldap_mockify {
    # Net::LDAP->new() can take an array ref as hostnames.
    # In that case, the first one should be used.
    for my $ldap (Net::LDAP->new(['ldap1.example.com', 'ldap2.example.com'])) {
        is ref($ldap), 'Test::Net::LDAP::Mock';
        
        my $search = $ldap->search_ok(scope => 'sub', filter => '(uid=*)');
        is scalar($search->entries), 2;
        
        my $entries = [sort {$a->dn cmp $b->dn} $search->entries];
        ldap_dn_is $entries->[0]->dn, 'uid=user01,dc=example,dc=com';
        ldap_dn_is $entries->[1]->dn, 'uid=user02,dc=example,dc=com';
    }
};

# Net::LDAP subclasses
{
    package Net::LDAP::MySubclass1;
    use base 'Net::LDAP';

    sub new {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        $self->{__subclass_test} = ref($self).'::new called';
        return $self;
    }

    sub search {
        my $self = shift;
        my $mesg = $self->SUPER::search(@_);
        $mesg->{__subclass_test} = ref($self).'::search called';
        return $mesg;
    }

    package Net::LDAP::MySubclass2;
    use base 'Net::LDAP::MySubclass1';

    sub my_method {
        my ($self) = @_;
        return ref($self).'::my_method called';
    }
}

ok !'Net::LDAP::MySubclass1'->isa('Test::Net::LDAP::Mock');

ldap_mockify {
    Net::LDAP::MySubclass1->new('subclass1.example.com');
    ok 'Net::LDAP::MySubclass1'->isa('Test::Net::LDAP::Mock');

    do {
        my $ldap = Net::LDAP::MySubclass1->new('subclass1.example.com');
        is($ldap->{__subclass_test}, 'Net::LDAP::MySubclass1::new called');

        $ldap->add_ok('uid=subclass1, dc=example, dc=com');

        my $mesg = $ldap->search_ok(
            base => 'dc=example, dc=com', scope => 'one', filter => 'uid=subclass1',
        );

        is($mesg->{__subclass_test}, 'Net::LDAP::MySubclass1::search called');
        is($mesg->count, 1);
    };

    do {
        my $ldap = Net::LDAP::MySubclass2->new('subclass2.example.com');
        is($ldap->{__subclass_test}, 'Net::LDAP::MySubclass2::new called');
        is($ldap->my_method, 'Net::LDAP::MySubclass2::my_method called');
    };
};

ok !'Net::LDAP::MySubclass1'->isa('Test::Net::LDAP::Mock');
ok 'Net::LDAP::MySubclass2'->isa('Net::LDAP::MySubclass1');
