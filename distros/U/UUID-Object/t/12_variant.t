use strict;
use warnings;
use Test::More tests => 5*4;

use UUID::Object;

my $class = 'UUID::Object';

sub variant_is {
    my ($a, $b, $desc) = @_;
    $desc = "variant ${b}"  if ! defined $desc;

    my $u = $class->create_from_string($a);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is($u->variant, $b, $desc);
}

# Note:
#     Following UUIDs are created randomly except for variant field.
#     Some of them would not conform to UUID specification.

# 0 (NCS backward compatibility)
variant_is 'd41099f8-e361-93d9-6d08-51ce502dbd95', 0;
variant_is 'e6ec1375-fbf0-c30f-2135-cc420d50c41e', 0;
variant_is 'b2591624-31f7-69db-1751-93961ef42b24', 0;
variant_is '4f8431f9-9129-fc1b-60f9-334fe87ec0b1', 0;
variant_is '619a60f3-b4d5-ef19-262f-2346a4cea8f3', 0;

# 2 (RFC 4122)
variant_is '63b95cf8-e2c7-af4a-9b0d-5f112ef49445', 2;
variant_is 'de0db128-7b3d-4d15-a8b3-85c1c7d05246', 2;
variant_is 'a7f51d7b-ec72-04fa-bd42-b9fca068ba0d', 2;
variant_is '2f8dc589-20b3-6d68-87ef-0236ba486ea8', 2;
variant_is '6691155d-9454-8cee-9d90-4b400785eca0', 2;

# 6 (Microsoft GUID backward compatibility)
variant_is '1dc90569-b0c5-e420-c80a-0b696234579c', 6;
variant_is '8f4a4572-0eef-be23-d23b-6fa5e281fd87', 6;
variant_is 'f727fd12-8fde-a61a-d008-e5e9393c1b4b', 6;
variant_is '4cbb1ad4-94a9-ce08-ca43-8a686c2c0ae1', 6;
variant_is '2cde0766-d66e-afe1-dd84-d79d84e31acf', 6;

# 7 (Reserved)
variant_is 'fdaa3ed0-98c2-438c-eb4b-81117157975e', 7;
variant_is '410c2df6-062f-a9d8-e41e-1e0bfcedeeda', 7;
variant_is 'fdf3de62-6e91-e5a0-fc30-3e2505c5276d', 7;
variant_is '73fbed9d-752a-d537-e198-bf909f7adb53', 7;
variant_is '90132bab-b065-5816-faa5-adc990377c23', 7;

