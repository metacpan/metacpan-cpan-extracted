
use Test::More tests => 24;

use lib 'lib';

use Text::NSR;

my $nsr = Text::NSR->new( filepath => 't/test.nsr' );

my $records = $nsr->read();

use Data::Dumper;

print Dumper $records;

is( scalar(@$records), 8, "parsing test file without fieldspec returns 8 entries");

is( ref($records->[0]), 'ARRAY', "record 0 is an array");
is( scalar(@{$records->[0]}), 4, "record 0 array has 4 keys");
is( scalar(@{$records->[1]}), 4, "record 1 array has 4 keys");
is( scalar(@{$records->[2]}), 4, "record 2 array has 4 keys");
is( scalar(@{$records->[3]}), 5, "record 3 array has 5 keys");
is( scalar(@{$records->[4]}), 4, "record 4 array has 4 keys");
is( scalar(@{$records->[5]}), 3, "record 5 array has 3 keys");
is( scalar(@{$records->[6]}), 4, "record 6 array has 4 keys");
is( scalar(@{$records->[7]}), 4, "record 7 array has 4 keys");

like( $records->[3]->[0], qr/^D1 /, "record sample: D1");
like( $records->[3]->[2], qr/^D3/, "record sample: D3");
like( $records->[3]->[4], qr/^D5 /, "record sample: D5");


$nsr = Text::NSR->new(filepath => 't/test.nsr', fieldspec => ['f1','f2','f3','f4'] );

$records = $nsr->read();

is( scalar(@$records), 8, "parsing test file with fieldspec returns 8 entries");

is( ref($records->[0]), 'HASH', "record 0 is a hash");
is( scalar(keys %{$records->[0]}), 4, "record 0 hash has 4 keys");
is( scalar(keys %{$records->[1]}), 4, "record 1 hash has 4 keys");
is( scalar(keys %{$records->[2]}), 4, "record 2 hash has 4 keys");
is( scalar(keys %{$records->[3]}), 5, "record 3 hash has 5 keys");
is( scalar(keys %{$records->[4]}), 4, "record 4 hash has 4 keys");
is( scalar(keys %{$records->[5]}), 3, "record 5 hash has 3 keys");
is( scalar(keys %{$records->[6]}), 4, "record 6 hash has 4 keys");
is( scalar(keys %{$records->[7]}), 4, "record 7 hash has 4 keys");

is( index($records->[7]->{f1}, "\n"), 27, "Literal newline converted?");


