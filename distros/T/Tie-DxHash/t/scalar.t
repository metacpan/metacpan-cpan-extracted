use Test::More tests => 2;

use Tie::DxHash;

my %dx_hash;
tie( %dx_hash, Tie::DxHash );

is( scalar %dx_hash,
    0, 'scalar %dx_hash returns zero for an empty tied hash' );

$dx_hash{foo} = '1';
$dx_hash{bar} = '2';
$dx_hash{bar} = '3';
is( scalar %dx_hash, 3,
    'scalar %dx_hash returns the correct number of keys' );
