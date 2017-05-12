#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);
use WWW::Search;

my $motif	= shift || 'ACCTA';
my $s		= new WWW::Search ('PubMed');
$s->native_query( $motif );


my $count	= 0;
while (my $r = $s->next_result) {
	unless ($count++) {
		print "The following abstracts mention the motif '${motif}':\n\n";
	}
	
	print join(' ', "${count}.", $r->title, $r->description) . "\n\n";
}

unless ($count) {
	print "No abstracts were found that mention the motif '${motif}'.\n";
}

