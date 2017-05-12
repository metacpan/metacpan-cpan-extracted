#!/usr/bin/perl

# Test that our declared minimum Perl version matches our syntax
use strict;
BEGIN
{
    $|  = 1;
    $^W = 1;

    use Test::More;
    unless ($ENV{AUTHOR_TESTING})
    {
        plan( skip_all => "Author tests not required for installation" );
    }
    else
    {
        eval "use Perl::MinimumVersion;";
        eval "use Test::MinimumVersion;";
    }
}

all_minimum_version_from_metayml_ok();

exit;
