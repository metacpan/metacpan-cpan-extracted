#!/usr/bin/perl -w

use Text::NLP;
        
my $talker = Text::NLP->new;
    
# setup the seeding
my $args = {
	HELLO   => [ 'hi', 'hello', 'good day' ],
	BYE     => [ 'bye', 'goodbye', 'laters' ],
};

$talker->addSeeding( $args );
    
my $string = 'Should I say goodbye or hello? I\'ll just say good day';
    
# process the string
my $words = $talker->process( $string );

# do some post-processing
use Data::Dumper; print Dumper( $words );
