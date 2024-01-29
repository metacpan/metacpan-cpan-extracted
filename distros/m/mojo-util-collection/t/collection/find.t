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

my $user_1 = $collection->find(1);

is($user_1->first_name, 'Joe');

my $user_2 = $collection->find({ first_name => 'Joe' });

is($user_2->first_name, 'Joe');

done_testing();
