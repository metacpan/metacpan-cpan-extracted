#!perl

use Test::More;

unless ( $ENV{XTATIK_TESTING} ) {
    diag 'Set XTATIK_TESTING env var to true, to run the tests';
    ok 1; done_testing; exit;
}

use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new('XTaTIK');

use lib 't';
eval 'use Test::XTaTIK';

Test::XTaTIK->load_test_products( _get_test_products() );

$t->app->config(
    custom_cat_sorting => [
        'Cat4',
        'Cat3',
        'Cat3*::*SubCat3',
        'Cat3*::*SubCat3*::*SubSubCat5',
        'Cat3*::*SubCat3*::*SubSubCat4',
        'Cat3*::*SubCat3*::*SubSubCat3',
        'Cat1',
        'Cat2*::*Cat2',
        'Cat2*::*Cat4',
        'Cat2*::*Cat1',
    ],
);

{
    $t->dive_reset->get_ok('/products')->status_is(200)
    ->element_exists_not('#back_up_category')

    ->dive_in('#product_list ')
    ->element_count_is('h3', 5)
    ->element_count_is('.cat', 5)
    ->element_count_is('.subcat', 10)
    ->element_count_is('.prod', 5);

    # Check first 'cat'
    $t->dive_in('li:first-child ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat4"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-4-001-TEST4"]', 2 );

    # Check second 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('h3', 1)
    ->element_count_is('.subcat', 5)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat3"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-3-001-TEST3"]', 2 )
    ->dive_in('.prod + .subcat ')
        ->element_count_is('a[href="/products/Cat3/SubCat3"]', 1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat3/SubCat1"]', 1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat3/SubCat2"]', 1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat3/SubCat4"]', 1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat3/SubCat5"]', 1 );

    # Check third 'cat'
    $t->dive_reset->dive_in('#product_list li:first-child + li + li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat1"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-1-001-TEST1"]', 2 );

    # Check fourth 'cat'
    $t->dive_reset->dive_in('#product_list li:first-child + li + li + li ')
    ->element_count_is('h3', 1)
    ->element_count_is('.subcat', 5)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat2"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-2-001-TEST2"]', 2 )
    ->dive_in('.prod + .subcat ')
        ->element_count_is('a[href="/products/Cat2/Cat2"]', 1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat2/Cat4"]', 1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat2/Cat1"]', 1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat2/Cat3"]', 1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat2/Cat5"]', 1 );


    # Check fifth 'cat'
    $t->dive_reset
    ->dive_in('#product_list li:first-child + li + li + li + li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat5"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-5-001-TEST5"]', 2 );
}

{
    $t->dive_reset->get_ok('/products/Cat3')->status_is(200)
    ->element_exists('#back_up_category [href="/products"]')

    ->dive_in('#product_list ')
    ->element_count_is('h3', 5)
    ->element_count_is('.cat', 6)
    ->element_count_is('.subcat', 5)
    ->element_count_is('.prod', 6);

    # Check first 'cat'
    $t->dive_in('li:first-child ')
    ->element_count_is('.subcat, h3', 0)
    ->element_count_is('.prod', 1)
    ->element_count_is('a[href="/product/Test-Product-3-001-TEST3"]', 2 );

    # Check second 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('h3', 1)
    ->element_count_is('.subcat', 5)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat3/SubCat3"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-13-001-TEST13"]', 2 )
    ->dive_in('.prod + .subcat ')
        ->element_count_is('a[href="/products/Cat3/SubCat3/SubSubCat5"]',1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat3/SubCat3/SubSubCat4"]',1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat3/SubCat3/SubSubCat3"]',1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat3/SubCat3/SubSubCat1"]',1 )
    ->dive_in('+ .subcat ')
        ->element_count_is('a[href="/products/Cat3/SubCat3/SubSubCat2"]',1);

    # Check third 'cat'
    $t->dive_reset->dive_in('#product_list li:first-child + li + li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat3/SubCat1"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-11-001-TEST11"]', 2 );

    # Check third 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat3/SubCat2"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-12-001-TEST12"]', 2 );

    # Check fourth 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat3/SubCat4"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-14-001-TEST14"]', 2 );

    # Check fifth 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat3/SubCat5"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-15-001-TEST15"]', 2 );
}

{
    $t->dive_reset->get_ok('/products/Cat3/SubCat3')->status_is(200)
    ->element_exists('#back_up_category [href="/products/Cat3"]')

    ->dive_in('#product_list ')
    ->element_count_is('h3', 5)
    ->element_count_is('.cat', 6)
    ->element_count_is('.subcat', 0)
    ->element_count_is('.prod', 6);

    # Check first 'cat'
    $t->dive_in('li:first-child ')
    ->element_count_is('.subcat, h3', 0)
    ->element_count_is('.prod', 1)
    ->element_count_is('a[href="/product/Test-Product-13-001-TEST13"]', 2 );

    # Check second 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat3/SubCat3/SubSubCat5"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-20-001-TEST20"]', 2 );

    # Check third 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat3/SubCat3/SubSubCat4"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-19-001-TEST19"]', 2 );

    # Check fourth 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat3/SubCat3/SubSubCat3"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-18-001-TEST18"]', 2 );

    # Check fifth 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat3/SubCat3/SubSubCat1"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-16-001-TEST16"]', 2 );

    # Check sixth 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat3/SubCat3/SubSubCat2"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-17-001-TEST17"]', 2 );
}

{
    $t->dive_reset->get_ok('/products/Cat2')->status_is(200)
    ->element_exists('#back_up_category [href="/products"]')

    ->dive_in('#product_list ')
    ->element_count_is('h3', 5)
    ->element_count_is('.cat', 6)
    ->element_count_is('.subcat', 0)
    ->element_count_is('.prod', 6);

    # Check first 'cat'
    $t->dive_in('li:first-child ')
    ->element_count_is('.subcat, h3', 0)
    ->element_count_is('.prod', 1)
    ->element_count_is('a[href="/product/Test-Product-2-001-TEST2"]', 2 );

    # Check second 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat2/Cat2"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-7-001-TEST7"]', 2 );

    # Check third 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat2/Cat4"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-9-001-TEST9"]', 2 );

    # Check fourth 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat2/Cat1"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-6-001-TEST6"]', 2 );

    # Check fifth 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat2/Cat3"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-8-001-TEST8"]', 2 );

    # Check sixth 'cat'
    $t->dive_in('+ li ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Cat2/Cat5"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-10-001-TEST10"]', 2 );
}

Test::XTaTIK->restore_db;

done_testing();

sub _get_test_products {
    return [
        ( map +( { category => "[Cat$_]",                    }, ), 1..5,  ),
        ( map +( { category => "[Cat2*::*Cat$_]",            }, ), 1..5,  ),
        ( map +( { category => "[Cat3*::*SubCat$_]",         }, ), 1..5,  ),
        ( map +( { category => "[Cat3*::*SubCat3*::*SubSubCat$_]", }, ),
            1..5, ),
    ];
}
