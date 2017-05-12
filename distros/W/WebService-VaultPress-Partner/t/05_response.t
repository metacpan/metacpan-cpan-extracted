#!/usr/bin/perl
use warnings;
use strict;
use lib 'lib';
use Test::More;
use Test::Exception;
use WebService::VaultPress::Partner::Response;

# This is really just a group of accessors
# without any requirements beyound is_success
# being set.  We'll do some random tests...

my @methods = qw/ api_call ticket unused
    basic premium email lname fname created
    type redeemed /;

for my $method ( @methods ) {
    ok ( WebService::VaultPress::Partner::Response->can( $method ),
        "Method $method exists" );
    
    # Test Accessors with random numbers
    for my $i ( 1 .. 20 ) {
        my $value = int rand 10000;
        ok my $Obj = WebService::VaultPress::Partner::Response->new(
            $method => $value,
        );

        is $Obj->$method, $value, "Expected value for $method";
        dies_ok sub {  $Obj->$method($value) }, "Cannot set accessor post constructure.";
    }
}

done_testing;
