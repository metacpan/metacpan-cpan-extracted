#!/usr/bin/env perl

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for release candidate testing' );
    }
}

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for release candidate testing' );
    }
}

use Test::More 0.96 tests => 1;
eval { require Test::Vars };

SKIP: {
    skip 1 => 'Test::Vars required for testing for unused vars'
        if $@;
    Test::Vars->import;

    subtest 'unused vars' => sub {
        vars_ok('lib/WebService/Avalara/AvaTax/Role/Connection.pm');
        vars_ok('lib/WebService/Avalara/AvaTax/Role/Dumper.pm');
        vars_ok( 'lib/WebService/Avalara/AvaTax/Role/Service.pm' =>
                ( ignore_vars => { '$auth' => 1, '$wss' => 1 } ) );

        vars_ok('lib/WebService/Avalara/AvaTax/Service/Address.pm');
        vars_ok('lib/WebService/Avalara/AvaTax/Service/Tax.pm');

        vars_ok('lib/WebService/Avalara/AvaTax.pm');
    };
}
