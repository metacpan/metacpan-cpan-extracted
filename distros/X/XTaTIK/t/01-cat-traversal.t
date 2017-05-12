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

{
    $t->dive_reset->get_ok('/products')->status_is(200)
    ->element_exists_not('#back_up_category')

    ->dive_in('#product_list ')
    ->element_count_is('h3', 1)
    ->element_count_is('.cat', 2)
    ->element_count_is('.subcat', 2)
    ->element_count_is('.prod', 3)

    # Check first 'cat'
    ->dive_in('li:first-child ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 0)
    ->element_count_is('.prod', 1)
    ->element_count_is('a[href="/product/Test-Product-1-001-TEST1"]', 2 )

    # Check second 'cat'
    ->dive_in('+ li ')
    ->element_count_is('h3', 1)
    ->element_count_is('.subcat', 2)
    ->element_count_is('.prod', 2)
    ->element_count_is('h3 a[href="/products/Test Cat 1"]', 1 )
    ->element_count_is('a[href="/product/Test-Product-2-001-TEST2"]', 2 )
    ->element_count_is('a[href="/product/Test-Product-3-001-TEST3"]', 2 )
    ->element_count_is('a[href="/products/Test Cat 1/Test SubCat 1"]', 1 )
    ->element_count_is('a[href="/products/Test Cat 1/Test SubCat 2"]', 1 )
}

{
    $t->dive_reset->get_ok('/products/Test Cat 1')->status_is(200)
    ->element_exists('#back_up_category [href="/products"]')

    ->dive_in('#product_list ')
    ->element_count_is('h3', 2)
    ->element_count_is('.cat', 3)
    ->element_count_is('.subcat', 2)
    ->element_count_is('.prod', 4)

    # Check first 'cat'
    ->dive_in('li:first-child ')
    ->element_count_is('h3, .subcat', 0)
    ->element_count_is('.prod', 2)
    ->element_count_is('a[href="/product/Test-Product-2-001-TEST2"]', 2 )
    ->element_count_is('a[href="/product/Test-Product-3-001-TEST3"]', 2 )

    # Check second 'cat'
    ->dive_in('+ li ')
    ->element_count_is('h3', 1)
    ->element_count_is('.subcat', 0)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Test Cat 1/Test SubCat 1"]',1 )
    ->element_count_is('a[href="/product/Test-Product-4-001-TEST4"]', 2 )

    # Check third 'cat'
    ->dive_in('+ li ')
    ->element_count_is('h3', 1)
    ->element_count_is('.subcat', 2)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Test Cat 1/Test SubCat 2"]',1 )
    ->element_count_is('a[href="/product/Test-Product-5-001-TEST5"]', 2 )
    ->element_count_is(
        'a[href="/products/Test Cat 1/Test SubCat 2/Test SubSubCat 1"]', 1 )
    ->element_count_is(
        'a[href="/products/Test Cat 1/Test SubCat 2/Test SubSubCat 2"]', 1 )
}

{
    $t->dive_reset->get_ok('/products/Test Cat 1/Test SubCat 1')
    ->status_is(200)
    ->element_exists('#back_up_category [href="/products/Test Cat 1"]')

    ->dive_in('#product_list ')
    ->element_count_is('h3, .subcat', 0)
    ->element_count_is('.cat', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('a[href="/product/Test-Product-4-001-TEST4"]', 2 )
}

{
    $t->dive_reset->get_ok('/products/Test Cat 1/Test SubCat 2')
    ->status_is(200)
    ->element_exists('#back_up_category [href="/products/Test Cat 1"]')

    ->dive_in('#product_list ')
    ->element_count_is('h3', 2)
    ->element_count_is('.cat', 3)
    ->element_count_is('.subcat', 1)
    ->element_count_is('.prod', 3)

    # Check first 'cat'
    ->dive_in('li:first-child ')
    ->element_count_is('h3, .subcat', 0)
    ->element_count_is('.prod', 1)
    ->element_count_is('a[href="/product/Test-Product-5-001-TEST5"]', 2 )

    # Check second 'cat'
    ->dive_in('+ li ')
    ->element_count_is('h3', 1)
    ->element_count_is('.subcat', 0)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Test Cat 1/'
            . 'Test SubCat 2/Test SubSubCat 1"]',1 )
    ->element_count_is('a[href="/product/Test-Product-6-001-TEST6"]', 2 )

    # Check third 'cat'
    ->dive_in('+ li ')
    ->element_count_is('h3', 1)
    ->element_count_is('.subcat', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Test Cat 1/'
            . 'Test SubCat 2/Test SubSubCat 2"]',1 )
    ->element_count_is('a[href="/product/Test-Product-7-001-TEST7"]', 2 )
    ->element_count_is('a[href="/products/Test Cat 1/Test SubCat 2/'
            . 'Test SubSubCat 2/Test SubSubSubCat 2"]', 1 )
}

{
    $t->dive_reset
    ->get_ok('/products/Test Cat 1/Test SubCat 2/Test SubSubCat 1')
    ->status_is(200)
    ->element_exists(
        '#back_up_category [href="/products/Test Cat 1/Test SubCat 2"]')

    ->dive_in('#product_list ')
    ->element_count_is('h3, .subcat', 0)
    ->element_count_is('.cat', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('a[href="/product/Test-Product-6-001-TEST6"]', 2 )
}

{
    $t->dive_reset
    ->get_ok('/products/Test Cat 1/Test SubCat 2/Test SubSubCat 2')
    ->status_is(200)
    ->element_exists(
        '#back_up_category [href="/products/Test Cat 1/Test SubCat 2"]')

    ->dive_in('#product_list ')
    ->element_count_is('h3', 1)
    ->element_count_is('.cat', 2)
    ->element_count_is('.subcat', 0)
    ->element_count_is('.prod', 2)

    # Check first 'cat'
    ->dive_in('li:first-child ')
    ->element_count_is('h3, .subcat', 0)
    ->element_count_is('.prod', 1)
    ->element_count_is('a[href="/product/Test-Product-7-001-TEST7"]', 2 )

    # Check second 'cat'
    ->dive_in('+ li ')
    ->element_count_is('h3', 1)
    ->element_count_is('.subcat', 0)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Test Cat 1/'
            . 'Test SubCat 2/Test SubSubCat 2/Test SubSubSubCat 2"]',1 )
    ->element_count_is('a[href="/product/Test-Product-8-001-TEST8"]', 2 )
}

{
    $t->dive_reset
    ->get_ok('/products/Test Cat 1/Test SubCat 2/'
            . 'Test SubSubCat 2/Test SubSubSubCat 2')
    ->status_is(200)
    ->element_exists('#back_up_category [href="/products/Test Cat 1/'
            . 'Test SubCat 2/Test SubSubCat 2"]')

    ->dive_in('#product_list ')
    ->element_count_is('h3, .subcat', 0)
    ->element_count_is('.cat', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('a[href="/product/Test-Product-8-001-TEST8"]', 2 )
}


###########################
###########################
### Test alternate category configurations:
### [cat*::*subcat] (Issue #119)
###########################
###########################

Test::XTaTIK->load_test_products( _get_test_products_cat_cat() );

{
    $t->dive_reset->get_ok('/products')->status_is(200)
    ->element_exists_not('#back_up_category')

    ->dive_in('#product_list ')
    ->element_count_is('h3', 1)
    ->element_count_is('.cat', 1)
    ->element_count_is('.subcat', 2)
    ->element_count_is('.prod', 0)

    # Check first 'cat'
    ->dive_in('li:first-child ')
    ->element_count_is('.subcat', 2)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 0)
    ->element_count_is('h3 a[href="/products/Test Cat 1"]', 1 )
    ->element_count_is('a[href="/products/Test Cat 1/Test SubCat 1"]', 1 )
    ->element_count_is('a[href="/products/Test Cat 1/Test SubCat 2"]', 1 )
}

{
    $t->dive_reset->get_ok('/products/Test Cat 1')->status_is(200)
    ->element_exists('#back_up_category [href="/products"')

    ->dive_in('#product_list ')
    ->element_count_is('h3', 2)
    ->element_count_is('.cat', 2)
    ->element_count_is('.subcat', 0)
    ->element_count_is('.prod', 4)

    # Check first 'cat'
    ->dive_in('li:first-child ')
    ->element_count_is('.subcat', 0)
    ->element_count_is('h3', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('h3 a[href="/products/Test Cat 1/Test SubCat 1"]',1 )
    ->element_count_is('a[href="/product/Test-Product-1-001-TEST1"]', 2 )

    # Check second 'cat'
    ->dive_in('+ li ')
    ->element_count_is('h3', 1)
    ->element_count_is('.subcat', 0)
    ->element_count_is('.prod', 3)
    ->element_count_is('h3 a[href="/products/Test Cat 1/Test SubCat 2"]',1 )
    ->element_count_is('a[href="/product/Test-Product-2-001-TEST2"]', 2 )
    ->element_count_is('a[href="/product/Test-Product-3-001-TEST3"]', 2 )
    ->element_count_is('a[href="/product/Test-Product-4-001-TEST4"]', 2 )
}

{
    $t->dive_reset
    ->get_ok('/products/Test Cat 1/Test SubCat 1')
    ->status_is(200)
    ->element_exists('#back_up_category [href="/products/Test Cat 1"]')

    ->dive_in('#product_list ')
    ->element_count_is('h3, .subcat', 0)
    ->element_count_is('.cat', 1)
    ->element_count_is('.prod', 1)
    ->element_count_is('a[href="/product/Test-Product-1-001-TEST1"]', 2 )
}

{
    $t->dive_reset
    ->get_ok('/products/Test Cat 1/Test SubCat 2')
    ->status_is(200)
    ->element_exists('#back_up_category [href="/products/Test Cat 1"]')

    ->dive_in('#product_list ')
    ->element_count_is('h3, .subcat', 0)
    ->element_count_is('.cat', 1)
    ->element_count_is('.prod', 3)
    ->element_count_is('a[href="/product/Test-Product-2-001-TEST2"]', 2 )
    ->element_count_is('a[href="/product/Test-Product-3-001-TEST3"]', 2 )
    ->element_count_is('a[href="/product/Test-Product-4-001-TEST4"]', 2 )
}

###########################
###########################
### Test alternate category configurations:
### no categories
###########################
###########################

Test::XTaTIK->load_test_products( _get_test_products_no_cats() );

{
    $t->dive_reset
    ->get_ok('/products')
    ->status_is(200)
    ->element_exists_not('#back_up_category')

    ->dive_in('#product_list ')
    ->element_count_is('h3, .subcat', 0)
    ->element_count_is('.cat', 1)
    ->element_count_is('.prod', 5)
    ->element_count_is('a[href="/product/Test-Product-1-001-TEST1"]', 2 )
    ->element_count_is('a[href="/product/Test-Product-2-001-TEST2"]', 2 )
    ->element_count_is('a[href="/product/Test-Product-3-001-TEST3"]', 2 )
    ->element_count_is('a[href="/product/Test-Product-4-001-TEST4"]', 2 )
    ->element_count_is('a[href="/product/Test-Product-5-001-TEST5"]', 2 )
}

Test::XTaTIK->restore_db;

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
            category            => '[Test Cat 1*::*Test SubCat 2'
                                    . '*::*Test SubSubCat 1]',
        },
        {
            category            => '[Test Cat 1*::*Test SubCat 2'
                                    . '*::*Test SubSubCat 2]',
            price               => 88.99,
        },
        {
            category            => '[Test Cat 1*::*Test SubCat 2'
                                    . '*::*Test SubSubCat 2'
                                    . '*::*Test SubSubSubCat 2]',
            price               => 48.99,
        },
    ];
}

sub _get_test_products_cat_cat {
    return [
        {
            category            => '[Test Cat 1*::*Test SubCat 1]',
            price               => 25458.99,
        },
        {
            category            => '[Test Cat 1*::*Test SubCat 2]',
            price               => 254.00,
        },
        {
            category            => '[Test Cat 1*::*Test SubCat 2]',
            price               => 25458.99,
        },
        {
            category            => '[Test Cat 1*::*Test SubCat 2]',
            price               => 254.00,
        },
    ];
}

sub _get_test_products_no_cats {
    return [
        { price => 25458.99, },
        { price => 25452.99, },
        { price => 25451.99, },
        { price => 25452.99, },
        { price => 0, },
    ];
}
