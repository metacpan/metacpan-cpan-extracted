#!/usr/bin/perl -wT

use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use WWW::Patent::Page;

# I would make this idiot-proof, but idiots are so damn clever.
use Archive::Zip;

if (param()) {    
	my $q = new CGI;
	binmode STDOUT;
	my $doc_id = param('doc_id');
	print $q->header(-status => "200 OK", -type => "application/zip", -attachment => "$doc_id.zip");
	my $agent = WWW::Patent::Page->new();

	#$agent->env_proxy();
	#$agent->proxy(['http', 'ftp'], 'http://somewhere.com:80/');
	$doc_id =~ s/[^A-Za-z0-9]//g;    # that which is not allowed is forbidden
	my $zip = $agent->get_page(
		$doc_id,
		'office' => 'JPO_IPDI',
		'format' => 'translation',
	);

	#	print 		#$response->content;
	$zip->writeToFileHandle(STDOUT, 0);    # 0 for not seekable
}

else {
	print header, start_html('JPO to English by IPDI'), h1('Japanese to English Patent Document Translation'), start_form,
		"Published at JPO? ", textfield('doc_id'), ' ',

		submit, end_form,
		"e.g. JPH09-123456A or JP2004012345A or JP2500002B or JP2006-004050A1 <br> see also http://www4.ipdl.inpit.go.jp/Tokujitu/tjsogodben.ipdl?N0000=115",
		p, '(Please be patient- translations and network latency take time.)', p, hr;
}
