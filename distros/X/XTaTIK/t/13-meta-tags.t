#!perl

############
# This test performs checks that <title> elements get correctly
# Updated when viewing products and shop categories
############

use Test::Most;

unless ( $ENV{XTATIK_TESTING} ) {
    diag 'Set XTATIK_TESTING env var to true, to run the tests';
    ok 1; done_testing; exit;
}

use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new('XTaTIK');

use lib 't';
eval 'use Test::XTaTIK';

$t->app->xtext( market => 'Widgets' );
$t->app->xtext( products_nav_name => 'Shop' );

Test::XTaTIK->load_test_products( _get_test_products() );

{
    $t->dive_reset->get_ok('/')->status_is(200)
    ->element_exists('meta[content="Widgets"]')

    ->get_ok('/about')->status_is(200)
    ->element_exists('meta[content="About / Widgets"]')

    ->get_ok('/products')->status_is(200)
    ->element_exists('meta[content="Shop, Widgets"]')

    ->get_ok('/products/Test Cat 1')->status_is(200)
    ->element_exists('meta[content="Test Cat 1, Widgets"]')

    ->get_ok('/products/Test Cat 1/Test SubCat 2')->status_is(200)
    ->element_exists('meta[content="Test SubCat 2, Test Cat 1, Widgets"]')

    ->get_ok('/products/Test Cat 1/Test SubCat 2/Test SubSubCat 1')
        ->status_is(200)
   ->element_exists('meta[content="Test SubSubCat 1, Test SubCat 2, Widgets"]')

    ->get_ok('/product/Test-Product-1-001-TEST1')->status_is(200)
    ->element_exists('meta[content="Just some group desc;'
        . ' foo bar baz Some other desc"]')

}

Test::XTaTIK->restore_db;

done_testing();

sub _get_test_products {
    return [
        {
            category => '[]',
            group_desc => 'Just some group desc',
            description => <<'END',
* foo
* bar
* baz

Some other desc
END
        },
        { category => '[Test Cat 1]', },
        { category => '[Test Cat 1*::*Test SubCat 2]', },
        { category => '[Test Cat 1*::*Test SubCat 2'
                                    . '*::*Test SubSubCat 1]', },
    ];
}
