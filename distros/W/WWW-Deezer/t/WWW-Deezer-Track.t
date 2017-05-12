#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('WWW::Deezer::Track') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $track = new_ok('WWW::Deezer::Track');

isa_ok ($track, 'WWW::Deezer::Track');
isa_ok ($track, 'WWW::Deezer::Obj');

can_ok( $track, qw/id readable title title_short title_version unseen isrc link/ );
can_ok( $track, qw/share duration track_position disk_number rank release_date explicit_lyrics/ );
can_ok( $track, qw/preview bpm gain/ );
