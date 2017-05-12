use Test::More tests => 1;
BEGIN { use_ok('WWW::UserAgent::Random') };

rand_ua();

exit(0);
