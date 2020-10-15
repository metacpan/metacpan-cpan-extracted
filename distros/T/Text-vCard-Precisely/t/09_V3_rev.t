use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 2;

use Text::vCard::Precisely::V3;

my $vc = Text::vCard::Precisely::V3->new();
$vc->rev('2008-04-24T19:52:43Z');

my $in_file          = path( 't', 'V3', 'Rev', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

is $vc->as_string, $expected_content, 'rev(DateTime)';    # 1

$in_file          = path( 't', 'V3', 'Rev', 'date.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->rev('2008-04-24');
is $vc->as_string, $expected_content, 'rev(Date)';        # 2

done_testing;
