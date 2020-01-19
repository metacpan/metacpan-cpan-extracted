use strict;
use warnings;
use Path::Tiny;
use URI;

use Test::More tests => 4;

use lib qw(./lib);

use Text::vCard::Precisely::V3;

my $vc = Text::vCard::Precisely::V3->new();

my $in_file = path( 't', 'V3', 'URI', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

$vc->url('https://www.example.com');
$vc->source('https://www.example.com');
is $vc->as_string, $expected_content, 'url(Str)';                    # test1

$vc->url({ content => 'https://www.example.com' });
$vc->source({ content => 'https://www.example.com' });
is $vc->as_string, $expected_content, 'url(HashRef)';                # test2

my $url = URI->new('https://www.example.com');
$vc->url($url);
$vc->source($url);
is $vc->as_string, $expected_content, 'url(URI)';                    # test3

$in_file = path( 't', 'V3', 'URI', 'maltiple.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->url([
    { types => ['home'], content => 'https://www.example.com' },
    { types => ['work'], content => 'https://blog.example.com' },
]);
$vc->source('https://www.example.com');
is $vc->as_string, $expected_content, 'url(ArrayRef of HashRef)';        # test4

done_testing;
