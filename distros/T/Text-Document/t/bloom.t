
use Text::Bloom;

print "1..6\n";

# 1 : test collision ratio

my $b = Text::Bloom->new();

$b->Compute( qw( foo bar baz ) );

if( $b->{collisionRatio} == 0 ){
	print "ok 1\n";
} else {
	print "not ok 1\n";
}

my $sim = $b->Similarity( $b );

if( $sim == 1 ){
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

my $b2 = Text::Bloom->new();
$b2->Compute( qw( danelle folta michelle pfeiffer ) );

if( $b->Similarity( $b2 ) == 0 ){
	print "ok 3\n";
} else {
	print "not ok 3\n";
}

	
my $b3 = Text::Bloom->new();
$b3->Compute( qw( danelle folta mary elizabeth mastrantonio ) );

if( abs( $b3->Similarity( $b2 ) - 2.0/7.0) < 1e-6 ){
	print "ok 4\n";
} else {
	print "not ok 4\n";
}

my $str = $b3->WriteToString();
# my $b4 = Text::Bloom->new();
my $b4 = Text::Bloom::NewFromString( $str );

if( $b3->Similarity( $b4 ) ){
	print "ok 5\n";
} else {
	print "not ok 5\n";
}

$b2->WriteToFile('afile.sig');
# my $b5 = Text::Bloom->new();
my $b5 = Text::Bloom::NewFromFile( 'afile.sig' );

unlink 'afile.sig';

if( $b2->Similarity( $b5 ) ){
	print "ok 6\n";
} else {
	print "not ok 6\n";
}

exit(0);
