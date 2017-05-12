#!/usr/bin/perl -wT

use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser); 
use WWW::Patent::Page;

# I would make this idiot-proof, but idiots are so damn clever.

if ( param() ) {
	my $q = new CGI;
	print $q->header( -status=>"200 OK", -type=>"application/pdf");	
	my $agent = WWW::Patent::Page->new();
	my $doc_id = param('doc_id');
	$doc_id =~ s/[^A-Za-z0-9]//g;  # that which is not allowed is forbidden
	my $response = $agent->get_page($doc_id);
	print $response->content;
}

else {
	print header, start_html('Patent PDF Get'), h1('EPO'), start_form,
		"Patent? ", textfield('doc_id'), p, "e.g. US6123456 or EP1234567", p, p,
		submit, end_form, hr;
}

