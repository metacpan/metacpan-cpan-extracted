#!perl

############
# This test performs checks of how free shipping setting works
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

# Set free shipping above $50
$t->app->config('text')->{shipping_free} = 50;

Test::XTaTIK->load_test_products( _get_test_products() );

{
    # First, add a cheap product. We should be charged for shipping
    _add_prod_to_cart( $t, 1 );
    _follow_checkout( $t );
    $t->text_is('.ship_chrg', '$11.30')
        ->text_is('dd.total', '$16')
        ->text_is('dd.total sup', '.95');

    # Add more expensive product; shipping must now be free
    _add_prod_to_cart( $t, 2 );
    _follow_checkout( $t );
    $t->text_is('.ship_chrg', 'FREE')
        ->text_is('dd.total', '$118')
        ->text_is('dd.total sup', '.65');
}

Test::XTaTIK->restore_db;

done_testing();

sub _add_prod_to_cart {
    my ( $t, $id ) = @_;
    $t->get_ok("/product/Test-Product-$id-001-TEST$id");
    my $csrf = $t->tx->res->dom->at('[name=csrf_token]')->attr('value');
    $t->post_ok('/cart/add' => form => {
        csrf_token  => $csrf,
        number      => "001-TEST$id",
        quantity    => 1,
    })->status_is(200);
}

sub _follow_checkout {
    my $t = shift;

    # Follow through the checkout steps
    $t->get_ok('/cart/');
    $csrf = $t->tx->res->dom->at('[name=csrf_token]')->attr('value');
    $t->post_ok('/cart/checkout' => form => {
        csrf_token  => $csrf,
        id_1        => 1,
        number_1    => '001-TEST1',
        quantity_1  => 1,
        id_2        => 2,
        number_2    => '001-TEST2',
        quantity_2  => 1,
    })->status_is(200);
    $csrf = $t->tx->res->dom->at('[name=csrf_token]')->attr('value');
    $t->post_ok('/cart/checkout-review' => form => {
        csrf_token  => $csrf,
        name        => 'name',
        lname       => 'lname',
        email       => 'example@example.com',
        phone       => 'phone',
        address1    => 'address1',
        address2    => 'address2',
        city        => 'city',
        province    => 'ON',
        zip         => '90210',
        toc         => 1,
    })->status_is(200);
}

sub _get_test_products {
    return [
        { price => 5 },
        { price => 100 },
    ];
}
