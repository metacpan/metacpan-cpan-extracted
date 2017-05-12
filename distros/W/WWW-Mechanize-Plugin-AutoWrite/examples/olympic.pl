#!/usr/bin/perl

=head1 NAME

olympic.pl - Get the results for all olympic games ever.

=head1 SYNOPSIS

olympic.pl

=head1 DESCRIPTION

This example shows how to navigate through a web site while using
L<WWW::Mechanize::Plugin::AutoWrite> in order to automatically save the whole
HTTP session.

Here we get the results of for all olympic games ever by browsing the official
web site of the olympic committee.

=cut

use strict;
use warnings;

use WWW::Mechanize;
use XML::LibXML;

# Load the plugin AutoWrite
use WWW::Mechanize::Plugin::AutoWrite;

use Data::Dumper;

exit main();


sub main {

	binmode(STDOUT, ":utf8");

	# Create an instance of mechanize and set it up to our liking.
	# For this example a vanilla mechanize is fine.
	my $mech = WWW::Mechanize->new(autocheck => 1);
	$mech->autowrite->dir('tmp/olympics');

	browse($mech);

	return 0;
}


#
# Method that browses the official International Olympic Committee web site and
# gets the medals results for each year.
#
sub browse {
	my ($mech) = @_;

	print "Going to http://www.olympic.org/\n";
	$mech->get('http://www.olympic.org/');
	# Strange the site is in english but the source identifies the site in french
	if ($mech->content !~ m/Site Officiel du Mouvement Olympique/) {
		die "Not browsing olympic.org";
	}


	print "Going to the past olympic games page\n";
	$mech->follow_link(text => 'Olympic Games');
	if ($mech->content !~ /Past Olympic Games since 1896/) {
		die "This is not the past olympic games page";
	}

	# Find the summer olympic events
	my $parser = XML::LibXML->new();
	$parser->recover_silently(1);
	my $doc = $parser->parse_html_string($mech->content);
	
	# Loop through each summer event
	foreach my $node ($doc->findnodes("//dl[dt[text() = 'Olympic Summer Games:']]/dd/a")) {
	
		my ($olympic_event) = $node->textContent();
		$olympic_event =~ s/\s+/ /g;

		my ($place, $year) = ($olympic_event =~ m/^\s*(.+)\s+(\d+)$/);
		my $link = $node->getAttribute('href');

		browse_olympic_event($mech, $link, $place, $year);
	}
}


#
# Browses the page of a specific olympic event.
#
sub browse_olympic_event {
	my ($mech, $link, $place, $year) = @_;
	
	my $olympic_event = "olympic games of $place $year";

	
	# Got to the summer's event page
	printf "Getting the main page for $olympic_event\n";
	$mech->get($link);
	if ($mech->content !~ m,<h3>\Q$place&nbsp;$year\E</h3>,) {
		die "This is not the page for the $olympic_event";
	}
	
	# Follow the link for the medals per country (we need to remove the javascript)
	printf "Getting the medals page for $olympic_event\n";
	$link = $mech->find_link(text => 'Medals by country');
	
	# Clean the URL from all javascript
	my $url = $link->url;
	$url =~ s/^javascript:openWindow\('([^']+)'.*$/$1/;

	$mech->get($url);
	my $regexp = qr{
		<em>
			\Q$place\E
			&nbsp; \s+
			\Q$year\E
			\s+	- \s+ 
			\QMedal Table\E
		</em>
	}x;
	if ($mech->content !~ m/$regexp/) {
		die "This is not the page for the medals table from the $olympic_event";
	}
	
	# Revert the mechanize instance to where it was (two steps back).
	$mech->back();
	$mech->back();
}

