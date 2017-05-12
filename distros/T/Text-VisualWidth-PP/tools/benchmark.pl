use strict;
use warnings;
use utf8;
use Benchmark qw/:all/;
use Encode;
use Text::VisualWidth::PP;
use Text::VisualWidth::UTF8;

my $flagged = "あいうえおaiueo" x 100;
my $raw     = encode_utf8($flagged);

cmpthese(
    -1 => {
        'orig' => sub {
            Text::VisualWidth::UTF8::width($flagged);
        },
        'pp' => sub {
            Text::VisualWidth::PP::width($flagged);
        },
    },
);

