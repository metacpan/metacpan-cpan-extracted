#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/./lib";
use lib "$FindBin::Bin/../lib";

=head1 DESCRIPTION

Tests for general client-related code.

=cut

use WebService::MyGengo::Test::Util::Client;
use WebService::MyGengo::Test::Util::Job;

use Getopt::Long;
use Test::More;
use LWP::UserAgent;

use Data::Dumper;

BEGIN {
    use_ok 'WebService::MyGengo::Base';
    use_ok 'WebService::MyGengo::Client';
}

# CLI options
my $DEBUG   = undef;
my $FILTER  = undef;
my $LIVE    = 0;
GetOptions(
    'debug'         => \$DEBUG
    , 'filter=s'    => \$FILTER
    , 'live:i'      => \$LIVE
    );
$LIVE and $ENV{WS_MYGENGO_USE_SANDBOX} = 1;
sub is_mock { !$LIVE }

my $tests = [
    'api_error_code_handled_correctly'
    , 'transport_error_code_handled_correctly'
    ];

my $client = client();
if ( $DEBUG ) {
    $client->DEBUG(1);
    is_mock() and $client->_user_agent->DEBUG(1);
}
my @_dummies;

run_tests();
done_testing();
teardown();

################################################################################
sub run_tests {
    foreach ( @$tests ) {
        next if $FILTER && $_ !~ /.*$FILTER.*/;
        $DEBUG and diag "##### Start test: $_";
        no strict 'refs';
        eval { &$_() };
        $@ and fail("Error in test $_: ".Dumper($@));
        $DEBUG and diag "##### End   test: $_";
    }
}

sub teardown {
    $DEBUG and print STDERR "TEARDOWN\n";
    foreach ( @_dummies ) {
        !$_->is_available and next;
        $client->delete_job( $_ ) or
            diag "Error deleting Job ".$_->id . ": "
                    . Dumper($client->last_response);
    }
}

################################################################################
sub api_error_code_handled_correctly {
    my $job = create_dummy_job( $client );

    # Force an error by attempting to request a revision
    my $com = "You are a champion.";
    $job = $client->request_job_revision( $job, $com );
    my $res = $client->last_response;

    ok( $res->is_error, "Res is error" );
    is( $res->_raw_response->code, 200, "Raw res has 200 error code" );
    isnt( $res->error_code, 0, "Has an API error code" );
    isnt( $res->error_code, 200, "API Error is not 200" );

    is( ref($res->_deserialized), 'HASH', "Has deserialized structure" );
    is( $res->_deserialized->{opstat}, 'error', "Opstat is 'error'" );
    is( $res->_deserialized->{err}->{code}, $res->error_code, "Errors match" );
}

sub transport_error_code_handled_correctly {
    my $res;
    my $struct = {};

    # Force a 404
    if ( is_mock() ) {
        $client->public_key( 'APIFAIL' );
        $res = $client->_send_request('GET', '/account/blargh/');
    }
    else {
        $res = $client->_send_request('GET', '/account/blargh/');
    }
    $struct = $res->response_struct;

    ok( $res->is_error, "Res is error" );
    is( $res->_raw_response->code, 404, "Raw res has 404 error code" );
    is( $res->error_code, 0, "Has no API error code" );
    isnt( $res->error_code, 200, "Error is not 200" );
    diag "You can safely disregard the 404 error.";
    is( $res->_deserialized, undef, "No deserialized structure" );

    if ( is_mock() ) {
        $client->public_key( 'OK' );
    }
}
