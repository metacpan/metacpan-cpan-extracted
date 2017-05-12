use v5.14;
use warnings;
use Test::More;
use t::Builder;

subtest 'is_favorite' => sub {
    my $entity = onevent( { event => 'favorite' } );
    ok $entity->is_favorite;
};

done_testing;
