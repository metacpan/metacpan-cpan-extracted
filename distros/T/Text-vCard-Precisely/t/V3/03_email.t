use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 3;

use lib qw(./lib);

use Text::vCard::Precisely::V3;

my $vc = Text::vCard::Precisely::V3->new();

my $in_file = path( 't', 'V3', 'Email', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

$vc->email('tester@example.com');
is $vc->as_string, $expected_content, 'email(Str)';                    # test1

$vc->email({ content => 'tester@example.com' });
is $vc->as_string, $expected_content, 'email(HashRef)';                # test2

$in_file = path( 't', 'V3', 'Email', 'maltiple.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->email([
    { types => ['home'], content => 'tester@example.com' },
    { types => ['work'], content => 'tester2@example.com', preferred => 1 },
]);
is $vc->as_string, $expected_content, 'email(ArrayRef of HashRef)';        # test2

done_testing;
