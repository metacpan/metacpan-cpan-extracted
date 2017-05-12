
package WWW::Patent::Page::USPTO;

# Version 2006-04-04		H. Schier
use strict;
use warnings;
use diagnostics;
use Carp;
use subs
	qw( methods USPTO_country_known  USPTO_htm USPTO_tif USPTO_pdf USPTO_terms  )
	;    #USPTO_pdf
use LWP::UserAgent 2.003;
require HTTP::Request;
use HTML::HeadParser;
use HTML::TokeParser;
use PDF::API2 2.00;
use File::Temp 0.17;
#use Data::Dumper;

$| = 1 ; 

use vars qw/ $VERSION @ISA/;

$VERSION = "0.30";

sub methods {
	return (
		'USPTO_htm'           => \&USPTO_htm,
		'USPTO_tif'           => \&USPTO_tif,
		'USPTO_pdf'           => \&USPTO_pdf,
		'USPTO_country_known' => \&USPTO_country_known,

		#		'USPTO_parse_doc_id'        => \&USPTO_parse_doc_id,
		'USPTO_terms' => \&USPTO_terms,
	);

}

#  sub USPTO_parse_doc_id{
#  "All patent numbers must be 7 characters in length"
#     well, maybe 7 or less...
#  USPTO will give 692,301 for request of 692301 or 0692301
#  Will respond to PN/D339456 (but not PN/D0339456)
#                  PN/D039456
#              and PN/D39456  and 1 and 01
#  Utility --          5,146,634 6923014 0000001
#  Design --        D339,456 D321987 D000152
#  Plant --        PP08,901 PP07514 PP00003
#  Reissue --        RE35,312 RE12345 RE00007
#  Defensive Publication --        T109,201 T855019 T100001
#  Statutory Invention Registration --        H001,523 H001234 H000001
#  Re-examination --        RX29,194 RE29183 RE00125
#  Additional Improvement --        AI00,002 AI000318 AI00007
#  }

sub USPTO_country_known {
	my $self    = shift @_;
	my $country = shift;
	if ( 'US' eq uc($country) ) { return ('1790 on'); }
	else { carp 'US only!'; return undef }
}

