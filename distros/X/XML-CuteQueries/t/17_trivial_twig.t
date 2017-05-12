
use strict;
use Test;
use XML::CuteQueries;

my $CQ = XML::CuteQueries->new->parse("<r><x>1</x><y>2</y></r>");

plan tests=>2;

my @a = map {$_->gi . $_->xml_string} $CQ->cute_query('*'=>'t');
ok( "@a", "x1 y2" );

my @b = $CQ->cute_query('*'=>'t');
$_->set_tag('h1') for @b;
$CQ->root->set_tag("html");

ok( $CQ->root->sprint, "<html><h1>1</h1><h1>2</h1></html>" );
