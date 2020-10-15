use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 1;

use Text::vCard::Precisely::V4;
my $vc = Text::vCard::Precisely::V4->new();

my $in_file          = path( 't', 'V4', 'Expected', 'kind.vcf' );
my $expected_content = $in_file->slurp_utf8;

$vc->kind('individual');
is $vc->as_string, $expected_content, 'kind(Str)';    # 1

done_testing;
