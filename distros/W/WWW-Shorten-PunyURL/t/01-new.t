#!perl -T

use Test::More tests => 2;

use WWW::Shorten::PunyURL;

my $url = 'http://developers.sapo.pt/';
my $punyurl = WWW::Shorten::PunyURL->new( url => $url );

ok( defined $punyurl, 'Object created' );
isa_ok( $punyurl, 'WWW::Shorten::PunyURL', 'Object type is correct' );
