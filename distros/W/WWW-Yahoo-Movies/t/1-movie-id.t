#
# Test for case if id of movie is existing
#

###########################################

use Test::More tests => 10;
BEGIN { use_ok('WWW::Yahoo::Movies') };

###########################################

my $ymovie = new WWW::Yahoo::Movies(id => '1808444810');
isa_ok($ymovie, 'WWW::Yahoo::Movies');

is($ymovie->title, 'Troy', 'Movie Title');
is($ymovie->year, 2004, 'Production Date');
is($ymovie->runtime, '162', 'Run Time');
#is($ymovie->distributor, 'Warner Bros', 'Disrtibutor');

is($ymovie->mpaa_rating, 'R', 'MPAA Rating Code');

my($code, $descr) = $ymovie->mpaa_rating();

is($descr, 'for graphic violence and some sexuality/nudity.', 'MPAA Rating Description');

is($ymovie->cover_file, 'troy_dvdcover.jpg', 'Cover File');
is($ymovie->release_date, '14 May 2004', 'Release Date');

is_deeply($ymovie->genres, ['Action', 'Adventure'], 'Genres');
