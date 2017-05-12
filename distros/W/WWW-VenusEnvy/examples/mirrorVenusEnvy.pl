#!/usr/bin/perl -w

use strict;
use LWP::Simple qw(get);
use WWW::VenusEnvy qw(:all);

my $html = get('http://venusenvy.keenspace.com/archive.html');
while (my ($id) = $html =~ m#http://venusenvy\.keenspace\.com/d/(\d{8})\.html#msi) {
	$html =~ s/$id//g;
	print "Getting $i.jpg ...\n";
	mirror_strip("$id.jpg",$id);
}