sub USPTO_htm {
	my ( $self, $page_response ) = @_;
	my $request;
	my $request_text;
	if (   ( !$self->{'patent'}->{'doc_type'} )
		&& ( length( $self->{'patent'}{'number'} ) == 11 ) )
	{

		# Application  (11 digits)
		$request_text = 'http://appft1.uspto.gov/netacgi/nph-Parser?TERM1='
			. $self->{'patent'}{'number'}
			. '&Sect1=PTO1&Sect2=HITOFF&d=PG01&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.html&r=0&f=S&l=50';
		$request = HTTP::Request->new( 'GET' => $request_text );
		my $intermediate = $self->request($request);
		my $p            = HTML::TokeParser->new( \$intermediate->content );
		while ( my $token = $p->get_tag("a") ) {
			my $url  = $token->[1]{href} || "-";
			my $text = $p->get_trimmed_text("/a");
			if (   ( $url =~ m/$self->{'patent'}{'number'}/ )
				&& ( $text =~ m/$self->{'patent'}{'number'}/ ) )
			{

				#warn "fully qualified? '$url'\n";
				$request_text = 'http://appft1.uspto.gov/' . $url;
				$request = HTTP::Request->new( 'GET' => $request_text );
			}
		}
	}

#http://appft1.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PG01&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.html&r=1&f=G&l=50&s1=%2220010000044%22.PGNR.&OS=DN/20010000044&RS=DN/20010000044
	elsif ( $self->{'patent'}->{'doc_type'} ) {

		# Non-Utility Patent
		$request_text
			= "http://patft.uspto.gov/netacgi/nph-Parser?patentnumber=$self->{'patent'}->{'doc_type'}$self->{'patent'}{'number'}";
		$request = HTTP::Request->new( 'GET' => $request_text );
	}
	else {

		#Standard Utility Patent
		$request_text
			= "http://patft.uspto.gov/netacgi/nph-Parser?patentnumber=$self->{'patent'}{'number'}";
		$request = HTTP::Request->new( 'GET' => $request_text );
	}

	# print "\nAlmost $self->{'retrieved_identifier'}->{'number'} \n";
	my $response = $self->request($request)
		;    # use the agent to make the request and get the response
	         # print "\there\n";
	if ( $response->is_success ) {
		my $html = $response->content;

		# print "\n$html\n";
		my $p = HTML::HeadParser->new;
		$p->parse( $response->content );
		my $entry;
		if ( $entry = $p->header('Refresh') )
		{ # carp "no refresh seen via '$self->{'patent'}{'number'}' in \n'$html' " }
			$entry =~ s/^.*?URL=//;
			$entry = 'http://patft.uspto.gov' . $entry;

			# print "$entry\n";
			$request = new HTTP::Request( 'GET' => "$entry" )
				or carp "bad refresh";
			$response = $self->request($request);
			$html     = $response->content;
		}

		if ( $html =~ m/No patents have matched your query/ ) {
			$page_response->set_parameter( 'is_success', undef );
			$page_response->set_parameter( 'message',
				'No patents have matched your query' )
				;    # No patents have matched your query
			return $page_response;
		}

		unless ( $html
			=~ s/.*?<html>.*?<head>/<html>\n<head><!-- Modified by perl module WWW::Patent::Page from information provided by http:\/\/www.uspto.gov ; dedicated to public ; use at own risk -->\n<title>US /is
			)
		{
			carp "header weird A \n";
		}
		unless ( $html
			=~ s/<head>.*(<title>)\D+/<head><!-- Modified by perl module WWW::Patent::Page from information provided by http:\/\/www.uspto.gov ; dedicated to public ; use at own risk -->\n<title>US /is
			)
		{
			carp "header weird B \n";
		}
		unless ( $html =~ s/<title>\D+/<title>US /is ) {
			carp "header weird C \n$html\n";
		}

		#warn " type is $self->{'patent'}->{'doc_type'}'\n";
		unless ( $html =~ s/<body.*?<hr>/<body><HR>/is ) {
			carp "front weird  \n$html\n";
		}
		unless ( $html =~ s/(.*)<hr>(.*)body>/$1<\/body>/is ) {
			carp "end weird  \n$html\n";
		}
		$html
			=~ s|"/netacgi/nph-Parser|"http://patft.uspto.gov/netacgi/nph-Parser|gi;
		$page_response->set_parameter( 'content', $html );
		return $page_response;
	}
	else {
		carp "Unsuccessful response: \n'"
			. $response->status_line
			. "'\n\nfrom request:\n'$request_text'\n";
		return undef;
	}
}

sub USPTO_tif {
	my ( $self, $page_response ) = @_;
	my ( $request, $base, $zero_fill );

	if ( $self->{'patent'}{'number'} =~ m/(0|1|2|3|4)\d$/ ) {

		# 0-4 is on one server, 5-9 is on another
		$base = 'patimg1.uspto.gov';
	}
	else { $base = 'patimg2.uspto.gov'; }
	my $zerofill = sprintf '%0.8u', $self->{'patent'}{'number'};

	# print "\nZerofill: $zerofill\n";
	if ( $self->{'patent'}->{'doc_type'} ) {
		$request = HTTP::Request->new( 'GET' =>
				"http://$base/.piw?Docid=$self->{'patent'}->{'doc_type'}$zerofill\&idkey=NONE"
		);
	}
	else {
		$request = HTTP::Request->new(
			'GET' => "http://$base/.piw?Docid=$zerofill\&idkey=NONE" );
	}

	# print "\nAlmost $self->{'retrieved_identifier'}->{'number'} \n";
	my $response = $self->request($request);

	my $html = $response->content;

	{    # page numbers

		if ( $html =~ m/NumPages=(\d+)/ ) {
			$page_response->set_parameter( 'pages', $1 );

		}
		elsif ( $html =~ m/(\d+)\s+of\s+(\d+)\s+pages/ ) {
			$page_response->set_parameter( 'pages', $2 );

			# print "Pages: $2\n";
		}
		else {
			carp
				"no maximum page number found in $self->{'patent'}{'country'}$self->{'patent'}{'number'}: \n$html";
		}
	}
	my $p = HTML::TokeParser->new( \$html );
	my $url;
	my $token;
FINDPAGE: while ( $token = $p->get_tag("a") ) {
		$url = $token->[1]{href} || "-";    #very strange or construct ???
		if ( $url =~ m/$self->{'patent'}{'number'}/ ) { last FINDPAGE; }

		# print "$url\n";
	}
	undef $p;

	$url =~ s/PageNum=(\d+)/PageNum=$self->{'patent'}{'page'}/;
#	$url = "http://$base$url";

#	warn "URL = '$url'\n";
	#	 exit;
	$request = new HTTP::Request( 'GET' => "$url" )
		or carp "bad numbered page $self->{'patent'}{'page'} fetch $url";
	$response = $self->request($request);
	$html     = $response->content;

	$p = HTML::TokeParser->new( \$html );

FINDPAGE: while ( $token = $p->get_tag("embed") ) {
		$url = $token->[1]->{src} || "-";
		if ( $url =~ m/image\/tiff/ ) { last FINDPAGE; }
	}

	# get tiff image
	# $url = "http://$base$url";
	$request = new HTTP::Request( 'GET' => "$url" )
		or carp "Coudn't retrieve the tiff image fetch $url";
	$response = $self->request($request);

	# print "\nPage response\n$response->content\n\n";
	$page_response->set_parameter( 'content', $response->content );

	return $page_response;
}

