#!perl -T

use Test::More tests => 1;

BEGIN
{
    use_ok('Unix::Statgrab') || BAIL_OUT "Couldn't load Unix::Statgrab";
}

diag("Testing Unix::Statgrab $Unix::Statgrab::VERSION, Perl $], $^X");
