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
use Mojo::DOM;

Test::XTaTIK->load_test_products( _get_test_products() );

{
    my $csrf = $t->get_ok('/login')->tx->res->dom->at('[name=csrf_token]')
        ->attr('value');

    $t->post_ok('/login' => form => {
        login => 'admin',
        pass  => 'test',
        csrf_token => $csrf,
    });

    # Rebuild search index:
    $t->post_ok('/user/site-products' => form => {
        save     => 1,
        products => "001-TEST1 58.99\n001-TEST2 158.99",
    });

    $t->get_ok("/search?term=Test")
        ->dive_in('#search_results ')
        ->element_count_is('.prod', 2, 'We have two search results')
        ->dive_in('li:first-child ')
        ->dived_text_is('a:first-child'      => 'Test Product 1')
        ->dived_text_is('+ li a:first-child' => 'Test Product 2');

    $t->get_ok("/search?term=001-TEST2")
        ->dive_reset
        ->dive_in('#search_results ')
        ->element_count_is('li', 1, 'We have only one search result')
        ->dived_text_is('li a:first-child' => 'Test Product 2');
}

Test::XTaTIK->restore_db;

done_testing();

sub _get_test_products {
    return [
        {
            unit    => 'box of 50',
            price   => 58.99,
        },
        {
            category    => '[Test Cat 1]',
            unit        => 'case of 100',
            price       => 158.99,
        },
    ];
}