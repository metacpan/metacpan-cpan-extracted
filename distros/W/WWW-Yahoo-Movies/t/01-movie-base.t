use Test::More tests => 5;

use_ok('WWW::Yahoo::Movies');

my $ymovie = new WWW::Yahoo::Movies(id 			=> '1808444810',
									timeout		=> 5,
									user_agent	=> 'Opera/8.x',
								);

isa_ok($ymovie, 'WWW::Yahoo::Movies');

is($ymovie->timeout, 5, 'Timeout');
is($ymovie->user_agent, 'Opera/8.x', 'User Agent');

can_ok($ymovie, qw(mpaa_rating timeout proxy user_agent cover_file matched parse_page));
