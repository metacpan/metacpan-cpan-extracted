
use Test::More tests => 4;

BEGIN { use_ok('WWW::Yahoo::Movies') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $ymovie = new WWW::Yahoo::Movies(id => 'Tddfdfroy');
isa_ok($ymovie, 'WWW::Yahoo::Movies');
ok($ymovie->error == 1, 'Not Found Any Movies');
ok($ymovie->error_msg eq 'Nothing found!', 'Not Found Any Movies');
