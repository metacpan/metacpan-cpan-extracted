use Test::More tests => ($] >= 5.008003 ? 4 : 3);

BEGIN { use_ok('Tie::File::AsHash') };

my %hash;

ok((my $obj = tie %hash, "Tie::File::AsHash", "t/testfile", split => ":", recsep => "\n"), "tie");

# 6 lines in the file
ok($obj->SCALAR() == 6, "scalar");

if ($] >= 5.008003) {
  ok(scalar %hash == 6, "scalar");
}
