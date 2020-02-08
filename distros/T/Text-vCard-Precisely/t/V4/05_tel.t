use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 3;

use lib qw(./lib);

use Text::vCard::Precisely::V4;

my $vc = Text::vCard::Precisely::V4->new();

my $in_file = path( 't', 'V4', 'Tel', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

$vc->tel('0120-000-000');
is $vc->as_string, $expected_content, 'tel(Str)';                       # 1

$vc->tel({ content => '0120-000-000' });
is $vc->as_string, $expected_content, 'tel(HashRef)';                   # 2

$in_file = path( 't', 'V4', 'Tel', 'maltiple.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->tel([
    { types => ['home'], content => '0120-000-000' },
    { types => ['fax'],  content => '0120-000-001' },
]);
is $vc->as_string, $expected_content, 'tel(ArrayRef of HashRef)';       # 3

done_testing;
