package Yahoo::Marketing::Test::Cache;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::Test::PostTest /;
use Test::More;
use Module::Build;
use Data::Dumper;
use Yahoo::Marketing::AccountService;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub test_set_cache : Test(2) {
    my $self = shift;

    return 'not running post tests' unless $self->run_post_tests;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );
    $ysm_ws->getAccount( accountID => $ysm_ws->account );
    my $location = $ysm_ws->cache->get('locations');

    # clear cache now.
    $ysm_ws->clear_cache;
    # confirm we cleared cache
    ok( !$ysm_ws->cache->get( 'locations' ) );

    # now pass the cache in param
    my $new_cache = Cache::FileCache->new;
    $new_cache->set( 'locations', $location );
    $ysm_ws->cache( $new_cache );
    ok( $ysm_ws->cache->get( 'locations' )->{$ysm_ws->version }->{ $ysm_ws->endpoint }->{ $ysm_ws->master_account } );
}


sub test_clear_cache : Test(2) {
    my $self = shift;

    return 'not running post tests' unless $self->run_post_tests;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );
    $ysm_ws->getAccount( accountID => $ysm_ws->account );

    ok( $ysm_ws->cache->get( 'locations' )->{$ysm_ws->version }->{ $ysm_ws->endpoint }->{ $ysm_ws->master_account } );

    $ysm_ws->clear_cache;

    ok( !$ysm_ws->cache->get( 'locations' ) );
}

sub test_purge_cache : Test(3) {
    my $self = shift;

    return 'not running post tests' unless $self->run_post_tests;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );
    # clear old cache first.
    $ysm_ws->clear_cache;

    $ysm_ws->cache_expire_time( '3 seconds' );
    my $account = $ysm_ws->getAccount( accountID => $ysm_ws->account );

    ok( $ysm_ws->cache->get( 'locations' )->{$ysm_ws->version }->{ $ysm_ws->endpoint }->{ $ysm_ws->master_account } );

    sleep( 4 ); # make sure that the cache has expired, see expire time above

    $ysm_ws->purge_cache;

    ok( !$ysm_ws->cache->get( $ysm_ws->_wsdl ) );
    ok( !$ysm_ws->cache->get( 'locations' ) );
}



sub start_cleanup_cache : Test(startup) {

    my $ysm_ws = Yahoo::Marketing::Service->new;

    $ysm_ws->clear_cache;
}

sub end_cleanup_cache : Test(shutdown) {

    my $ysm_ws = Yahoo::Marketing::Service->new;

    $ysm_ws->clear_cache;
}

1;

