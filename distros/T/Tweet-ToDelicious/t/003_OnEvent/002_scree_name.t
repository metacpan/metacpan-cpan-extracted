use v5.14;
use warnings;
use Test::More;
use t::Builder;

subtest 'screen_name' => sub {
    my $entity = onevent({
        source => { screen_name => 'foo' }
    });
    is $entity->screen_name, 'foo';
};

done_testing;

