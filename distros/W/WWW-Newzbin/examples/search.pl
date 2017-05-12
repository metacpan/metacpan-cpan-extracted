#!/usr/bin/perl

use strict;
use warnings;

use WWW::Newzbin;
use WWW::Newzbin::Constants;

# log into newzbin using the username "joebloggs" and the password "secretpass123"
my $nzb = WWW::Newzbin->new(
	username => "joebloggs",
	password => "secretpass123"
);

# search newzbin for posts
my @results = $nzb->search_files(
	query => "the john smith orchestra",
	category => [ NEWZBIN_CAT_MUSIC, NEWZBIN_CAT_MOVIES ], # search in Newzbin's "music" and "movies" categories...
	group => [ "alt.binaries.music", "alt.binaries.test" ], # ...and return results from these groups only
	retention => 30, # no more than 30 days old
	resultlimit => 50, # return maximum of 50 results
	sortfield => NEWZBIN_SORTFIELD_SUBJECT, # sort by subject...
	sortorder => NEWZBIN_SORTORDER_ASC # ...in ascending order
);

# check whether errors occurred
if ($nzb->error_code) {
	print "Error # " . $nzb->error_code . ": " . $nzb->error_message;
} else {
	print "Total number of results found: " . $nzb->search_files_total;
	print "Subject of result #1: " . $results[0]->{subject};
}
