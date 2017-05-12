#
# Test for case if id of movie is existing
#

###########################################

use Test::More tests => 5;
BEGIN { use_ok('WWW::Yahoo::Movies') };

###########################################

my $ymovie = new WWW::Yahoo::Movies(id => '1808412033');
isa_ok($ymovie, 'WWW::Yahoo::Movies');

is($ymovie->title, 'War of the Worlds', 'Movie Title');
is($ymovie->year, 2005, 'Production Date');
is($ymovie->runtime, '116', 'Run Time');
