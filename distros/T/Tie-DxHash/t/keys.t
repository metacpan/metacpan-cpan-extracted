use Test::More qw(no_plan);

use Tie::DxHash;

my %dx_hash;
tie( %dx_hash, Tie::DxHash );

$dx_hash{foo} = '1';
$dx_hash{bar} = '2';
is( scalar keys %dx_hash, 2, 'keys() returns the correct number of keys' );

$dx_hash{bletch} = '3';
is( scalar keys %dx_hash, 3, 'calling keys() does not mess up the hash' );
