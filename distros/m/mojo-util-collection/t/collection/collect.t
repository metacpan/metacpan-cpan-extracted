#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Mojo::Util::Collection qw(collect);
use Mojo::Util::Model::User;

my $collection = collect([
    { id => 1, fist_name => 'Joe', last_name => 'Smith' },
    { id => 2, fist_name => 'Jane', last_name => 'Smith' },
    { id => 3, fist_name => 'Joe', last_name => 'Doe' },
    { id => 4, fist_name => 'Jane', last_name => 'Doe' },
    { id => 5, fist_name => 'Joe', last_name => 'Public' },
    { id => 6, fist_name => 'Jane', last_name => 'Public' },
]);

isa_ok($collection, 'Mojo::Util::Collection');
isa_ok($collection->first, 'Mojo::Util::Model');

my $collection_as = collect([
    { id => 1, fist_name => 'Joe', last_name => 'Smith' },
    { id => 2, fist_name => 'Jane', last_name => 'Smith' },
    { id => 3, fist_name => 'Joe', last_name => 'Doe' },
    { id => 4, fist_name => 'Jane', last_name => 'Doe' },
    { id => 5, fist_name => 'Joe', last_name => 'Public' },
    { id => 6, fist_name => 'Jane', last_name => 'Public' },
])->as(sub { Mojo::Util::Model::User->new(@_) });

isa_ok($collection_as, 'Mojo::Util::Collection');
isa_ok($collection_as->first, 'Mojo::Util::Model::User');

done_testing();
