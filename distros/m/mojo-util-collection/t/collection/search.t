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

is($collection->count, 4);

is($collection->search({ first_name => 'Joe' })->count, 1);
is($collection->search({ first_name => 'Missing' })->count, 0);
is($collection->search({ first_name => { like => 'Jo' } })->count, 2);
is($collection->search({ first_name => { match => 'Ja' } })->count, 1);

is($collection->search({ age => 19 })->count, 1);
is($collection->search({ age => { eq => 19 } })->count, 1);
is($collection->search({ age => { '==' => 19 } })->count, 1);
is($collection->search({ age => { gt => 20 } })->count, 3);
is($collection->search({ age => { '>' => 20 } })->count, 3);
is($collection->search({ age => { ge => 22 } })->count, 2);
is($collection->search({ age => { '>=' => 22 } })->count, 2);
is($collection->search({ age => { lt => 20 } })->count, 1);
is($collection->search({ age => { '<' => 20 } })->count, 1);
is($collection->search({ age => { le => 21 } })->count, 2);
is($collection->search({ age => { '<=' => 21 } })->count, 2);
is($collection->search({ age => { '!=' => 21 } })->count, 3);
is($collection->search({ age => { between => [19, 22] } })->count, 1);
is($collection->search({ age => { gt => 19, lt => 22 } })->count, 1);
is($collection->search({ age => { between => [18, 23] } })->count, 3);
is($collection->search({ age => { gt => 18, lt => 23 } })->count, 3);
is($collection->search({ age => [19, 21] })->count, 2);
is($collection->search({ age => { in => [19, 21] } })->count, 2);

done_testing();
