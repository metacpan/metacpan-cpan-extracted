use Test::More tests => 3;

BEGIN { use_ok('Tie::Array::AsHash') };

my %hash;

my @array = qw(first:line foo:bar one:uno two:dos bar:baz last:line);
my @vals = qw/line bar uno dos baz line/;

ok((tie %hash, "Tie::Array::AsHash", array => \@array, split => ":", recsep => "\n"), "tie");

my @vals_from_testfile = values %hash;

# yes, vals are in order, though that may change
ok("@vals" eq "@vals_from_testfile");
