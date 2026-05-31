use Test2::V0;
use exact -nodefer;

like( dies {defer { 1 } }, qr/Can't .* method "defer"/, 'nodefer' );

done_testing;
