use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 5;

use Text::vCard::Precisely::V3;

my $vc = Text::vCard::Precisely::V3->new();

my $in_file          = path( 't', 'V3', 'Address', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

$vc->adr(
    {   pobox     => 'pobox',
        extended  => 'extended',
        street    => 'street',
        city      => 'city',
        region    => 'region',
        post_code => 'post_code',
        country   => 'country',
    }
);
is $vc->as_string, $expected_content, 'adr(HashRef)';    # 1

$in_file          = path( 't', 'V3', 'Address', 'maltiple.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->adr(
    [   {   pobox     => 'pobox',
            extended  => 'extended',
            street    => 'street',
            city      => 'city',
            region    => 'region',
            post_code => 'post_code',
            country   => 'country',
        },
        {   pobox     => 'another pobox',
            extended  => 'extended',
            street    => 'another street',
            city      => 'city',
            region    => 'region',
            post_code => 'post_code',
            country   => 'country',
        }
    ]
);
is $vc->as_string, $expected_content, 'adr(ArrayRef of HashRef)';    # 2

$in_file          = path( 't', 'V3', 'Address', 'utf8.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->adr(
    {   types     => [qw(home work)],
        pobox     => '201号室',
        extended  => 'マンション',
        street    => '通り',
        city      => '市',
        region    => '都道府県',
        post_code => '郵便番号',
        country   => '日本',
    }
);
is $vc->as_string, $expected_content, 'adr(HashRef with utf8)';    # 3

$in_file          = path( 't', 'V3', 'Address', 'long_ascii.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->adr(
    {   types     => [qw(home work)],
        pobox     => 'pobox',
        extended  => 'long named extended',
        street    => 'long named street',
        city      => 'long named city',
        region    => 'long named region',
        post_code => 'post_code',
        country   => 'United States of America',
    }
);
is $vc->as_string, $expected_content, 'adr(HashRef with long ascii)';    # 4

$in_file          = path( 't', 'V3', 'Address', 'long_utf8.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->adr(
    {   types     => [qw(home work)],
        pobox     => '201号室',
        extended  => '必要以上に長い名前のマンション',
        street    => '冗長化された通り',
        city      => '八王子市',
        region    => '都道府県',
        post_code => '郵便番号',
        country   => '日本',
    }
);
is $vc->as_string, $expected_content, 'adr(HashRef with long utf8)';    # 5

done_testing;
