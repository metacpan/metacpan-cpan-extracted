#
#
# Test for case searching movie by its title
#
#

#########################

use Test::More tests => 7;
BEGIN { use_ok('WWW::Yahoo::Movies') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $ymovie = new WWW::Yahoo::Movies(id => 'Troy');
isa_ok($ymovie, 'WWW::Yahoo::Movies');

is($ymovie->title, 'Troy', 'Movie Title');
is($ymovie->year, 2004, 'Production Date');
cmp_ok(scalar(@{$ymovie->matched}), '>', 1, 'Search Results');

$ymovie = new WWW::Yahoo::Movies(id => 'Get Carter');
is($ymovie->title, 'Get Carter', 'Movie Title');

$ymovie = new WWW::Yahoo::Movies(id => '300');
is($ymovie->title, '300', 'Movie Title');
