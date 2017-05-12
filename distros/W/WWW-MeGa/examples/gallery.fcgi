#!/usr/bin/perl -w
# $Id: gallery.fcgi 172 2008-11-12 12:25:41Z fish $

use strict;
use CGI::Fast;

use FindBin qw($RealBin);

use if -e "$RealBin/../Makefile.PL", lib => "$RealBin/../lib";
use WWW::MeGa;

my %cache;

while (my $q = new CGI::Fast)
{
	my $app = WWW::MeGa->new
	(
		QUERY => $q,
		PARAMS => { cache => \%cache },
	);
	$app->run();
};
