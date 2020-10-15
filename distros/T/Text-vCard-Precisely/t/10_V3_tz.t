use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 2;

use Text::vCard::Precisely::V3;

my $vc = Text::vCard::Precisely::V3->new();
$vc->tz('America/Chicago');

my $in_file          = path( 't', 'V3', 'Tz', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

is $vc->as_string, $expected_content, 'tz(Str)';    # 1

$in_file          = path( 't', 'V3', 'Tz', 'multiple.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->tz( [ 'America/Chicago', 'Asia/Tokyo' ] );
is $vc->as_string, $expected_content, 'tz(ArraRef)';    # 2

done_testing;
