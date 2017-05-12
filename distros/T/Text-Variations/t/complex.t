use strict;
use Test::More tests => 2;

use_ok 'Text::Variations';

my $sidekick = Text::Variations->new(
    [ 'Holy Knickerbokers', "Great Scott", "Yikes" ],
    " {{hero}}! ",
    [   "{{villan}} is getting away",
        "{{villan}} has gone too far this time",
        "you'll have to stop {{villan}} now",
    ]
);

my %results = ();

for ( 1 .. 10000 ) {
    my $dialogue = $sidekick->generate(
        {   villan => 'The Joker',
            hero   => 'Batman'
        }
    );
    $results{$dialogue}++;
}

is_deeply    #
    [ sort keys %results ],
    [
    "Great Scott Batman! The Joker has gone too far this time",
    "Great Scott Batman! The Joker is getting away",
    "Great Scott Batman! you'll have to stop The Joker now",
    "Holy Knickerbokers Batman! The Joker has gone too far this time",
    "Holy Knickerbokers Batman! The Joker is getting away",
    "Holy Knickerbokers Batman! you'll have to stop The Joker now",
    "Yikes Batman! The Joker has gone too far this time",
    "Yikes Batman! The Joker is getting away",
    "Yikes Batman! you'll have to stop The Joker now",
    ],
    "expected results";

