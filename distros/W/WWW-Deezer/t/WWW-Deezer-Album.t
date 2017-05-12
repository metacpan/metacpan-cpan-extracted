#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('WWW::Deezer::Album') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $album = new_ok('WWW::Deezer::Album');

isa_ok ($album, 'WWW::Deezer::Album');
isa_ok ($album, 'WWW::Deezer::Obj');

can_ok( $album => qw/id title upc link genres genre_id label nb_tracks/ );
can_ok( $album => qw/cover cover_small cover_medium cover_big cover_xl/ );
can_ok( $album => qw/duration fans rating release_date record_type available/ );
