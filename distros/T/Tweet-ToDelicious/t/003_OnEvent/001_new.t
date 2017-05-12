use v5.14;
use warnings;
use Test::More;
use Tweet::ToDelicious::Entity::OnEvent;

subtest 'new' => sub {
    new_ok 'Tweet::ToDelicious::Entity::OnEvent';
};

done_testing;
