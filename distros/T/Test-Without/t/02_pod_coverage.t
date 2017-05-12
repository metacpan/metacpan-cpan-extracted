#!/usr/bin/perl

# Test that the syntax of our POD documentation is valid
use strict;
BEGIN
{
    $|  = 1;
    $^W = 1;

    use Test::More;
    unless ($ENV{AUTHOR_TESTING})
    {
        plan skip_all => "Author tests not required for installation";
    }
    else
    {
        eval "use Test::Pod::Coverage;";
    }
}

all_pod_coverage_ok();

exit;
