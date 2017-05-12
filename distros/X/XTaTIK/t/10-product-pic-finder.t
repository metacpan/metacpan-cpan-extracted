#!perl

############
# This test performs checks of how product pictures are handled
############

use Test::More;

unless ( $ENV{XTATIK_TESTING} ) {
    diag 'Set XTATIK_TESTING env var to true, to run the tests';
    ok 1; done_testing; exit;
}

diag join "\n", '', '', '######################',
    'NOTE: To pass, this test requires your silos to contain these files:',
    ( map "\tproduct-pics/$_",
        qw/001-TEST1.jpg  001-TEST1___2.jpg  001-TEST1___blah42.jpg
            001-TEST2.jpg  001-TEST2___blah42.jpg
            001-TEST3.jpg  001-TEST4.jpg/
    ),
    'And NOT contain these files:',
    ( map "\tproduct-pics/$_",
        qw/001-TEST5.jpg  001-TEST6.jpg  001-TEST6___42.jpg/
    ),
    '######################', '', '';


use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new('XTaTIK');

use lib 't';
eval 'use Test::XTaTIK';

Test::XTaTIK->load_test_products( _get_test_products() );

{ # Check pic display on shop page
    $t->dive_reset->get_ok('/products')->status_is(200)
    ->element_count_is('.prod img', 6)
    ->element_count_is('[src="/product-pics/001-TEST1.jpg?'
            . '001-TEST1___2.jpg?001-TEST1___blah42.jpg"]', 1)
    ->element_count_is('[src="/product-pics/001-TEST2.jpg?'
            . '001-TEST2___blah42.jpg"]', 1)
    ->element_count_is('[src="/product-pics/001-TEST3.jpg"]', 1)
    ->element_count_is('[src="/product-pics/001-TEST4.jpg"]', 1)
    ->element_count_is('[src="/product-pics/nopic.png"]', 2)
}

{ # Check pic display on individual product pages
    $t->dive_reset->get_ok('/product/Test-Product-1-001-TEST1')->status_is(200)
        ->element_exists('[src="/product-pics/001-TEST1.jpg"]')
        ->element_exists('[src="/product-pics/001-TEST1___2.jpg"]')
        ->element_exists('[src="/product-pics/001-TEST1___blah42.jpg"]')
        ->element_exists_not('[src="/product-pics/nopic.png"]')
        ->element_count_is('.prod_pic', 3)

    ->get_ok('/product/Test-Product-2-001-TEST2')->status_is(200)
        ->element_exists('[src="/product-pics/001-TEST2.jpg"]')
        ->element_exists('[src="/product-pics/001-TEST2___blah42.jpg"]')
        ->element_exists_not('[src="/product-pics/nopic.png"]')
        ->element_count_is('.prod_pic', 2)

    ->get_ok('/product/Test-Product-3-001-TEST3')->status_is(200)
        ->element_exists('[src="/product-pics/001-TEST3.jpg"]')
        ->element_exists_not('[src="/product-pics/nopic.png"]')
        ->element_count_is('.prod_pic', 1)

    ->get_ok('/product/Test-Product-4-001-TEST4')->status_is(200)
        ->element_exists('[src="/product-pics/001-TEST4.jpg"]')
        ->element_exists_not('[src="/product-pics/nopic.png"]')
        ->element_count_is('.prod_pic', 1)

    ->get_ok('/product/Test-Product-5-001-TEST5')->status_is(200)
        ->element_exists_not('[src="/product-pics/001-TEST5.jpg"]')
        ->element_exists('[src="/product-pics/nopic.png"]')
        ->element_count_is('.prod_pic', 1)

    ->get_ok('/product/Test-Product-6-001-TEST6')->status_is(200)
        ->element_exists_not('[src="/product-pics/001-TEST6.jpg"]')
        ->element_exists_not('[src="/product-pics/001-TEST6___42.jpg"]')
        ->element_exists('[src="/product-pics/nopic.png"]')
        ->element_count_is('.prod_pic', 1)
}

{   # Check hot products image display

    # Set hot products
    $t->post_ok('/login', form => { login => 'admin', pass => 'test'} )
        ->get_ok('/user/hot-products')
        ->post_ok('/user/hot-products', form => {
            hot_products => join ' ', map "001-TEST$_", 1..6
        })

    # Validate images
    ->get_ok('/')->status_is(200)
    ->element_count_is('#hot_products img', 6)
    ->element_count_is('[src="/product-pics/001-TEST1.jpg?'
            . '001-TEST1___2.jpg?001-TEST1___blah42.jpg"]', 1)
    ->element_count_is('[src="/product-pics/001-TEST2.jpg?'
            . '001-TEST2___blah42.jpg"]', 1)
    ->element_count_is('[src="/product-pics/001-TEST3.jpg"]', 1)
    ->element_count_is('[src="/product-pics/001-TEST4.jpg"]', 1)
    ->element_count_is('[src="/product-pics/nopic.png"]', 2)
}

{ # Add products to cart and check correct display on checkout page
    for ( 1..6 ) {
        $t->get_ok("/product/Test-Product-$_-001-TEST$_");
        my $csrf = $t->tx->res->dom->at('[name=csrf_token]')->attr('value');
        $t->post_ok('/cart/add' => form => {
            csrf_token  => $csrf,
            number      => "001-TEST$_",
            quantity    => 1,
        })->status_is(200);
    }

    $t->dive_reset->get_ok('/cart/')->status_is(200)
        ->element_count_is('.cart img', 6)
        ->element_count_is('[src="/product-pics/001-TEST1.jpg?'
                . '001-TEST1___2.jpg?001-TEST1___blah42.jpg"]', 1)
        ->element_count_is('[src="/product-pics/001-TEST2.jpg?'
                . '001-TEST2___blah42.jpg"]', 1)
        ->element_count_is('[src="/product-pics/001-TEST3.jpg"]', 1)
        ->element_count_is('[src="/product-pics/001-TEST4.jpg"]', 1)
        ->element_count_is('[src="/product-pics/nopic.png"]', 2)
}

Test::XTaTIK->restore_db;

done_testing();

sub _get_test_products {
    return [
        { }, # 001-TEST1.jpg  001-TEST1___2.jpg  001-TEST1___blah42.jpg
        { image => '001-TEST2.jpg?001-TEST2___blah42.jpg' },
        { }, # 001-TEST3.jpg
        { image => '001-TEST4.jpg' },
        { }, # Missing 001-TEST5.jpg
        { image => '001-TEST6.jpg?001-TEST6___42.jpg' }, # both missing
    ];
}
