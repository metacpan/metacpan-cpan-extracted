#!perl

use Test::More tests => 2;

BEGIN 
{ 
    use_ok( 'WWW::OReillyMedia::Store' ) || print "Bail out!"; 
    use_ok( 'WWW::OReillyMedia::Store::Book' ) || print "Bail out!";
}