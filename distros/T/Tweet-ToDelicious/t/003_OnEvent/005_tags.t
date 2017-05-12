use v5.14;
use warnings;
use Test::More;
use t::Builder;

subtest 'tags' => sub {
    my $entity = onevent({});
    my @tags = $entity->tags;
    is_deeply \@tags, ['favorite', 'via:tweet2delicious'];

};

done_testing;
