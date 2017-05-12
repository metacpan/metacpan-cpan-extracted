use Test::More tests => 4;

BEGIN { use_ok('Tie::File::AsHash') };

# make sure the test file exists
ok(-e "t/testfile", "testfile that is used by the various tests");

my %hash;

ok((tie %hash, "Tie::File::AsHash", "t/testfile", split => ":", recsep => "\n"), "tie");

ok($hash{foo} eq "bar", "fetch");
