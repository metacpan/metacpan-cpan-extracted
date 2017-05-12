#!/usr/dim/perl/5.8/bin/perl

# $Id: nph-object.cgi,v 1.31 2004/09/14 09:08:03 joern Exp $

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

# this hash maps CGI events (passed via parameter 'e')
# to methods of the NewSpirit::Object class.

my %METHOD = (
	create				=> 'create_ctrl',
	edit				=> 'edit_ctrl',
	save_object			=> 'save_ctrl',
	save_object_without_dep		=> 'save_ctrl',
	install_last_saved_object	=> 'install_last_saved_ctrl',
	properties			=> 'properties_ctrl',
	save_properties			=> 'save_properties_ctrl',
	save_properties_without_dep	=> 'save_properties_ctrl',
	download			=> 'download_ctrl',
	unlock				=> 'unlock_ctrl',
	history				=> 'history_ctrl',
	view				=> 'view_ctrl',
	restore				=> 'restore_ctrl',
	restore_without_dep		=> 'restore_ctrl',
	function			=> 'function_ctrl',
	delete_versions 		=> 'delete_versions_ctrl',
	dependencies			=> 'dependencies_ctrl',
	delete_ask			=> 'delete_ask_ctrl',
	delete				=> 'delete_ctrl',
	refresh_db_popup 		=> 'refresh_db_popup',
	refresh_base_config_popup	=> 'refresh_base_config_popup',
	download_prod_file 		=> 'download_prod_file_ctrl',
	download_prod_err_file 		=> 'download_prod_err_file_ctrl',
);

main: {
	# dieses globale Hash können Module nutzen, um request
	# spezifische Daten abzulegen
	%NEWSPIRIT::DATA_PER_REQUEST = ();
	
	my $q = new CGI;

	print $q->header( -nph => 1, -type=>'text/html' )
		unless $q->param('no_http_header');

	eval { main($q) };
	
	my $exception_handled = handle_exception ($@) if $@;
	
	NewSpirit::print_error ($@) if $@ and not $exception_handled;

	NewSpirit::remove_on_the_fly_session ($q);

	%NEWSPIRIT::DATA_PER_REQUEST = ();
}

sub main {
	my $q = shift;

	NewSpirit::check_session_and_init_request ($q);

	my $e = $q->param('e');
	
	# special handling for clone_session event
	# this has no corresponding method in NewSpirit::Object,
	# cloning must be done before creation of the NewSpirit::Object
	# instance
	
	if ( $e eq 'clone_session' ) {
		# clone session and mark as window session
		NewSpirit::clone_session ($q, 1);
		$e = 'edit';
		$q->param('e', $e);
		$q->param('window', 1);
	}
	
	# which method for this event?
	my $method = $METHOD{$e};

	if ( $method ) {
		my $o = new NewSpirit::Object (
			q => $q,
			set_lock => 1,
		);
		$o->$method();
	} elsif ( not $e ) {
		NewSpirit::blank_page();
	} else {
		print "event '$e' unknown";
	}
}

sub handle_exception {
	my ($message) = @_;
	
	my ($exc, $msg) = split ("\t", $message, 2);
	
	my ($handled, $title, $message);

	if ( $exc eq 'object_does_not_exist' ) {
		$handled = 1;
		($title) = split ("\t", $msg, 2);
		$message = "The object does not exist. Maybe someone deleted it and<br>\n";
		$message .= "you did not refresh your project browser since that time.\n";
	}
	
	if ( $handled ) {
		NewSpirit::std_header (
			page_title => $title
		);
		print "<p><b>$CFG::FONT$message</font></b>\n";
	}

	return $handled;
}
