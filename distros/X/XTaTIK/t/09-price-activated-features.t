#!perl

############
# This test performs checks for price-activated features, such as
# 'Add to cart', 'Add to quote', and 'FREE' products
############

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

{ # Check pricing display on product pages
    $t->dive_reset->get_ok('/product/Test-Product-1-001-TEST1')->status_is(200)
        ->text_is('.price_large', 'FREE')
        ->element_exists_not('.price_large sup')
        ->element_exists_not('.price_large .sku')
        ->element_exists('[value="Add to cart"]')

    ->get_ok('/product/Test-Product-2-001-TEST2')->status_is(200)
        ->text_is('.price_large', 'FREE')
        ->element_exists_not('.price_large sup')
        ->element_exists_not('.price_large .sku')
        ->element_exists('[value="Add to cart"]')

    ->get_ok('/product/Test-Product-3-001-TEST3')->status_is(200)
        ->text_is('.price_large', '$42')
        ->text_is('.price_large sup', '.42')
        ->text_is('.price_large .sku', 'per each')
        ->element_exists('[value="Add to cart"]')

    ->get_ok('/product/Test-Product-4-001-TEST4')->status_is(200)
        ->text_is('.price_large', '$42')
        ->text_is('.price_large sup', '.40')
        ->text_is('.price_large .sku', 'per each')
        ->element_exists('[value="Add to cart"]')

    ->get_ok('/product/Test-Product-5-001-TEST5')->status_is(200)
        ->text_is('.price_large', '$42')
        ->text_is('.price_large sup', '.00')
        ->text_is('.price_large .sku', 'per each')
        ->element_exists('[value="Add to cart"]')

    ->get_ok('/product/Test-Product-6-001-TEST6')->status_is(200)
        ->element_exists('.quote_only')
        ->element_exists('[value="Add to quote"]')
        ->element_exists_not('.price_large')
        ->element_exists_not('.price_large sup')
        ->element_exists_not('.price_large .sku')

    ->get_ok('/product/Test-Product-7-001-TEST7')->status_is(200)
        ->element_exists('.quote_only')
        ->element_exists('[value="Add to quote"]')
        ->element_exists_not('.price_large')
        ->element_exists_not('.price_large sup')
        ->element_exists_not('.price_large .sku')
}

{ # Add products to cart and check correct display on checkout page
    for ( 1..7 ) {
        $t->get_ok("/product/Test-Product-$_-001-TEST$_");
        my $csrf = $t->tx->res->dom->at('[name=csrf_token]')->attr('value');
        $t->post_ok('/cart/add' => form => {
            csrf_token  => $csrf,
            number      => "001-TEST$_",
            quantity    => 1,
        })->status_is(200)
    }

    my $price_sel = 'td + td + td';
    my $name_sel  = 'td + td a';
    $t->dive_reset->get_ok('/cart/')->status_is(200)
        ->element_count_is('.cart  tbody tr', 5 )
        ->element_count_is('.quote tbody tr', 2 )

        ->dive_in('.cart tbody tr:first-child ')
            ->dived_text_is($name_sel, 'Test Product 1')
            ->dived_text_is($price_sel, 'FREE')
        ->dive_in('+ tr ')
            ->dived_text_is($name_sel, 'Test Product 2')
            ->dived_text_is($price_sel, 'FREE')
        ->dive_in('+ tr ')
            ->dived_text_is($name_sel, 'Test Product 3')
            ->dived_text_is($price_sel, '$42')
            ->dived_text_is("$price_sel sup", '.42')
        ->dive_in('+ tr ')
            ->dived_text_is($name_sel, 'Test Product 4')
            ->dived_text_is($price_sel, '$42')
            ->dived_text_is("$price_sel sup", '.40')
        ->dive_in('+ tr ')
            ->dived_text_is($name_sel, 'Test Product 5')
            ->dived_text_is($price_sel, '$42')
            ->dived_text_is("$price_sel sup", '.00');

    $t->dive_reset->dive_in('.quote tbody tr:first-child ')
            ->dived_text_is($name_sel, 'Test Product 6')
        ->dive_in('+ tr ')
            ->dived_text_is($name_sel, 'Test Product 7')

}

Test::XTaTIK->restore_db;

done_testing();

sub _get_test_products {
    return [
        { price => '0.00'  }, # 1
        { price => 0       }, # 2
        { price => 42.42   }, # 3
        { price => 42.4    }, # 4
        { price => 42      }, # 5
        { price => -1      }, # 6
        { price => '-1.00' }, # 7
    ];
}
