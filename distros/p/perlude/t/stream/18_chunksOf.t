#! /usr/bin/perl
use 5.010;
use strict;
use warnings;
use Test::More 'no_plan';
use Perlude;

# this is the reference: don't touch it
# because chunksOf means to preserve the content of the original array 

my @reference = 'a'..'f'; # alpha symbols of hexadecimal base

# this is the copy of the reference array!
my @source    = @reference;

my $got = chunksOf 3, \@source;

# what we expect $got to produce
my @expect = 
( [ qw[ a b c ]]
, [ qw[ d e f ]] );

now {
    state $counter = 0;
    $counter++;

    @expect or BAIL_OUT
        ( "the ${counter}th call to chunksOf wasn't expected. it contains "
        . join ',',@$_ );

    my $e = shift @expect;

    is_deeply $e, $_
    , "row $counter is expected";

} $got;

ok
( (0 == @expect)
, 'chunksOf finish the job' );

my @unused = fold $got;
ok
( (0 == @unused)
, 'chunksOf dont send extra stuff' );


