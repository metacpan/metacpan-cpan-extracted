#!perl -w
use strict;
use Test::More tests => 261;

use Time::Slideshow;

my $s= Time::Slideshow->new(
    slides => [qw( slide1 slide2 slide3 )],
    duration => 5,
);

is $s->seconds_to_next_slide( 0 ), 5, "At start, we need to wait 5 seconds (duration)";
is $s->seconds_to_next_slide( 4 ), 1, "Just before the next slide, we need to wait 1 second";
is $s->current_slide( 4 ), 'slide1', "First slide";
is $s->next_slide( 4 ), 'slide2', "Second slide";
is $s->seconds_to_next_slide( 5 ), 5, "We need to wait 5 seconds with the second slide";
is $s->current_slide( 5 ), 'slide2', "After five seconds, we show the second slide";
is $s->current_slide( 10 ), 'slide3', "The slides keep advancing";
is $s->current_slide( 15 ), 'slide1', "... and cycling";

# Now check the shuffled slide sequences
my $shuffled= Time::Slideshow->new(
    slides => [qw( slide1 slide2 slide3 slide4 )],
    duration => 5,
    shuffle => 1,
);
my $ordered= Time::Slideshow->new(
    slides => [qw( slide1 slide2 slide3 slide4 )],
    duration => 5,
);

# First permutation will be the two-step loop 2-3-4-1
is $shuffled->current_slide( 4 ), 'slide2', "First 'random' slide";
is $shuffled->next_slide( 4 ), 'slide3', "Second 'random' slide is next";
is $shuffled->current_slide( 5 ), 'slide3', "After five seconds, we show the second slide";
is $shuffled->current_slide( 10 ), 'slide4', "The slides keep advancing";
is $shuffled->current_slide( 15 ), 'slide1', "The slides keep advancing further";

# Now, check that for the 24 permutations (well, some less), we always show all slides
my %cases= (
    shuffled => $shuffled,
    ordered => $ordered,
);
for my $elements (3..10) {
    my %permutations_seen;
    for my $case (sort keys %cases) {
        my $s= Time::Slideshow->new(
            slides => [1..$elements],
            duration => 5,
            shuffle => 1,
        );
        my $slides= @{ $s->slides };
        my $slide_duration= $s->duration;
        for my $permutation (0..$elements) { # Let's have some overlap
            my @order;
            my $permutation_start= $permutation * $slides * $slide_duration;
            for my $offset (0..$slides-1) {
                my $time= $permutation_start + $offset * $slide_duration;
                push @order, $s->current_slide_index( $time );
            };
            
            isn't join(",",@order), join(",",@{$s->slides}), "Shuffle permutes for $permutation";
            #isn't $order[0], 1, "We never start with the first image";
            #isn't $order[-1], $s->slides->[-1], "We never end with the last image";
            
            my %missing= map { $_ => 1 } 0..$slides -1;
            delete @missing{ @order };
            if( scalar keys %missing ) {
                fail "$case: Not all slides were shown in permutation $permutation";
                diag "Shown   " . join ",", @order;
                diag "Missing " . join ",", sort keys %missing;
                $permutations_seen{ "@order" }++;
            } else {
                pass "$case: All slides were shown in permutation $permutation";
                $permutations_seen{ "@order" }++;
            };
        };
    };
    is( (scalar keys %permutations_seen), $elements -2, "We saw all permutations for $elements")
        or do { diag $_ for sort keys %permutations_seen };
};