#!/usr/local/bin/perl -w

use strict;

use WWW::Meta::XML::Browser;

my $browser = WWW::Meta::XML::Browser->new(
	args =>		{
					"Liga"	=> 'BeL3H',
				},
	debug => 1
);
$browser->process_file('liga_aktuell.xml');
$browser->process_all_request_nodes();
$browser->print_request_result($browser->get_request_result(0,0));