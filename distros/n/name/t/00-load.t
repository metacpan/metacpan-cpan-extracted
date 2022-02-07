use 5.008;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'name', 'foo', alias => 'bar' or print "Bail out!\n";
}

diag "Testing name $name::VERSION, Perl $], $^X" ;

done_testing;
