
use strict;
use Test;
use XML::CuteQueries;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::CuteQueries->new;
   $CQ->parsefile("example.xml");

my $exemplar1 = Dumper([ 
    "this'll be hard to fetch I think",
    'I may need special handlers for @queries',
]);

my $exemplar2 = Dumper({ 
    a => "this'll be hard to fetch I think",
    b => 'I may need special handlers for @queries',
});

my $actual1 = Dumper( $CQ->cute_query(data=>['@a'=>'', '@b'=>'']) );
my $actual2 = Dumper( $CQ->cute_query(data=>{'@*'=>''}) );

plan tests => 4;

ok( $actual1, $exemplar1 );
ok( $actual2, $exemplar2 );

ok( $CQ->cute_query('/root/data/@a' => ''), qr(hard to fetch) );
ok( $CQ->cute_query('data/@a'       => ''), qr(hard to fetch) );
