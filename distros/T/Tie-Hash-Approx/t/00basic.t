#!/usr/bin/perl -w
use strict;
use vars qw($loaded);
use Test::More tests => 1; 
END   { ok($loaded) }
use Tie::Hash::Approx; 
$loaded++;

