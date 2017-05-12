use Test::More tests => 3;

BEGIN { use_ok('Tie::File::AsHash') };

my %hash;

ok((tie %hash, "Tie::File::AsHash", "t/testfile", split => ":", recsep => "\n"), "tie");

ok(exists $hash{foo}, "exists");
