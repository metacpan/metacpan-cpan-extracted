#!perl -T

use Test::More tests => 3;

use WWW::Shorten::PunyURL;

my $url = 'http://developers.sapo.pt/';
my $punyurl = WWW::Shorten::PunyURL->new(
    url => $url
);

is( $punyurl->url, 'http://developers.sapo.pt/', 'URL setting' );
isa_ok( $punyurl->parser, 'XML::LibXML', 'XML parser instantiated' );
isa_ok( $punyurl->browser, 'LWP::UserAgent', 'Browser instantiated' );