

#!perl -T
use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Test::More 0.88;
use Crypt::OpenSSL::RSA;
use File::Slurp;
use URI::Encode qw(uri_encode uri_decode );

#plan tests => 17; # instead of noplan using  done_testing;

use Config::Tiny;



BEGIN {
    use_ok( 'WebService::Xero::Agent::PrivateApplication' ) || print "Bail out!\n";

    # my $xero = 

    # as_text
    is( WebService::Xero::Agent::PrivateApplication->new() , undef, "attempt to create with invalid parameters failed as expected");



my $fake_key = '-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQCu2PMZrIHPiFmZujY0s7dz8atk1TofVSTVqhWg5h/fn8tYbwgg
koTqpAigxAUCAZ63prtj9LQhIqe3TRNtCDMsxxriyN3O/cxkVD52LwCKAgEoaNmr
Vvt97UgxglKyQ6taNO/c6V8FCKvPC945GKd/b7BoIYZcJsrpo+E+8Ek9IQIDAQAB
AoGAbbPC+0XIAI0dIp256uEjZkSn89Dw8b27Ka/YeCZKs0UQEYFAiSdE6+9VVoEG
X1bi3XloM3PSHMQglJpwaMVvTUwZfdxCFIM0mpgXtdK8Xuh3QTZpgH9S0a2HoXrB
uXFEqvwMcT43ig2FCfVQU86RQZAxrb1YfyFSauEayrVtbT0CQQDe8HEXSkbxjUwj
I2TdCDA7yOW7rWQPAk3REZ33SqBUdo45qofpkH7vWSx+W6q65uyRYfF4N1JKmW8V
OhMxBpFPAkEAyMbGZ2VX6gW37g03OGSoUG6mvXe+CKRqv8hV4UoGeQIUYJTFlt2O
ukD2jKyHqWIdU/3tM3iP1b8CY6JyVyhOjwJBAJ/NmDMKohnJn9bcKxOpJ/HiypIh
8sQzcZY4W5QEYTLKHJ7HV08brXFh6VvV12bL2q1HmLAEb69bll2P2Gve+k8CQQC3
1Pi4lxwl1FKSjlsvMUrDSm01Mbw34YM0UlP/0W2XwoWx4MYB2p7ifrTAHQCh4IoF
64wSAqOADEI9w/F5SBiVAkBJVt3jNObeieMfxVU/NOtajXX51sDUj3XCIWPPui8i
IKzzVn7G0kH+/TqtTPdizrDJkg/rsnrTpvHi8eeMZlAy
-----END RSA PRIVATE KEY-----';

    ## test a valid although unusable configuration
    ok( my $xero = WebService::Xero::Agent::PrivateApplication->new( CONSUMER_KEY    => 'CKCKCKCKCKCKCKCKCKCKCKCKCKCKCKCKCKCKCK', 
                                                          CONSUMER_SECRET => 'CSCSCSCSCSCSCSCSCSCSCSCSCSCSCSCSCSCSCS', 
                                                          #KEYFILE         => "/Users/peter/gc-drivers/conf/xero_private_key.pem"
                                                          PRIVATE_KEY => $fake_key, ) ,  'New Xero Private Application Agent' );
    is( ref($xero), 'WebService::Xero::Agent::PrivateApplication', 'created Xero object is the right type' );

    like ( $xero->as_text(), qr/WebService::Xero::Agent::PrivateApplication/, 'as_text()' );

    is( $xero->get_all_xero_products_from_xero(), undef, "attempt to get from xero fails with invalid credentials" );

    #WebService
}

done_testing;
