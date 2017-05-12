use strict;
use Test::More tests => 2;

use WWW::Blog::Metadata;

my $html = do { open my $in, "t/sample.html"; join '', <$in> };
my $meta = WWW::Blog::Metadata->extract_from_html(\$html, "http://www.example.com/")
    or die WWW::Blog::Metadata->errstr;
is $meta->mobile_link, "http://www.example.com/mobile";
is $meta->mobile_link_type, "text/html";
