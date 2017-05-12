use Test::More tests => 9;

use strict;
use warnings;

use_ok( 'WebService::Lucene' );

{
    my $service = WebService::Lucene->new( 'http://localhost:8080/lucene' );
    isa_ok( $service, 'WebService::Lucene' );
    is( $service->base_url, 'http://localhost:8080/lucene/', 'service url' );
}

{
    my $service = WebService::Lucene->new( 'http://localhost:8080/lucene/' );
    isa_ok( $service, 'WebService::Lucene' );
    is( $service->base_url, 'http://localhost:8080/lucene/', 'service url' );
}

{
    my $service = WebService::Lucene->new( 'http://localhost:8080/lucene/' );
    isa_ok( $service, 'WebService::Lucene' );

    my $index = $service->get_index( 'library' );
    isa_ok( $index, 'WebService::Lucene::Index' );

    is( $index->base_url, 'http://localhost:8080/lucene/library/',
        'index url' );
    is( $index->name, 'library', 'index name' );
}
