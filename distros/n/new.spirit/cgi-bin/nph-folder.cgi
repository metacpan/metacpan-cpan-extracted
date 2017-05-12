#!/usr/dim/perl/5.8/bin/perl

# $Id: nph-folder.cgi,v 1.10 2004/09/14 09:08:03 joern Exp $

use strict;
BEGIN {
	$| = 1;
	$0 =~ m!^(.*)[/\\][^/\\]+$!;    # Win32 Netscape Server Workaround
	chdir $1 if $1;
	require "../etc/default-user.conf";
	require "../etc/newspirit.conf"
}

require $CFG::objecttypes_conf_file;

use CGI qw(-nph);
use Carp;

use NewSpirit;
use NewSpirit::Folder;

my %METHOD = (
	edit => "edit_ctrl",
	create_folder => "create",
);

main: {
	# dieses globale Hash können Module nutzen, um request
	# spezifische Daten abzulegen
	%NEWSPIRIT::DATA_PER_REQUEST = ();
	
	my $q = new CGI;
	print $q->header( -nph => 1, -type=>'text/html' )
		unless $q->param('no_http_header');

	eval { main($q) };
	NewSpirit::print_error ($@) if $@;

	%NEWSPIRIT::DATA_PER_REQUEST = ();

	NewSpirit::remove_on_the_fly_session ($q);
}

sub main {
	my $q = shift;

	NewSpirit::check_session_and_init_request ($q);

	my $e = $q->param('e');
	
	# which method for this event?
	my $method = $METHOD{$e};

	if ( $method ) {
		my $o = new NewSpirit::Folder ($q);
		$o->$method();
	} elsif ( not $e ) {
		NewSpirit::blank_page();
	} else {
		print "event '$e' unknown";
	}
}
