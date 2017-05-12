use Test::More tests => 3;

BEGIN { use_ok('Tie::File::AsHash') };

my %hash;

my @vals = qw/line bar uno dos baz line/;

ok((tie %hash, "Tie::File::AsHash", "t/testfile", split => ":", recsep => "\n"), "tie");

my @vals_from_testfile = values %hash;

# yes, vals are in order, though that may change
ok("@vals" eq "@vals_from_testfile");
