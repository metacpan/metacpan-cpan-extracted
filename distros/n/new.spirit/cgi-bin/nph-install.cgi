#!/usr/dim/perl/5.8/bin/perl

# $Id: nph-install.cgi,v 1.10 2004/09/14 09:08:03 joern Exp $

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
use NewSpirit::Object;

my %METHOD = (
	install_project => 'install_project_ctrl',
	compile_project => 'compile_project_ctrl',
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

	$q->param('object', 'dummy.depend-all');

	NewSpirit::check_session_and_init_request ($q);

	# which method for this event?
	my $e = $q->param('e');
	my $method = $METHOD{$e};

	if ( $method ) {
		my $o = new NewSpirit::Object (
			q => $q,
			base_config_object => $q->param('base_config')
		);
		$o->$method();
	} elsif ( not $e ) {
		NewSpirit::blank_page();
	} else {
		print "event '$e' unknown";
	}
}
