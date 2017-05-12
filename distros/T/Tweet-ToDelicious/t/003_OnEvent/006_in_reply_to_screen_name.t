use v5.14;
use warnings;
use Test::More;
use t::Builder;

subtest 'in_reply_to_screen_name' => sub {
    my $entity = onevent(
        { target_object => { in_reply_to_screen_name => 'foo' } } );
    is $entity->in_reply_to_screen_name, 'foo';

};

done_testing;

