
use Text::Document;

print "1..5\n";

my $d = Text::Document->new();
$d->AddContent( 'danelle folta  michelle pfeiffer' );

my $d2 = Text::Document->new();
$d2->AddContent( 'mary elizabeth mastrantonio danelle folta' );

my $r = $d->JaccardSimilarity( $d2 );

# ratio is 2 / 7

if( abs( $r - 2.0/7 ) < 1e-6 ){
	print "ok 1\n";
} else {
	print "not ok 1\n";
}

my $d3 = Text::Document->new();
$d3->AddContent( 'katherine hepburn' );

if( $d->JaccardSimilarity( $d3 ) == 0.0 ){
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

$r = $d->JaccardSimilarity( $d );
if( $r == 1.0 ){
	print "ok 3\n";
} else {
	print "not ok 3\n";
}

my $str = $d->WriteToString();
# my $d4 = Text::Document->new();
my $d4 = Text::Document::NewFromString( $str );

$r = $d->JaccardSimilarity( $d4 );
if( $r == 1.0 ){
	print "ok 4\n";
} else {
	print "not ok 4\n";
}

# test immunity to case, punctuation and newlines
$d4 = Text::Document->new();
$d4->AddContent( "Danelle--FoLta,
Michelle!!!!Pfeiffer()" );

$r = $d->JaccardSimilarity( $d4 );
if( $r == 1.0 ){
	print "ok 5\n";
} else {
	print "not ok 5\n";
}


exit 0;
