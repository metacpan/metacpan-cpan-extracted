use strict;
use warnings;
use Test::Base;
use WWW::Mechanize;
use WWW::Mechanize::DecodedContent;

plan skip_all => 'Live test (LIVE_TEST) not enabled'
    unless $ENV{LIVE_TEST};

plan tests => 2 * blocks;

my $mech = WWW::Mechanize->new;

run {
    my $block = shift;
    $mech->get($block->url);

    my $want_encoding = $block->encoding;
    like $mech->res->encoding, qr/$want_encoding/i;
    ok Encode::is_utf8( $mech->decoded_content );
};

__END__

===
--- url: http://del.icio.us/
--- encoding: utf-8

===
--- url: http://mixi.jp/
--- encoding: euc-jp
