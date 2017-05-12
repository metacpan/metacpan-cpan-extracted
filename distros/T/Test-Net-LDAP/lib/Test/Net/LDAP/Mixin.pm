use 5.006;
use strict;
use warnings;

package Test::Net::LDAP::Mixin;

use Net::LDAP;
use Net::LDAP::Constant;
use Test::Builder;
use Test::Net::LDAP::Util;

for my $method (qw(search compare add modify delete moddn bind unbind abandon)) {
    no strict 'refs';
    
    *{__PACKAGE__.'::'.$method.'_ok'} = sub {
        my $self = shift;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        return $self->method_ok($method, @_);
    };
    
    *{__PACKAGE__.'::'.$method.'_is'} = sub {
        my $self = shift;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        return $self->method_is($method, @_);
    };
}

sub method_ok {
    my $ldap = shift;
    my $method = shift;
    my ($params, $name);
    
    if (ref $_[0] eq 'ARRAY') {
        ($params, $name) = @_;
    } else {
        $params = \@_;
    }
    
    my $expected = Net::LDAP::Constant::LDAP_SUCCESS;
    return $ldap->method_is($method, $params, $expected, $name);
}

sub method_is {
    my $ldap = shift;
    my $method = shift;
    my ($params, $expected, $name);
    
    if (ref $_[0] eq 'ARRAY') {
        ($params, $expected, $name) = @_;
    } else {
        $params = \@_;
    }
    
    my $mesg = $ldap->$method(@$params);
    
    unless (defined $name) {
        my $arg = Net::LDAP::_dn_options(@$params);
        
        $name = $method.'('.join(', ', map {
            my ($param, $value) = ($_, "$arg->{$_}");
            $value = substr($value, 0, 32).'...' if length($value) > 32;
            qq($param => "$value");
        } grep {
            defined $arg->{$_}
        } qw(base scope filter dn newrdn newsuperior)).')';
    }
    
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Net::LDAP::Util::ldap_result_is($mesg, $expected, $name);
    
    return $mesg;
}

1;
