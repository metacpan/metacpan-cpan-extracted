use strict;
use warnings;
use Test::More tests => 5*5 + 5*5;

use UUID::Object;

my $class = 'UUID::Object';

sub version_is {
    my ($a, $b, $desc) = @_;
    $desc = "version ${b}"  if ! defined $desc;

    my $u = $class->create_from_string($a);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is($u->version, $b, $desc);
}

my $u = $class->create_from_string('00000000-0000-0000-0000-000000000000');

$u->variant(2);

$u->version(1);
ok   $u->is_v1, 'v1 is v1';
ok ! $u->is_v2, 'v1 is not v2';
ok ! $u->is_v3, 'v1 is not v3';
ok ! $u->is_v4, 'v1 is not v4';
ok ! $u->is_v5, 'v1 is not v5';

$u->version(2);
ok ! $u->is_v1, 'v2 is not v1';
ok   $u->is_v2, 'v2 is v2';
ok ! $u->is_v3, 'v2 is not v3';
ok ! $u->is_v4, 'v2 is not v4';
ok ! $u->is_v5, 'v2 is not v5';

$u->version(3);
ok ! $u->is_v1, 'v3 is not v1';
ok ! $u->is_v2, 'v3 is not v2';
ok   $u->is_v3, 'v3 is v3';
ok ! $u->is_v4, 'v3 is not v4';
ok ! $u->is_v5, 'v3 is not v5';

$u->version(4);
ok ! $u->is_v1, 'v4 is not v1';
ok ! $u->is_v2, 'v4 is not v2';
ok ! $u->is_v3, 'v4 is not v3';
ok   $u->is_v4, 'v4 is v4';
ok ! $u->is_v5, 'v4 is not v5';

$u->version(5);
ok ! $u->is_v1, 'v5 is not v1';
ok ! $u->is_v2, 'v5 is not v2';
ok ! $u->is_v3, 'v5 is not v3';
ok ! $u->is_v4, 'v5 is not v4';
ok   $u->is_v5, 'v5 is v5';

# Note:
#     Following UUIDs are created randomly except for version field.
#     Some of them would not conform to UUID specification.

# v1
version_is '7b086c9f-339f-1def-85f3-5f78fa7c9e13', 1;
version_is '16a402a4-78dd-1432-bfb2-81bae48dfb8f', 1;
version_is '5ecd2b99-a710-134a-a2ea-08299d880f94', 1;
version_is 'ff862940-8059-109d-90f8-78aebf619749', 1;
version_is 'b5966704-03a9-1a92-8448-5c0acca27065', 1;

# v2 (DCE Security)
version_is 'a192b640-2e30-2787-b252-22bc26996143', 2;
version_is '19e759f0-ab2b-2aa8-9e2e-bc5db1015e4c', 2;
version_is '5a8db88e-0005-2ec0-8d50-e77ae6d10125', 2;
version_is '5bad6c80-92d2-28f5-8f51-4b124c793213', 2;
version_is 'ab402c95-f166-200d-a2a5-4b77f6a90e4d', 2;

# v3 (Namespace and name, MD5)
version_is 'aad5529e-8c29-3d64-ad76-9f9fea727c7f', 3;
version_is '31b5fa08-ac20-3cb9-94df-12b7fdef1927', 3;
version_is 'fbfc2f91-cba5-31e9-818c-aecc20ec873f', 3;
version_is '9f20eb1d-5bb0-3824-91c5-6cc28bc86d62', 3;
version_is '10fcb716-4edf-3d22-b6e4-918b78a84aa8', 3;

# v4 (Random)
version_is 'f7409094-ce51-49b5-b1dd-2532932242ad', 4;
version_is 'f02af41a-31a3-4f41-9dc4-4e27fd192dce', 4;
version_is 'b8a879f3-6347-411b-b650-9f3b70218110', 4;
version_is '6a9e341c-4501-45dd-8ba1-9940ac2a0db1', 4;
version_is 'bce46682-3086-4fd7-aff2-2603f4b65414', 4;

# v5 (Namespace and name, SHA-1)
version_is '17ac6fbb-7afe-55a3-a0be-365fd9f0c204', 5;
version_is 'a6ce691b-6926-5c3c-bf35-2292f84ef93b', 5;
version_is '1b7fc3c1-4d9e-59c1-9c90-618bd6d6cf80', 5;
version_is 'd32f31b8-bf4f-583a-9ad7-ac4baccba3ee', 5;
version_is '4b9ee1e2-730f-54ea-81ca-b3fa183e3796', 5;

