package t::Builder;

use v5.14;
use warnings;
use parent 'Exporter';
use Tweet::ToDelicious::Entity;
use Tweet::ToDelicious::Entity::OnTweet;
use Tweet::ToDelicious::Entity::OnEvent;

our @EXPORT = qw(ontweet onevent entity);

sub ontweet {
    Tweet::ToDelicious::Entity::OnTweet->new(shift)
}

sub onevent {
    Tweet::ToDelicious::Entity::OnEvent->new(shift)
}

sub entity {
    Tweet::ToDelicious::Entity->new(shift)
}

1;
