use strict;
use warnings;

use Test::More;

if (! $ENV{XML_AMAZON__FORCE_TESTS})
{
    plan skip_all => 'Skipping failing test';
}
else
{
    plan tests => 3;
}

use XML::Amazon;  # What you're testing.
my $amazon = XML::Amazon->new(token => '1VJJYMBJGWQPFCG64282', sak => 'KZneYOoXBTILPRPaRHIVG7Fx0f/VT7F8V4ueyHq7', locale => 'uk');
my $item = $amazon->asin('0596101058');

# TEST
is($amazon->is_success, '1', 'Get information from Amazon by ASIN.');

# TEST
like (
    $item->title, qr/Learning Perl/,
    'Check if the information is correct. The title is ' . $item->title
);

my $items = $amazon->search(keywords => 'Perl');

# TEST
ok($items, 'Get information from Amazon by searching.');

