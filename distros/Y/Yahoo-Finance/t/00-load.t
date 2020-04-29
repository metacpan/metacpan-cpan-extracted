#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Yahoo::Finance;

BEGIN {
    use_ok( 'Yahoo::Finance' ) || print "Bail out!\n";
}

diag( "Testing Yahoo::Finance $Yahoo::Finance::VERSION, Perl $], $^X" );

{
    no warnings 'redefine';
 
    local *Yahoo::Finance::get_historic_data = sub { 1 };

    my $result = get_historic_data({symbol => 'GOLD'});

    ok($result,"non oo test done");

}

{
    no warnings 'redefine';

    local *Yahoo::Finance::get_historic_data = sub { 1 };

    my $fin = Yahoo::Finance->new();

    my $result = $fin->get_historic_data({symbol => 'GOLD'});

    ok($result,"oo test done");

}

{
    my $finance = Yahoo::Finance->new();
 
    is($finance->VERSION,'0.01','Version test');
 
}

done_testing();

1;