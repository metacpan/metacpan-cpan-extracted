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
    for my $idx ( 1..12 ) {
        $t->get_ok("/product/Test-Product-$idx-001-TEST$idx")
            ->status_is(200);

        my $dom = Mojo::DOM->new( $t->tx->res->body );
        my ( $csrf ) = $dom->find('[name=csrf_token]')
            ->map(qw/attr value/)->each;
        my ( $number ) = $dom->find('[name=number]')
            ->map(qw/attr value/)->each;

        $t->post_ok('/cart/add' => form => {
            csrf => $csrf,
            number => $number,
            quantity => $idx%2 ? 1 : $idx,
        });
    }

    $t->get_ok('/cart/');
    my @units = map +(/\d+\.\d+\s+(.+)/)[0], # grab all text after the price
        Mojo::DOM->new( $t->tx->res->body )
            ->find('form tbody tr')->map('all_text')->each;

    my @wanted_units = (
        'each',
        'eaches',
        'each',
        'eaches',
        'box of 5',
        'boxes of 5',
        'pair',
        'pairs',
        'case of 100',
        'cases of 100',
        'pack of 42',
        'packs of 42',
    );

    for ( 0 .. $#wanted_units ) {
        is $units[$_], $wanted_units[$_],
            "correct unit at index $_ ($wanted_units[$_])";
    }
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