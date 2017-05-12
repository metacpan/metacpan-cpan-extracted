use Test::More tests => 3;

BEGIN { use_ok('Tie::Array::AsHash') };

my %hash;
my @array = qw(first:line foo:bar one:uno two:dos bar:baz last:line);

ok((tie %hash, "Tie::Array::AsHash", array => \@array, split => ":", recsep => "\n"), "tie");

ok(delete $hash{foo}, "delete");
