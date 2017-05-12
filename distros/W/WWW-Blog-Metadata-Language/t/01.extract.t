use Test::More tests => 2;

use WWW::Blog::Metadata;

my $meta;

$meta = WWW::Blog::Metadata->extract_from_uri('http://www.techcrunch.com/')
    or die WWW::Blog::Metadata->errstr;
is($meta->language(), 'en');

$meta = WWW::Blog::Metadata->extract_from_uri('http://wirres.net/')
    or die WWW::Blog::Metadata->errstr;
is($meta->language(), 'de');


