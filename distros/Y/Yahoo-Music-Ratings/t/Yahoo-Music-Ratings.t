use Test::More tests => 2;
BEGIN { use_ok('Yahoo::Music::Ratings') };

#########################

my $ratings = new Yahoo::Music::Ratings( { memberName => 'smolarek', progress => 0 } );
ok( defined $ratings, 'Yahoo::Music::Ratings Loaded Correctly'  );

## This next test may take a minute or two, depending on your connection speed
#my $arrayRef = $ratings->getRatings();
#is( ref($arrayRef), 'ARRAY', 'getRatings returned an ArrayRef Correctly');