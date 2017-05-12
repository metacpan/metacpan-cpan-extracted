#!/usr/bin/perl -w

# $Id$

use strict;
use Test::More tests => 3;

use_ok('WWW::DanDomain');

ok(my $wd = WWW::DanDomain->new());

can_ok($wd, qw(processor));