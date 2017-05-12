package Tweet::ToDelicious::Entity;

use v5.14;
use warnings;
use Tweet::ToDelicious::Entity::OnTweet;
use Tweet::ToDelicious::Entity::OnEvent;

sub new {
    my $class = shift;
    my $tweet = shift;
    if ( exists $tweet->{event} ) {
        return Tweet::ToDelicious::Entity::OnEvent->new($tweet);
    }
    else {
        return Tweet::ToDelicious::Entity::OnTweet->new($tweet);
    }
}

1;