sub USPTO_pdf {
	my ( $self, $page_response ) = @_;
	my ( $request, $base, $zero_fill );

	my $tempdir = $self->{'patent'}->{'tempdir'}
		if ( $self->{'patent'}->{'tempdir'} );
	my $fn_template = $self->{'patent'}->{'doc_id'} . "_XXXX";

	my $pdf_file = new File::Temp(
		TEMPLATE => $fn_template,
		DIR      => $tempdir,
		SUFFIX   => '.pdf',
		UNLINK   => 1,
	);
	my $pdf_fn = $pdf_file->filename;
	my $pdf    = new PDF::API2();
	print $pdf_file $pdf->stringify;
	close $pdf_file;

	my $currenttime = localtime();
	my $short_id
		= $self->{'patent'}{'country'} . $self->{'patent'}->{'number'};

#	my $pdf = new PDF::API2(-file => "$tempdir/$self->{'patent'}{'doc_id'}".".pdf");
#	my $pdf = new PDF::API2(-file => $pdf_fn);
	$pdf = PDF::API2->open($pdf_fn);
	my %h = $pdf->info(
		'Author'       => "Programatically Produced from Public Information",
		'CreationDate' => $currenttime,
		'ModDate'      => $currenttime,
		'Creator'      => "WWW::Patent::Page::USPTO_pdf",
		'Producer'     => "US Patent Office and PDF::API2",
		'Title'        => "$short_id",
		'Subject'      => "patent",
		'Keywords'     => "$short_id WWW::Patent::Page"
	);
	my $page = $pdf->page();
	$page->mediabox('A4');


	if ( $self->{'patent'}{'number'} =~ m/(0|1|2|3|4)\d$/ ) {

		# 0-4 is on one server, 5-9 is on another
		$base = 'patimg1.uspto.gov';
	}
	else { $base = 'patimg2.uspto.gov'; }
	my $zerofill = sprintf '%0.8u', $self->{'patent'}{'number'};

	if ( $self->{'patent'}->{'doc_type'} ) {
		$request = HTTP::Request->new( 'GET' =>
				"http://$base/.piw?Docid=$self->{'patent'}->{'doc_type'}$zerofill\&idkey=NONE"
		);
	}
	else {
		$request = HTTP::Request->new(
			'GET' => "http://$base/.piw?Docid=$zerofill\&idkey=NONE" );
	}

	my $response = $self->request($request);

	my $html = $response->content;
#	warn "html = $html\n"; 
	{    # page numbers

		if ( $html =~ m/NumPages=(\d+)/ ) {
			$page_response->set_parameter( 'pages', $1 );
		}
		elsif ( $html =~ m/(\d+)\s+of\s+(\d+)\s+pages/ ) {
			$page_response->set_parameter( 'pages', $2 );

			# print "Pages: $2\n";
		}
		else {
			carp
				"no maximum page number found in $self->{'patent'}{'country'}$self->{'patent'}{'number'}: \n$html";
		}
	}
	my $p = HTML::TokeParser->new( \$html );
	my $url;
	my $token;
FINDPAGE: while ( $token = $p->get_tag("a") ) {
		$url = $token->[1]{href} || "-";    #very strange or construct ???
		if ( $url =~ m/$self->{'patent'}{'number'}/ ) { last FINDPAGE; }
	}

	undef $p;

	if ( defined( $self->{'patent'}{'page'} ) ) {
		$url =~ s/PageNum=(\d+)/PageNum=$self->{'patent'}{'page'}/;
	}

#	print "\n\$self->{'patent'}->{'page'} = '$self->{'patent'}->{'page'}'  |$url = '$url' \@ 391 \n";

	#$url = "http://$base$url";
	$request = new HTTP::Request( 'GET' => "$url" )
		or carp "bad numbered page $self->{'patent'}{'page'} fetch $url";
	$response = $self->request($request) or carp "bad request" ;
	$html     = $response->content;

# open( my $fh,">", "1.html"); print $fh $html; close $fh; 

	$p = HTML::TokeParser->new( \$html );
# warn "base = $base, URL1 = '$url'\n";	

$url = ""; 

FINDIMAGE: while($token = $p->get_tag("a") ) {  
	$url = $token->[1]->{href} || "-" ; 
	# warn "\ntoken 1 href = ", $token->[1]->{href} , "\n" ; 
	if ($url =~ m/View\+first\+page/) {last FINDIMAGE; } 
}
# warn "URL2 = '$url'\n";	


	$request = new HTTP::Request( 'GET' => "$url" )
		or carp "bad numbered page $self->{'patent'}{'page'} fetch $url";
	$response = $self->request($request) or carp "bad request" ;
	$html     = $response->content;
	$p = HTML::TokeParser->new( \$html );

#open( my $fh1,">", "2.html"); print $fh1 $html; close $fh1; 


FINDTIF: while ( $token = $p->get_tag("embed") ) {
		# print "\ntoken = ", Dumper($token), "\n" ; 
		$url = $token->[1]->{src} || "-";
		if ( $url =~ m/tif$/ ) { last FINDTIF; }
	}

	# get tiff image
	$url = "http://$base$url"; $url =~ s/\n//; 
	if ( defined( $self->{'patent'}{'page'} ) ) {
		$url =~ s/PageNum=(\d+)/PageNum=$self->{'patent'}{'page'}/;
	}

# warn "URL3 = '$url'\n";	
	my $tif_url = $url;
	$request = new HTTP::Request( 'GET' => "$url" )
		or carp "Coudn't retrieve the tiff image fetch $url";


	# prepare to store tif image
	my $pat_page = 1;
	if ( defined( $self->{'patent'}{'page'} ) ) {
		$pat_page = $self->{'patent'}{'page'};
	}

#	print "\n\$self->{'patent'}->{'doc_id'} = '$self->{'patent'}->{'doc_id'}' \@ 413 \n";

	$fn_template = $self->{'patent'}->{'doc_id'} . "_p" . $pat_page . "_XXXX";
#	warn "TEMPLATE => $fn_template,		DIR      => $tempdir\n" ; 
	my $temp_tif = new File::Temp(
		TEMPLATE => $fn_template,
		DIR      => $tempdir,
		SUFFIX   => '.tif',
		UNLINK   => 1,
	);

	my $done = 0;
	my $trys = 0;
	if ( !$done and $trys < 5 ) {
		$response = $self->request($request);
		$trys++;
		if ( $response->is_success and $response->content ) {
			print $temp_tif $response->content;
#		open( my $th,">", "2.html"); print $th $response->content; close $th; 

			$done = 1;
		}
		else {
			carp
				"attempt $trys response failed or content empty, no temporary tiff can be made- possibly network problem or timeout, will try again";
		}
	}
	else { carp "too many attempts, giving up."; return (0); }

	#	close $temp_tif;

	# convert to pdf
	my $gfx = $page->gfx();
	# print Dumper($temp_tif); 
	$gfx->image( $pdf->image_tiff($temp_tif), 0, 0, 0.23 );

	# one page only
	if ( $self->{'patent'}{'page'} ) {
		$page_response->set_parameter( 'content', $pdf->stringify );
		return $page_response;
	}

	# retrieve all pages
	my $maxpage = $page_response->get_parameter('pages');
	for ( my $i = 2; $i <= $maxpage; $i++ ) {
		$tif_url =~ s/PageNum=(\d+)/PageNum=$i/;
		$request = new HTTP::Request( 'GET' => "$tif_url" )
			or carp "Couldn't retrieve the tiff image fetch $tif_url";
		$response = $self->request($request);

		# store tif image
		$fn_template = $self->{'patent'}->{'doc_id'} . "_p" . $i . "_XXXX";
		$temp_tif    = new File::Temp(
			TEMPLATE => $fn_template,
			DIR      => $tempdir,
			SUFFIX   => '.tif',
			UNLINK   => 1,
		);
		print $temp_tif $response->content;

		#	close $temp_tif;

		# convert to pdf
		$page = $pdf->page(0);
		$gfx  = $page->gfx();
		$gfx->image( $pdf->image_tiff($temp_tif), 0, 0, 0.23 );
	}

	# return pdf as string
	$page_response->set_parameter( 'content', $pdf->stringify );

	#	$pdf->save;
	#	$pdf->saveas("$tempdir/$self->{'patent'}->{'doc_id'}".".pdf");

	return $page_response;
}

