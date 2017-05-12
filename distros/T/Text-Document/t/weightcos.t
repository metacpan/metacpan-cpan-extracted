
print "1..3\n";

use Text::DocumentCollection;
use Text::Document;

my $testct = 1;

my $d1 = Text::Document->new();
$d1->AddContent( ' danelle folta michelle pfeiffer ' );

my $d2 = Text::Document->new();
$d2->AddContent( ' danelle folta mary elizabeth mastrantonio ' );

my $d3 = Text::Document->new();
$d3->AddContent( 'maria grazia cucinotta mary stuart' );

my $c = Text::DocumentCollection->new( file => 't/collection.db');

$c->Add( 'a', $d1 );
$c->Add( 'b', $d2 );
$c->Add( 'c', $d3 );

# test 1 - a document is identical to itself

my $wcs = $d1->WeightedCosineSimilarity(
	$d1,
	\&Text::DocumentCollection::IDF,
	$c
);

if( abs( $wcs - 1.0 ) < 1e-6 ){
	print 'ok ' . $testct++ . "\n";
} else {
	print 'not ok ' . $testct++ . "\n";
}

# test 2 documents without words in common have similarity 0

$wcs = $d1->WeightedCosineSimilarity(
	$d3,
	\&Text::DocumentCollection::IDF,
	$c
);

if( abs( $wcs - 0.0 ) < 1e-6 ){
	print 'ok ' . $testct++ . "\n";
} else {
	print 'not ok ' . $testct++ . "\n";
}

# test 3 - compare computed similarity with a known value
# documents 2 and 3 have only the word 'mary' in common
# so we concentrate on that word.
# it occurs in 2 over 3 documents, so its IDF is log2(3/2) = 0.585
# ... 
# after several amusing steps, we find that the expected similarity
# is about 0.0.432

$wcs = $d2->WeightedCosineSimilarity(
	$d3,
	\&Text::DocumentCollection::IDF,
	$c
);

if( abs( $wcs - 0.0432 ) < 1e-4 ){
	print 'ok ' . $testct++ . "\n";
} else {
	print 'not ok ' . $testct++ . "\n";
}

unlink( 't/collection.db' );

exit 0;
