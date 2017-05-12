
print "1..3\n";

use Text::DocumentCollection;
use Text::Document;

my $d1 = Text::Document->new();
$d1->AddContent( ' danelle folta michelle pfeiffer ' );

my $d2 = Text::Document->new();
$d2->AddContent( ' danelle folta mary elizabeth mastrantonio ' );

my $c = Text::DocumentCollection->new( file => 't/collection.db');

$c->Add( 'a', $d1 );
$c->Add( 'b', $d2 );

my $idf = $c->IDF( 'folta' );

if( $idf == 0 ){
	print "ok 1\n";
} else {
	print "not ok 1\n";
}

$idf = $c->IDF( 'michelle' );

if( abs($idf - 1) < 1e-6 ){
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

my $d3 = Text::Document->new();
$d3->AddContent( 'claudia gerini michelle pfeiffer' );

$c->Add( 'c', $d3 );

$idf = $c->IDF( 'michelle' ); # now idf is log2(3/2)

if( abs($idf - 0.585) < 0.01 ){
	print "ok 3\n";
} else {
	print "not ok 3\n";
}

undef($c);

unlink( 't/collection.db');

exit 0;
