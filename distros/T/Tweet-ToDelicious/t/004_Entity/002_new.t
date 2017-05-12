use v5.14;
use warnings;
use Test::More;
use t::Builder;

subtest 'on_tweet' => sub {
    my $obj = entity( {} );
    isa_ok $obj, 'Tweet::ToDelicious::Entity::OnTweet';
};

subtest 'on_event' => sub {
    my $obj = entity( { event => 'favorite' } );
    isa_ok $obj, 'Tweet::ToDelicious::Entity::OnEvent';
};

done_testing;
