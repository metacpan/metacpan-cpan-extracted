#!/usr/bin/perl

# This code, as is the case with much of the other test code is
# modified in minor ways from the original test case created
# by Kevin Ryde.

# Kevin Ryde: MyObject has data hidden away from Test::Weaken's normal
# traversals, in this case separate %data and %moredata hashes.  This is
# like an "inside-out" object, and as is sometimes done for extra data
# in a subclass.  It also resembles case where data is kept only in C
# code structures.

package MyObject;
use strict;
use warnings;

use Test::More tests => 3;
use English qw( -no_match_vars );
use Fatal qw(open close);
use Test::Weaken;
use Data::Dumper;

use lib 't/lib';
use Test::Weaken::Test;

my %data;
my %moredata;

sub construct_data {
    return ['extra data'];
}

sub construct_more_data {
    return [ 'more extra data', ['with a sub-array too'] ];
}

sub new {
    my ($class) = @_;
    my $scalar  = 42;
    my $self    = \$scalar;
    $data{ $self + 0 }     = construct_data;
    $moredata{ $self + 0 } = construct_more_data;
    return bless $self, $class;
} ## end sub new

sub DESTROY {
    my ($self) = @_;
    delete $data{ $self + 0 };
    delete $moredata{ $self + 0 };
    return;
} ## end sub DESTROY

sub data {
    my ($self) = @_;
    return $data{ $self + 0 };
}

sub moredata {
    my ($self) = @_;
    return $moredata{ $self + 0 };
}

## use Marpa::Test::Display contents sub snippet

sub contents {
    my ($probe) = @_;
    return unless Scalar::Util::reftype $probe eq 'REF';
    my $thing = ${$probe};
    return unless Scalar::Util::blessed($thing);
    return unless $thing->isa('MyObject');
    return ( $thing->data, $thing->moredata );
} ## end sub MyObject::contents

## no Marpa::Test::Display

package main;

{

## use Marpa::Test::Display contents named arg snippet

    my $tester = Test::Weaken::leaks(
        {   constructor => sub { return MyObject->new },
            contents    => \&MyObject::contents
        }
    );

## no Marpa::Test::Display

    Test::More::is( $tester, undef, 'good weaken of MyObject' );
}

# Leaky Data Detection
{
    my $leak;
    my $self_index;
    my $tester = Test::Weaken::leaks(
        {   constructor => sub {
                my $obj = MyObject->new;
                $self_index = $obj + 0;
                $leak       = $obj->data;
                return $obj;
            },
            contents => \&MyObject::contents
        }
    );
    my $test_name = 'leaky data detection';
    if ( not $tester ) {
        Test::More::fail($test_name);
    }
    else {
        Test::More::is_deeply( $leak, MyObject->construct_data, $test_name );
    }
}

# More Leaky Data Detection
{
    my $leak;
    my $self_index;
    my $tester = Test::Weaken::leaks(
        {   constructor => sub {
                my $obj = MyObject->new;
                $self_index = $obj + 0;
                $leak       = $obj->moredata;
                return $obj;
            },
            contents => \&MyObject::contents
        }
    );
    my $test_name = q{more leaky data detection};
    if ( not $tester ) {
        Test::More::fail($test_name);
    }
    else {
        Test::More::is_deeply( $leak, MyObject->construct_more_data,
            $test_name );
    }
}

exit 0;
