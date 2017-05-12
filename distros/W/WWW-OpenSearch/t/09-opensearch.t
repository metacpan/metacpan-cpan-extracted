use Test::More tests => 2;

use_ok( 'WWW::OpenSearch' );
use URI::file;

my $uri = URI::file->new_abs( 't/data/osd.xml' );

my $engine = WWW::OpenSearch->new( $uri );
isa_ok( $engine, 'WWW::OpenSearch' );
