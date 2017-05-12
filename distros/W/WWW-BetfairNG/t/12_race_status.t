#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;

# Tests of race status methods NOT requiring internet connection
# ==============================================================

# Load Module
BEGIN { use_ok('WWW::BetfairNG') };
# Create Object w/o attributes
my $bf = new_ok('WWW::BetfairNG');
# Check all race status methods exist
my %methods = (
  listRaceDetails => [],
);
can_ok('WWW::BetfairNG', keys %methods);
my %param_data = (
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
