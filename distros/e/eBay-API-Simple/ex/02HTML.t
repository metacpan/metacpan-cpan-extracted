use Test::More;
use strict; no warnings;
#use LWP::Debug qw(+);
use Data::Dumper;
use lib qw/lib/;

BEGIN {
    my @skip_msg;

    eval {
        use eBay::API::Simple::HTML;
    };
    
    if ( $@ ) {
        push @skip_msg, 'missing module eBay::API::Simple::HTML, skipping test';
    }
    if ( scalar( @skip_msg ) ) {
        plan skip_all => join( ' ', @skip_msg );
    }
    else {
        plan qw(no_plan);
    }    
}

my $call = eBay::API::Simple::HTML->new();

$call->execute( 'http://www.example.com/', { utm_campaign =>'simple_test' } );

#diag $call->request_content();
#diag $call->response_content();

if ( $call->has_error() ) {
    fail( 'api call failed: ' . $call->errors_as_string() );
}
else {
    is( ref $call->response_dom(), 'XML::LibXML::Document', 'response dom' );
    is( ref $call->response_hash(), 'HASH', 'response hash' );

    like( $call->response_hash->{head}{title}, 
        qr/Example/i, 
        'hash test' 
    );
    
    ok( $call->nodeContent('title') =~ /example/i, 
        'nodeContent test' );
    #diag Dumper( $call->response_hash );
}

$call->execute( 'http://bogusurlexample.com' );

is( $call->has_error(), 1, 'look for error flag' );
ok( $call->errors_as_string() ne '', 'check for error message' );
ok( $call->response_content() ne '', 'check for response content' );


