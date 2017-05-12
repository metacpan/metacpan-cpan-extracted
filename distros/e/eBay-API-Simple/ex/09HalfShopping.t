use Test::More;
use strict; no warnings;
#use LWP::Debug qw(+);
use Data::Dumper;
use lib qw/lib/;

my @skip_msg;

plan skip_all => join( ' ', 'Skipping Half test - not implemented' );

BEGIN {


    eval {
        use eBay::API::Simple::Shopping;
    };
    
    if ( $@ ) {
        push @skip_msg, 'missing module eBay::API::Simple::Shopping, skipping test';
    }
    if ( scalar( @skip_msg ) ) {
        #plan skip_all => join( ' ', @skip_msg );
    }
    else {
        #plan qw(no_plan);
    }    
}

my $call;
eval {
    $call = eBay::API::Simple::Shopping->new(
        { appid => undef, enable_attributes => 1 } # <----- your appid here
    );
};
if ( $@ ) {
    push( @skip_msg, $@ );
}


SKIP: {
    skip join( ' ', @skip_msg), 1 if scalar( @skip_msg );

    $call->execute ('FindHalfProducts', { 
        ProductID => { 
            type =>'ISBN', content => '0596006306' 
        }, 
        PageNumber => { content => 1 }, 
    } );

    is( ref $call->response_hash(), 'HASH', 'response hash' );
    
    #print $call->request_content() . "\n\n";
    #print $call->response_content();

    if ( $call->has_error() ) {
        die "Call Failed:" . $call->errors_as_string();
    }

    # getters for the response DOM or Hash
    my $dom   = $call->response_dom();
    my $title = $call->response_hash->{Products}{Product}{Title};
    
    like( $title, qr/Head First by Lynn Beighley/, "title check" );
    
    is( $call->nodeContent( 'Ack' ), 'Success', 'call was successfull' );
}

