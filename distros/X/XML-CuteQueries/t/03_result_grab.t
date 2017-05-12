
use strict;
use Test;
use XML::CuteQueries;

my $CQ = XML::CuteQueries->new;
   $CQ->parsefile("example.xml");

plan tests => 1;

ok( $CQ->cute_query(result=>''), 'OK' );
