use strict;
use warnings;
use Test::Base;
use WWW::Mechanize::AutoPager;
use WWW::Mechanize;

plan skip_all => 'TEST_LIVE is off' unless $ENV{TEST_LIVE};
plan tests => 2 * blocks;

my $mech = WWW::Mechanize->new;
$mech->autopager->load_siteinfo;

run {
    my $block = shift;
    $mech->get($block->url);
    is $mech->next_link, $block->next_link;
    ok $mech->page_element;
};

__END__
=== Tumblr
--- url: http://otsune.tumblr.com/
--- next_link: http://otsune.tumblr.com/page/2
--- page_element: otsune.tumblr.com/post
