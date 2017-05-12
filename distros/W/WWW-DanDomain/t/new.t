#!/usr/bin/perl -w

# $Id$

use strict;
use Test::More tests => 5;

use_ok('WWW::DanDomain');

my $wd;

ok($wd = WWW::DanDomain->new());

isa_ok($wd, 'WWW::DanDomain');

my $mech = WWW::Mechanize->new();

ok($wd = WWW::DanDomain->new({mech => $mech}));

ok($wd = WWW::DanDomain->new({verbose => 1}));