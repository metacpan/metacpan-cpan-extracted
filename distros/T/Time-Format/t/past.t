
# Test cases for bug reported by Will "Coke" Coleda

use strict;
use Test::More;
use Time::Format;

my $have_module = eval { require 'DateTime::Format::ISO8601'; 1; };


# Input string, output string
my @tuples = (
              ['2009-04-15T01:58:17.010760Z', 'April 15, 2009 @ 1:58'],
              ['2009-04-15T13:58:17.010760Z', 'April 15, 2009 @ 1:58'],
             );

# The above array contains all of the tests this unit will run.
my $num_tests = 2 * scalar(@tuples);
plan tests => $num_tests;

SKIP:
{
    skip 'DateTime::Format::ISO8601 required for this test', $num_tests
        unless $have_module;

    my $time_format = 'Month d, yyyy @ H:mm';

    my $index = 0;
    foreach my $pair (@tuples)
    {
        my ($input, $expected) = @$pair;
        my $dt = DateTime::Format::ISO8601->parse_datetime($input);

        is $time{$time_format,       $dt}, $expected, "Test case $index (hash)";
        is time_format($time_format, $dt), $expected, "Test case $index (func)";
        ++$index;
    }
}

