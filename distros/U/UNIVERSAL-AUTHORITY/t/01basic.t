use Test::More tests => 2;
BEGIN { use_ok('UNIVERSAL::AUTHORITY') };
can_ok(UNIVERSAL => AUTHORITY);
