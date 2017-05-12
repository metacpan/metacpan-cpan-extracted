use Test::More tests => 17;
BEGIN { use_ok('WWW::Bleep') };

my $bleep;
my %album;
my @artists;
my @tracks;

ok( $bleep = WWW::Bleep->new(), 'Initial Declaration' );

# Validate album call
ok( %album = $bleep->album( cat => 'WARP43' ), 'Catalog Album Lookup' );
is( $bleep->error(), '' , 'Album Error' ) or
	diag( 'Test album could not be found...  Is your internet connection on?' );

# Validate album return
is( $album{artist}, 'Aphex Twin', 'Album Artist' );
is( $album{date}, '11/1996', 'Album Date' );
is( $album{label}, 'Warp', 'Album Label' );
is( $album{title}, 'Richard D. James', 'Album Title' );
is( $album{tracks}->{"06"}{time}, '4:04', 'Track Time' );
is( $album{tracks}->{"06"}{title}, 'To Cure A Weakling Child', 'Track Title' );
is( $album{tracks}->{"06"}{valid}, 1, 'Track Valid' );

# Validate artist lookup
ok( @artists = $bleep->artists(label => 'Warp'), 'Artists List' );
is( $artists[0], '!!!', 'Specific Artist' );
is( $bleep->error(), '' , 'Artists Error' );

#Validate track lookup
ok( @tracks = $bleep->tracks(artist => 'Aphex Twin') );
is( $tracks[0]{title}, '4', 'Specific Track' );
is( $bleep->error(), '', 'Track Error' );
