#!perl

use lib 't';
use Test::More;

unless ( $ENV{XTATIK_TESTING} ) {
    diag 'Set XTATIK_TESTING env var to true, to run the tests';
    ok 1; done_testing; exit;
}

eval 'use Test::XTaTIK';
Test::XTaTIK->load_test_products( _get_test_products() );
ok 1;
done_testing();

sub _get_test_products {
    return [
        {
            category            => '[]',
            unit                => 'box of 50',
            price               => 58.99,
        },
        {
            category            => '[Test Cat 1]',
            unit                => 'case of 100',
            price               => 158.99,
        },
        {
            category            => '[Test Cat 1]',
            price               => 1558.99,
        },
        {
            category            => '[Test Cat 1*::*Test SubCat 1]',
            price               => 25458.99,
        },
        {
            category            => '[Test Cat 1*::*Test SubCat 2]',
            price               => 254.00,
        },
        {
            category => '[Test Cat 1*::*Test SubCat 2*::*Test SubSubCat 1]',
        },
        {
            category => '[Test Cat 1*::*Test SubCat 2*::*Test SubSubCat 2]',
            price    => 88.99,
        },
        {
            category            => '[Test Cat 1*::*Test SubCat 2'
                                    . '*::*Test SubSubCat 2'
                                    . '*::*Test SubSubSubCat 2]',
            price               => 48.99,
        },
    ];
}