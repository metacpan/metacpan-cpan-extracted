use Test::More tests => ($] >= 5.008003 ? 4 : 3);

BEGIN { use_ok('Tie::Array::AsHash') };

my %hash;
my @array = qw(first:line foo:bar one:uno two:dos bar:baz last:line);

ok((my $obj = tie %hash, "Tie::Array::AsHash", array => \@array, split => ":", recsep => "\n"), "tie");

# 6 lines in the file
ok($obj->SCALAR() == 6, "scalar");

if ($] >= 5.008003) {
  ok(scalar %hash == 6, "scalar");
}
