#!/usr/bin/perl
use strict;
use warnings;
use WWW::BetfairNG;
use Test::More tests => 145;

# Tests of betting methods NOT requiring internet connection
# ==========================================================
# Create Object w/o attributes
my $bf = WWW::BetfairNG->new();


# Check all betting methods exist
my %methods = (
  listCompetitions         => ['MarketFilter'],
  listCountries            => ['MarketFilter'],
  listCurrentOrders        => [],
  listClearedOrders        => ['BetStatus'],
  listEvents               => ['MarketFilter'],
  listEventTypes           => ['MarketFilter'],
  listMarketBook           => ['MarketIds'],
  listRunnerBook           => ['MarketId', 'SelectionId'],
  listMarketCatalogue      => ['MarketFilter', 'MaxResults'],
  listMarketProfitAndLoss  => ['MarketIds'],
  listMarketTypes          => ['MarketFilter'],
  listTimeRanges           => ['MarketFilter', 'TimeGranularity'],
  listVenues               => ['MarketFilter'],
  placeOrders              => ['MarketId', 'PlaceInstructions'],
  cancelOrders             => [],
  replaceOrders            => ['MarketId', 'ReplaceInstructions'],
  updateOrders             => ['MarketId', 'UpdateInstructions'],
);
can_ok('WWW::BetfairNG', keys %methods);
# Check required parameters
my %param_data = (
  MarketFilter        => {
			  name   => 'filter',
			  value  => {},
			  errstr => 'Market Filter is Required'
			 },
  BetStatus           => {
			  name   => 'betStatus',
			  value  => 'SETTLED',
			  errstr => 'Bet Status is Required'
			 },
  MarketIds           => {
			  name   => 'marketIds',
			  value  => [],
			  errstr => 'Market Ids are Required'
			 },
  MaxResults          => {
			  name   => 'maxResults',
			  value  => '1',
			  errstr => 'maxResults is Required'
			 },
  TimeGranularity     => {
			  name   => 'granularity',
			  value  => 'DAYS',
			  errstr => 'Time Granularity is Required'
			 },
  MarketId            => {
			  name   => 'marketId',
			  value  => '1.111111',
			  errstr => 'Market Id is Required'
			 },
  SelectionId         => {
			  name   => 'selectionId',
			  value  => '6750999',
			  errstr => 'Selection Id is Required'
			 },
  PlaceInstructions   => {
			  name   => 'instructions',
			  value  => [
				     {
				      selectionId => "6666666",
				      handicap    => "0",
				      side        => "BACK",
				      orderType   => "LIMIT",
				      limitOrder  => {
						      size => "0.01",
						      price => "1000",
						      persistenceType => "LAPSE"
						     }
				     }
				    ],
			  errstr => 'Order Instructions are Required'
			 },
  ReplaceInstructions => {
			  name   => 'instructions',
			  value  => [
				     {
				      selectionId => "6666666",
				      newPrice    => "500"
				     }
				    ],
			  errstr => 'Replace Instructions are Required'
			 },
  UpdateInstructions  => {
			  name   => 'instructions',
			  value  => [
				     {
				      selectionId => "6666666",
		               newPersistenceType => "LAPSE"
				     }
				    ],
			  errstr => 'Update Instructions are Required'
			 },
 );
foreach my $method (keys %methods) {
  my $params = {};
  foreach my $required_param (@{$methods{$method}}) {
      ok(!$bf->$method($params), "Call $method");
      is($bf->error, 'Not logged in' , "$method error msg");
      my $pkey = $param_data{$required_param}{name};
      my $pval = $param_data{$required_param}{value};
      $params->{$pkey} = $pval;
  }
  ok(!$bf->$method($params), "Call $method");
  is($bf->error, 'Not logged in' , "$method error msg");
  is($bf->session('session_token'), 'session_token', "Set session token");
  ok(!$bf->$method($params), "Call $method");
  is($bf->error, "No application key set", "No app key error message OK");
  is($bf->session(undef), undef, "Unset session token");
}
