
print "1..2\n";

use Text::DocumentCollection;
use Text::Document;

unlink( 't/collection.db' );

my $d1 = Text::Document->new();
$d1->AddContent( ' danelle folta michelle pfeiffer ' );

my $d2 = Text::Document->new();
$d2->AddContent( ' danelle folta mary elizabeth mastrantonio ' );

my $c = Text::DocumentCollection->new( file => 't/collection.db');

$c->Add( 'a', $d1 );
$c->Add( 'b', $d2 );

my $d3 = Text::Document->new();
$d3->AddContent( 'claudia gerini michelle pfeiffer' );

$c->Add( 'c', $d3 );

$c = undef;

$c = Text::DocumentCollection->NewFromDB( file => 't/collection.db' );

my $idf = $c->IDF( 'folta' );

if( abs($idf-0.585) < 0.01 ){
	print "ok 1\n";
} else {
	print "not ok 1\n";
}

$idf = $c->IDF( 'michelle' ); # now idf is log2(3/2)

if( abs($idf - 0.585) < 0.01 ){
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

exit 0;
