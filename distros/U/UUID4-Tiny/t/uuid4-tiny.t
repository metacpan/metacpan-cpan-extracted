#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Tools::Tiny;
use UUID4::Tiny ':all';

tests is_uuid_string => sub {
    ok is_uuid_string('00000000-0000-0000-0000-000000000000'),
        'Basic UUID pattern';
    ok is_uuid_string('ffffffff-ffff-ffff-ffff-ffffffffffff'),
        'Lowercase';
    ok is_uuid_string('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA'),
        'Uppercase';
    ok !is_uuid_string('not-a-uuid'), 'Non-UUID text';
};

tests is_uuid4_string => sub {
    ok !is_uuid4_string('00000000-0000-4000-0000-000000000000'),
        'Version 4 with bad variant';

    for (qw(8 9 a b)) {
        ok is_uuid4_string(
            sprintf '00000000-0000-4000-%s000-000000000000', $_
            ), "Version 4 variant $_";

        ok !is_uuid4_string(
            sprintf '00000000-0000-1000-%s000-000000000000', $_
            ), "Bad version with variant $_";
    }
};

my $string = '42424242-4242-4242-4242-424242424242';
my $bytes = 'B' x 16;
tests string_to_uuid => sub {
    like warnings(sub {
        is string_to_uuid($string), string_to_uuid(string_to_uuid $string),
            'Bytes unchanged on attempted double conversion';
        })->[0], qr/assumed to be UUID bytes/, 'Warn for double conversion';

    is string_to_uuid($string), $bytes,
        'UUID string converts to correct UUID bytes';
};

tests uuid_to_string => sub {
    like warnings(sub {
        is uuid_to_string(uuid_to_string $bytes), uuid_to_string($bytes),
            'String unchanged on attempted double conversion';
        })->[0], qr/identified as UUID string/, 'Warn for double conversion';

    is uuid_to_string($bytes), $string,
        'UUID bytes convert to correct UUID string';
};

tests 'create_uuid(_string)' => sub {
    ok is_uuid4_string(uuid_to_string create_uuid),
        'create_uuid converts to valid UUID4 string';
    ok is_uuid4_string(create_uuid_string),
        'create_uuid_string returns valid UUID4 string';
};

done_testing;
