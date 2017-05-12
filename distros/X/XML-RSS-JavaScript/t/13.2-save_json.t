use strict;
use warnings;
use Test::More tests => 4;

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

my $file = 't/out.js';

$rss->save_json( $file );
ok( -e $file, 'File created' );
ok( -s $file, 'File written' );

unlink( $file );
