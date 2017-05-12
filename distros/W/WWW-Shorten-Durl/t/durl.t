use strict;
use Test::More tests => 4;
BEGIN { use_ok 'WWW::Shorten' }
BEGIN { use_ok 'WWW::Shorten::Durl' }

my $url = 'http://jeen.tistory.com/';
my $code = '6588';

my $durl = 'http://durl.me/';
is ( makeashorterlink($url), $durl.$code);
is ( makealongerlink($durl.$code), $url);

