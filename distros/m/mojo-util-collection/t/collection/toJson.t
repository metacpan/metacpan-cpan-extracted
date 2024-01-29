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

is($collection->toJson(), '[{"age":19,"exists":1,"first_name":"Joe","id":1,"last_name":"Doe","pk":1,"primary_key":"id"},{"age":21,"exists":1,"first_name":"Jane","id":2,"last_name":"Doe","pk":2,"primary_key":"id"},{"age":22,"exists":1,"first_name":"John","id":3,"last_name":"Doe","pk":3,"primary_key":"id"},{"age":23,"exists":1,"first_name":"Jill","id":4,"last_name":"Doe","pk":4,"primary_key":"id"}]');
is($collection->toJson('id', 'full_name'), '[{"full_name":"Joe Doe","id":1},{"full_name":"Jane Doe","id":2},{"full_name":"John Doe","id":3},{"full_name":"Jill Doe","id":4}]');

done_testing();
