use Test::More;
use strict; no warnings;

use lib qw( t/lib );
use TestCommon::Credentials;

BEGIN {
    my @skip_msg;

    unless ( TestCommon::Credentials->load() ) {
        push @skip_msg, 'skipping test, missing eBay credentials';
    }

    eval {
        use eBay::API::XML::Call::GetSearchResults;
    };
    
    if ( $@ ) {
        push @skip_msg, 'missing module GetSearchResults, skipping test';
    }
    if ( scalar( @skip_msg ) ) {
        plan skip_all => join( ' ', @skip_msg );
    }
    else {
        plan qw(no_plan);
    }    
}

my $call = eBay::API::XML::Call::GetSearchResults->new( {
    site_id => 0,
    proxy   => $arg_api_url,
    dev_id  => $arg_devid,
    app_id  => $arg_appid,
    cert_id => $arg_certid,
    user_auth_token => $arg_authtoken
} );

$call->setQuery('iPhone');
$call->execute();

if ( $arg_verbose ) {
    diag( "Request:" . $call->getHttpRequestAsString(1) );
    diag( "Response: " . $call->getHttpResponseAsString(1) );    
}

is( $call->getAck, 'Success', 'search results query' );

#my $data = $call->getSearchResultItemArray();
#use Data::Dumper;
#warn( Dumper( $data ) );

my @i = $call->getSearchResultItemArray->getSearchResultItem();
use Data::Dumper;

foreach my $item ( @i ) {
    print $item->getItem()->getPictureDetails()->getPictureURL() . "\n";
    print Dumper( $item->getItem->getPictureDetails ) . "\n";
    
}

