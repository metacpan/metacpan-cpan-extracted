use Test::More;
use strict; no warnings;
#use LWP::Debug qw(+);
use Data::Dumper;
use lib qw/lib/;

BEGIN {
    my @skip_msg;

    eval {
        use eBay::API::Simple::RSS;
    };
    
    if ( $@ ) {
        push @skip_msg, 'missing module eBay::API::Simple::RSS, skipping test';
    }
    if ( scalar( @skip_msg ) ) {
        plan skip_all => join( ' ', @skip_msg );
    }
    else {
        plan qw(no_plan);
    }    
}

my $call = eBay::API::Simple::RSS->new();

$call->execute(
    'http://worldofgood.ebay.com/Eco-Organic-Clothes-Shoes-Men-Women-Children/43/list',
    { format => 'rss' },
);

if ( $call->has_error() ) {
    fail( 'api call failed: ' . $call->errors_as_string() );
}
else {
    is( ref $call->response_dom(), 'XML::LibXML::Document', 'response dom' );
    is( ref $call->response_hash(), 'HASH', 'response hash' );

    ok( $call->nodeContent('title') ne '', 'nodeContent test' );
    #diag Dumper( $call->response_hash );
}

$call->execute( 'http://bogusurlexample.com' );

is( $call->has_error(), 1, 'look for error flag' );
ok( $call->errors_as_string() ne '', 'check for error message' );
ok( $call->response_content() ne '', 'check for response content' );

my $call2 = eBay::API::Simple::RSS->new(
    { request_method => 'POST' }
);

$call2->execute(
    'http://en.wikipedia.org/w/index.php?title=Special:RecentChanges&feed=rss',
    { page => 1 },
);

is( ref $call2->response_dom(), 'XML::LibXML::Document', 'post response dom' );
is( ref $call2->response_hash(), 'HASH', 'post response hash' );
ok( $call2->nodeContent('title') ne '', 'post nodeContent test' );

