use Test::More tests => 3;

BEGIN { use_ok('Tie::Array::AsHash') };

my %hash;

my @array = qw(first:line foo:bar one:uno two:dos bar:baz last:line);
my @keys = qw/first foo one two bar last/;

ok((tie %hash, "Tie::Array::AsHash", array => \@array, split => ":", recsep => "\n"), "tie");

my @keys_from_testfile = keys %hash;

# yes, keys are in order, though that may change
ok("@keys" eq "@keys_from_testfile");
