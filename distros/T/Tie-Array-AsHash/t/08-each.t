use Test::More tests => 3;

BEGIN { use_ok('Tie::Array::AsHash') };

my %hash;

my @array = qw(first:line foo:bar one:uno two:dos bar:baz last:line);
my @vals = qw/line bar uno dos bar line/;

ok((my $obj = tie %hash, "Tie::Array::AsHash", array => \@array, split => ":", recsep => "\n"), "tie");

my $vals = 0;

while (my ($key, $val) = each %hash)
{
	$vals++;
}

# yes, hashes are in same order, though that may change
ok($vals == $obj->SCALAR());
