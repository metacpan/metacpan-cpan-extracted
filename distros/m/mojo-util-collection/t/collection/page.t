#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Mojo::Util::Collection;
use Mojo::Util::Model::User;

my $collection = Mojo::Util::Collection->new(
    items => [
        {
            id         => 1,
            first_name => 'Joe',
            last_name  => 'Doe',
            age        => 19
        },
        {
            id         => 2,
            first_name => 'Jane',
            last_name  => 'Doe',
            age        => 21
        },
        {
            id         => 3,
            first_name => 'John',
            last_name  => 'Doe',
            age        => 22
        },
        {
            id         => 4,
            first_name => 'Jill',
            last_name  => 'Doe',
            age        => 23
        },
    ],
    model => Mojo::Util::Model::User->new
);

$collection->limit(2);

my $page = $collection->page(1);

is_deeply($page->only('id'), [ { id => 1 }, { id => 2 } ], 'page 1');
is_deeply($page->pager, {
    'next_page' => 2,
    'end' => 2,
    'count' => 4,
    'first_page' => 1,
    'start' => 1,
    'page' => 1,
    'prev_page' => 1,
    'limit' => 2,
    'last_page' => 2
}, 'page 1 pager');

$page = $collection->page(2);

is_deeply($page->only('id'), [ { id => 3 }, { id => 4 } ], 'page 2');
is_deeply($page->pager, {
    'next_page' => 2,
    'end' => 4,
    'count' => 4,
    'first_page' => 1,
    'start' => 3,
    'page' => 2,
    'prev_page' => 1,
    'limit' => 2,
    'last_page' => 2
}, 'page 2 pager');

$page = $collection->page(3);

is_deeply($page->only('id'), [], 'page 3');
is_deeply($page->pager, {
    'next_page' => 2,
    'end' => 4,
    'count' => 4,
    'first_page' => 1,
    'start' => 5,
    'page' => 3,
    'prev_page' => 2,
    'limit' => 2,
    'last_page' => 2
}, 'page 3 pager');

done_testing();
