use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 7;

use lib qw(./lib);

use Text::vCard::Precisely::V4;

my $vc = Text::vCard::Precisely::V4->new();

my $in_file = path( 't', 'V4', 'Address', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

$vc->adr({
    street      => 'street',
    city        => 'city',
    region      => 'region',
    post_code   => 'post_code',
    country     => 'country',
});
is $vc->as_string, $expected_content, 'adr(HashRef)';                   # 1

$in_file = path( 't', 'V4', 'Address', 'maltiple.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->adr([{
    street      => 'street',
    city        => 'city',
    region      => 'region',
    post_code   => 'post_code',
    country     => 'country',
},{
    street      => 'another street',
    city        => 'city',
    region      => 'region',
    post_code   => 'post_code',
    country     => 'country',
}]);
is $vc->as_string, $expected_content, 'adr(ArrayRef of HashRef)';       # 2

$in_file = path( 't', 'V4', 'Address', 'utf8.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->adr({
    types       => [qw(home work)],
    street      => '通り',
    city        => '市',
    region      => '都道府県',
    post_code   => '郵便番号',
    country     => '日本',
});
is $vc->as_string, $expected_content, 'adr(HashRef with utf8)';         # 3

$in_file = path( 't', 'V4', 'Address', 'long_ascii.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->adr({
    types       => [qw(home work)],
    street      => 'long named street',
    city        => 'long named city',
    region      => 'long named region',
    post_code   => 'post_code',
    country     => 'United States of America',
});
is $vc->as_string, $expected_content, 'adr(HashRef with long ascii)';   # 4

$in_file = path( 't', 'V4', 'Address', 'long_utf8.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->adr({
    types       => [qw(home work)],
    street      => '必要以上に冗長化された長い名前の通り',
    city        => '八王子市',
    region      => '都道府県',
    post_code   => '郵便番号',
    country     => '日本',
});
is $vc->as_string, $expected_content, 'adr(HashRef with long utf8)';    # 5

$in_file = path( 't', 'V4', 'Address', 'label.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->adr({
    street      => '123 Main Street',
    city        => 'Any Town',
    region      => 'CA',
    post_code   => '91921-1234',
    country     => 'U.S.A.',
    label       => "Mr. John Q. Public, Esq.\nMail Drop: TNE QB\n123 Main Street\nAny Town, CA  91921-1234\nU.S.A."
});
is $vc->as_string, $expected_content, 'adr(HashRef with label)';        # 6

$in_file = path( 't', 'V4', 'Address', 'geo.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->adr({
    geo         => 'geo:12.3457,78.910',
    street      => 'street',
    city        => 'city',
    region      => 'region',
    post_code   => 'post_code',
    country     => 'country',
});
is $vc->as_string, $expected_content, 'adr(HashRef with geo)';          # 7

done_testing;
