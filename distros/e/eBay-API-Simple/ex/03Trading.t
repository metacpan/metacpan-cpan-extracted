use Test::More;
use strict; no warnings;
#use LWP::Debug qw(+);
use Data::Dumper;
use lib qw/lib/;

BEGIN {
    my @skip_msg;

    eval {
        use eBay::API::Simple::Trading;
    };
    
    if ( $@ ) {
        push @skip_msg, 'missing module eBay::API::Simple::Trading, skipping test';
    }
    if ( scalar( @skip_msg ) ) {
        plan skip_all => join( ' ', @skip_msg );
    }
    else {
        plan qw(no_plan);
    }    
} 

my $call = eBay::API::Simple::Trading->new( {
    # domain => 'internal-api.vip.ebay.com',
} );

#$call->api_init( { 
#    site_id => 0,
#    uri     => $arg_uri,
#    domain  => $arg_domain,
#    app_id  => $arg_appid,
#    version => $arg_version,
#} );

eval{
    $call->execute( 'GetCategories', 
                    { DetailLevel => 'ReturnAll',
                      LevelLimit => 2,
                      CategoryParent => 11116,
                  } 
                );
};

SKIP: {
    skip $@, 1 if $@;

    if ( $call->has_error() ) {
        fail( 'api call failed: ' . $call->errors_as_string() );
    }
    else {
        is( ref $call->response_dom(), 'XML::LibXML::Document', 'response dom' );
        is( ref $call->response_hash(), 'HASH', 'response hash' );

        like( $call->nodeContent('Timestamp'), 
            qr/^\d{4}-\d{2}-\d{2}/, 
            'response timestamp' 
        );

        ok( $call->nodeContent('ReduceReserveAllowed') =~ /(true|false)/, 
            'reduce reserve allowed node' );
    }
        
}

$call->execute( 'BadCallSSS', { Query => 'shoe' } );

is( $call->has_error(), 1, 'look for error flag' );
ok( $call->errors_as_string() eq 'Call Failure-The API call "BadCallSSS" is invalid or not supported in this release.', 'check for error message' );
ok( $call->response_content() ne '', 'check for response content' );

$call->execute( 'GetSearchResults', { Query => 'shoe', Pagination => { EntriesPerPage => 2, PageNumber => 1 }  } );

is( $call->has_error(), 0, 'error check' );
is( $call->errors_as_string(), '', 'error string check' );
ok( $call->nodeContent('TotalNumberOfEntries') > 10, 'response total items' );
#diag $call->request_object->as_string();

my @nodes = $call->response_dom->findnodes(
    '//Item'
);

foreach my $n ( @nodes ) {
    #diag( $n->findvalue('Title/text()') );
    ok( $n->findvalue('Title/text()') ne '', 'title check' );
}
 
#diag Dumper( $call->response_hash );

