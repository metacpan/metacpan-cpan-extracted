#!/usr/bin/perl -w
# -*- mode:cperl; coding:utf-8; -*-

#
# Author: Slaven Rezic
#

use strict;
use utf8;
use POSIX 'strftime';
use Test::More;
use Tk;
use Tk::DateEntry;

no warnings 'uninitialized';
plan skip_all => 'need a German locale for this test'
    if $ENV{LC_ALL} !~ m{^de};

my $mw = eval { MainWindow->new };
plan skip_all => 'cannot create MainWindow'
    if !$mw;

plan tests => 1;

my $w = $mw->DateEntry;
my $maerz = strftime '%B', 0,0,0,15,3-1,2016;
is $w->_decode_posix_bytes($maerz), "März";

__END__
