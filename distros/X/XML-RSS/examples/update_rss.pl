#!/usr/bin/perl
# update_rss.pl
# Adds a new item to the RSS file
use strict;
use warnings;

use XML::RSS;

die "Syntax: update_rss.pl source.rdf destination.rdf\n\n"
	unless @ARGV == 2;

my $rss = XML::RSS->new;
$rss->parsefile(shift);

$rss->add_item(title => "MpegTV Player (mtv) 1.0.9.7",
               link  => "http://freshmeat.net/news/1999/06/21/930003958.html",
	       mode => 'insert'
	       );

$rss->save(shift);
