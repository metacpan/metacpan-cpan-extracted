#!/usr/bin/perl
use strict;
use warnings;
use if -d 'lib', lib => 'lib';
use W3C::Validator::Server;

my $app = W3C::Validator::Server->build_app;

return scalar caller(0) ? $app : W3C::Validator::Server->run($app, @ARGV);
