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

{   # Showing by default
    $t->get_ok('/')
        ->element_exists('#hot_products')
        ->dive_in('#hot_products')
        ->element_count_is('> li', 3)
        ->element_exists('a[href="/product/Test-Product-1-001-TEST1"]')
        ->element_exists('a[href="/product/Test-Product-3-001-TEST3"]')
        ->element_exists('a[href="/product/Test-Product-6-001-TEST6"]');
}

{   # change hot products using admin interface
    $t->post_ok('/login', form => { login => 'admin', pass => 'test'} )
        ->get_ok('/user/hot-products')
        ->text_is('textarea', "001-TEST1\n001-TEST3\n001-TEST6")
        ->post_ok('/user/hot-products', form => {
            hot_products => '  001-TEST3  001-TEST2  ',
        })
        ->get_ok('/user/hot-products')
        ->text_is('textarea', "001-TEST3\n001-TEST2")
}

{   # Check that the change indeed occured
    $t->get_ok('/')
        ->element_exists('#hot_products')
        ->dive_in('#hot_products')
        ->element_count_is('> li', 2)
        ->element_exists('a[href="/product/Test-Product-3-001-TEST3"]')
        ->element_exists('a[href="/product/Test-Product-2-001-TEST2"]')
}

Test::XTaTIK->restore_db;

done_testing();

sub _get_test_products {
    return [
        {
            number              => '001-TEST1',
            image               => '',
            title               => 'Test Product 1',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => '',
            description         => 'Test Desc 1',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST2',
            image               => '',
            title               => 'Test Product 2',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => '',
            description         => 'Test Desc 2',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST3',
            image               => '',
            title               => 'Test Product 3',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => 'each',
            description         => 'Test Desc 3',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST4',
            image               => '',
            title               => 'Test Product 4',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => 'each',
            description         => 'Test Desc 4',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST5',
            image               => '',
            title               => 'Test Product 5',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => 'box of 5',
            description         => 'Test Desc 5',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST6',
            image               => '',
            title               => 'Test Product 6',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => 'box of 5',
            description         => 'Test Desc 6',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST7',
            image               => '',
            title               => 'Test Product 7',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => 'pair',
            description         => 'Test Desc 7',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST8',
            image               => '',
            title               => 'Test Product 8',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => 'pair',
            description         => 'Test Desc 8',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST9',
            image               => '',
            title               => 'Test Product 9',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => 'case of 100',
            description         => 'Test Desc 9',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST10',
            image               => '',
            title               => 'Test Product 10',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => 'case of 100',
            description         => 'Test Desc 10',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST11',
            image               => '',
            title               => 'Test Product 11',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => 'pack of 42',
            description         => 'Test Desc 11',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST12',
            image               => '',
            title               => 'Test Product 12',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => 'pack of 42',
            description         => 'Test Desc 12',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
    ];
}