use strict;
use Test::Base;

plan skip_all => "no inc/.author" unless -e "inc/.author";
plan tests => 2 * blocks;

use WWW::Shorten 'RevCanonical';

run {
    my $block = shift;

    my $shorten = makeashorterlink $block->url;
    is $shorten, $block->shorten, $block->name;

    my $long = makealongerlink $block->shorten;
    is $long, $block->url, $block->name;
};

__END__

=== flickr
--- url: http://www.flickr.com/photos/leahculver/3430401384/
--- shorten: http://flic.kr/p/6e8GPs

=== dopplr
--- url: http://www.dopplr.com/traveller/miyagawa
--- shorten: http://dplr.it/t/miyagawa
