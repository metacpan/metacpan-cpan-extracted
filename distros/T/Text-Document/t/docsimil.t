
use Text::Document;

print "1..6\n";

# this doc has coordinates (1,0) in the space
# {danelle} x {elizabeth}
$d = Text::Document->new();
$d->AddContent( 'danelle' );

# this doc has coordinates (1,1) in the space
# {danelle} x {elizabeth}
my $e = Text::Document->new();
$e->AddContent( 'danelle elizabeth' );

# their cosine should be sqrt(2)/2
my $r = $d->CosineSimilarity( $e );

if( abs( $r - 0.707 ) < 1e-3 ){
	print "ok 1\n";
} else {
	print "not ok 1\n";
}

# test symmetry

my $rAlt = $e->CosineSimilarity( $d );
if( abs( $r - $rAlt ) < 1e-6 ){
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

# test reflexivity on a more complex doc
my $complex = Text::Document->new();
$complex->AddContent( 'foo bar baz foo foo bar Foo barbaz' );
$r = $complex->CosineSimilarity( $complex );
if( abs( $r - 1.0 ) < 1e-6 ){
	print "ok 3\n";
} else {
	print "not ok 3\n";
}

# compute the same for Jaccard similarity
# since one document has both keywords and the other
# just one, we should find 0.5

$r = $d->JaccardSimilarity( $e );

if( abs( $r - 0.5 ) < 1e-3 ){
	print "ok 4\n";
} else {
	print "not ok 4\n";
}

$rAlt = $e->JaccardSimilarity( $d );
if( abs( $r - $rAlt ) < 1e-6 ){
	print "ok 5\n";
} else {
	print "not ok 5\n";
}

# test reflexivity on a more complex doc
$r = $complex->JaccardSimilarity( $complex );
if( abs( $r - 1.0 ) < 1e-6 ){
	print "ok 6\n";
} else {
	print "not ok 6\n";
}
exit 0;
