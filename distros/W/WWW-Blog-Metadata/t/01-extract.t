use strict;
use Test::More tests => 10;
use WWW::Blog::Metadata;
use File::Spec::Functions;
use URI::file;

use constant SAMPLES => catdir 't', 'samples';

my($meta);

{
    diag 'extract_from_html';

    open my $fh, catfile(SAMPLES, 'blog-full.html')
        or die $!;
    my $html = do { local $/; <$fh> };
    close $fh;

    my $meta = WWW::Blog::Metadata->extract_from_html(
        \$html, 'http://example.com/'
    );
    isa_ok $meta, 'WWW::Blog::Metadata';
    ok $meta->feeds, 'meta->feeds is defined';
    is scalar @{ $meta->feeds }, 2, '2 feeds in the source html';
    is $meta->feeds->[0], 'http://btrott.typepad.com/typepad/atom.xml';
    is $meta->feeds->[1], 'http://btrott.typepad.com/typepad/index.rdf';
    is $meta->foaf_uri, 'http://btrott.typepad.com/foaf.rdf';
    is $meta->lat, '37.743630';
    is $meta->lon, '-122.443182';
}

{
    diag 'extract_from_uri';
    my $meta = WWW::Blog::Metadata->extract_from_uri(
        'http://www.sixapart.com/blog/'
    );
    isa_ok $meta, 'WWW::Blog::Metadata';
    my $feeds = $meta->feeds;
    cmp_ok @$feeds, '>=', 1, 'at least 1 feed on www.sixapart.com/blog/';
}