sub USPTO_terms {
	my ($self) = @_;
	return (
		"WWW::Patent::Page utilizes the USPTO web site.\n
Refer to http://www.USPTO.gov for terms and conditions of use of that site.

Note that as of September 1, 2004,
http://www.uspto.gov/patft/help/notices.htm and the like state in part:

These databases are intended for use by the general public.
Due to limitations of equipment and bandwidth, they are not
intended to be a source for bulk downloads of USPTO data.
Bulk data may be purchased from USPTO at cost (see the USPTO
Products and Services Catalog). Individuals, companies,
IP addresses, or blocks of IP addresses who, in effect,
deny service to the general public by generating unusually
high numbers (1000 or more) of daily database accesses
(searches, pages, or hits), whether generated manually or
in an automated fashion, may be denied access to these
servers without notice.

Note at http://www.uspto.gov/patft/help/accpat.htm :

If you can access the main PTO Web site, but cannot access any
of the Patent Grant Database Quick Search, Advanced Quick Searching,
or Patent Number Searching pages, your workstation or organization
may have been denied access to the Web Patent Databases pursuant
to the policy stated at the top of this page. To determine if you
have been denied access, you can check the Denied List for your
computer's IP address. http://www.uspto.gov/patft/help/denied.htm

(Your IP address is the only means by which you are known to the
PTO servers -- server logs do not contain your email address or
any other personal identifying information. If you do not know
your computer's IP address because you are behind a firewall, do
not have a fixed IP address, or for any other reason, you can find
your current IP address by using an 'IP reflector,' such as
http://www2.simflex.com/ip.shtml or http://www.dslreports.com/ip.)

If you are an individual whose individual IP address has been
denied access: to seek to have your access restored, please send
email including your workstation and firewall or gateway IP addresses
(consult with your network administrators if necessary), and describing
the steps you have taken or will take to insure that future violations
of the USPTO access policy will not occur, to the Database Help Desk at
www\@uspto.gov.

If you are a member or employee of an organization which has been
denied access: please do not send individual email to PTO. Instead,
please have your network administrator or a person holding authority
over your organization\'s network operations send email including your
firewall, gateway, or workstation IP addresses, and describing the steps
you have taken or will take to insure that future violations of the USPTO
access policy will not occur, to the Database Help Desk at www\@uspto.gov.

For all other content-related matters, please send email to the Database
Help Desk at www\@uspto.gov

Note at http://www.uspto.gov/patft/help/images.htm

Patent images must  be retrieved from the database one page at a time.
This is necessary since patents can be as long as 5,000 pages, and the
resources required to allow downloading such 'jumbo' patents are not
available. Users employing third-party software which downloads multiple
pages of a patent at once may find this practice subjects them to denial
of access to the databases if they exceed PTO's maximum allowable
activity levels.

"
	);
}
1;

__END__

=head1 WWW::Patent::Page::USPTO

support the use of the United States Patent and Trademark Office web site

=cut

=head2 methods

set up the methods available for each document type

=cut

=head2 USPTO_tif

tif capture and manipulation

This is where the fun stuff happens.  TODO:  append the tiffs pagewise into a pdf; provide USPTO_pdf .

=cut

=head2 USPTO_pdf

tif capture and manipulation into a PDF

Code kindly written by Dr. Hermann Schier.
=cut

=head2 USPTO_htm

htm capture and manipulation

This is where the fun stuff happens.  TODO:  better error handling .

=cut

=head2 USPTO_terms

terms of use

=cut


=head2 USPTO_country_known

hash with keys of two letter acronyms, values of the dates covered

=cut

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Wanda B. Anon wanda_b_anon@yahoo.com . 
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the Artistic License version 2.0 
or above ( http://www.perlfoundation.org/artistic_license_2_0 ) .

=cut


