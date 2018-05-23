# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use strict;
use warnings;

# Should be 5.
use Test::More tests => 5;

use Text::Format;

# TEST
ok( 1, "Text::Format loaded." );

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

{
    my $text = Text::Format->new;

    my @results = $text->paragraphs( "hello world", "cool" );

    # TEST
    is( scalar(@results), 2, "2 results." );

    @results = $text->format( "hello world", "cool" );

    # TEST
    is( scalar(@results), 1, "formatting as one line." );

    @results = $text->center( "hello world", "cool" );

    # TEST
    is( scalar(@results), 2, "center()" );

    $text->columns(10);
    $text->bodyIndent(8);

    @results = $text->format( "hello world", "cool" );

    # TEST
    is( scalar(@results), 3, "columns and bodyIndent" );
}
