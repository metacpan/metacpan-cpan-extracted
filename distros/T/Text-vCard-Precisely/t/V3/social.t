use strict;
use warnings;
use Path::Tiny;
use URI;

use Test::More tests => 2;

use lib qw(./lib);

use Text::vCard::Precisely::V3;

my $vc = Text::vCard::Precisely::V3->new();

my $in_file = path( 't', 'V3', 'Social', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

$vc->socialprofile({ types => 'GitHub', content => 'https://github.com/worthmine' });
is $vc->as_string, $expected_content, 'socialprofile(HashRef)';                 # 1

$in_file = path( 't', 'V3', 'Social', 'maltiple.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->socialprofile([
    { types => 'twitter', content => 'https://twitter.com/worthmine' },
    { types => 'facebook', content => 'https://www.facebook.com/worthmine',
        displayname => 'worthmine',
        userid => '102074486543502',
    },
    { types => 'LinkedIn', content => 'https://jp.linkedin.com/in/worthmine' },
    { types => 'GitHub', content => 'https://github.com/worthmine' },
]);
is $vc->as_string, $expected_content, 'socialprofile(ArrayRef of HashRef)';     # 2

done_testing;
