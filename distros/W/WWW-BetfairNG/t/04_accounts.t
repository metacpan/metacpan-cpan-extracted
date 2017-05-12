#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 53;

# Tests of accounts methods NOT requiring internet connection
# ===========================================================

# Load Module
BEGIN { use_ok('WWW::BetfairNG') };
# Create Object w/o attributes
my $bf = new_ok('WWW::BetfairNG');
# Check all accounts methods exist
my %methods = (
  createDeveloperAppKeys => ['AppName'],
  getAccountDetails      => [],
  getAccountFunds        => [],
  getDeveloperAppKeys    => [],
  getAccountStatement    => [],
  listCurrencyRates      => [],
  transferFunds          => ['FromWallet', 'ToWallet', 'Amount'],
);
can_ok('WWW::BetfairNG', keys %methods);
# Check required parameters
my %param_data = (
  AppName    => {
		 name   => 'appName',
		 value  => 'App Name',
		 errstr => 'App Name is Required'
	        },
  FromWallet => {
		 name   => 'from',
		 value  => 'UK',
		 errstr => 'from Wallet is Required'
	        },
  ToWallet   => {
		 name   => 'to',
		 value  => 'Australian',
		 errstr => 'to Wallet is Required'
	        },
  Amount     => {
		 name   => 'amount',
		 value  => '5.00',
		 errstr => 'amount is Required'
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
  if ($method =~ /DeveloperAppKeys/) {
    like($bf->error, qr/^400 Bad Request/, "Bad request error message OK");
  }
  else {
    is($bf->error, "No application key set", "No app key error message OK");
  }
  is($bf->session(undef), undef, "Unset session token");
}
