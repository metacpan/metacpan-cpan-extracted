use Test::More tests => 4;

use strict;
use warnings;

use_ok( 'XML::RSS::JavaScript' );

my $rss = XML::RSS::JavaScript->new();
isa_ok( $rss, 'XML::RSS::JavaScript' );

$rss->channel(
    'title'       => 'title',
    'link'        => 'link',
    'description' => 'description'
);

$rss->add_item(
    'title'       => 'title1',
    'link'        => 'link1',
    'description' => 'desc1'
);

$rss->add_item(
    'title'       => 'title2',
    'link'        => 'link2',
    'description' => 'desc2'
);

{
    eval { $rss->save_javascript; };
    like( $@, qr/You must pass in a filename/, 'save_javascript (no file)' );
}

{
    eval { $rss->save_javascript( 't' ); };
    like( $@, qr/Cannot open file/, "save_javascript (can't write file)" );
}
