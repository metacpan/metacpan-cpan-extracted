#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Data::Dumper;

use Test::More tests => 15;
BEGIN { use_ok('WWW::Deezer::Artist') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $artist = new_ok('WWW::Deezer::Artist');
isa_ok ($artist, 'WWW::Deezer::Obj');

$artist = new_ok('WWW::Deezer::Artist' => [744]);

can_ok ($artist, qw/id name link radio deezer_obj nb_fan nb_album tracklist/);
can_ok ($artist, qw/share picture picture_small picture_medium picture_big picture_xl/);

ok ($artist->name eq 'Nina Simone', 'Artist created correctly');

ok (! ref $artist->radio, 'Artist radio flag has correct (simple) type');

isa_ok ($artist->deezer_obj, 'WWW::Deezer', 'Artist object has deezer_obj reference');

like( $artist->picture, qr/^http/, "Artist picture is a link to (most probably) a picture" );
like( $artist->picture_small, qr/^http/, "Artist picture_small is a link to (most probably) a picture" );
like( $artist->picture_medium, qr/^http/, "Artist picture_medium is a link to (most probably) a picture" );
like( $artist->picture_big, qr/^http/, "Artist picture_big is a link to (most probably) a picture" );
like( $artist->picture_xl, qr/^http/, "Artist picture_xl is a link to (most probably) a picture" );

like( $artist->share, qr/^http/, "Artist share is an URL to (most probably) a picture" );
