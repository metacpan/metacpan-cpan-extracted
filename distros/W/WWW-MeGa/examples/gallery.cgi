#!/usr/bin/perl -w
# $Id: gallery.cgi 172 2008-11-12 12:25:41Z fish $

use strict;
use FindBin qw($RealBin);

use if -e "$RealBin/../Makefile.PL", lib => "$RealBin/../lib";
use WWW::MeGa;

my $webapp = WWW::MeGa->new;
$webapp->run;
