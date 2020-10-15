use strict;
use warnings;
use Path::Tiny;
use URI;

use Test::More tests => 4;

use Text::vCard::Precisely::V3;

my $vc = Text::vCard::Precisely::V3->new();

my $in_file          = path( 't', 'V3', 'URI', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8();

$vc->url('https://www.example.com');
$vc->source('https://www.example.com');
is $vc->as_string, $expected_content, 'url(Str)';    # 01

$vc->url( { content => 'https://www.example.com', types => 'home' } );
$vc->source( { content => 'https://www.example.com', types => 'home' } );
is $vc->as_string, $expected_content, 'url(HashRef)';    # 02

my $url = URI->new('https://www.example.com');
$vc->url($url);
$vc->source($url);
is $vc->as_string, $expected_content, 'url(URI)';        # 03

$in_file          = path( 't', 'V3', 'URI', 'maltiple.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->url(
    [   { types => 'home', content => 'https://www.example.com' },
        { types => 'work', content => 'https://blog.example.com' },
    ]
);
$vc->source('https://www.example.com');
is $vc->as_string, $expected_content, 'url(ArrayRef of HashRef)';    # 04

done_testing;
