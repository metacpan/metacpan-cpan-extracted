
package WWW::Patent::Page::MICROPATENT;
use strict;
use warnings;
use diagnostics;
use Carp qw(carp croak cluck confess);
use subs
	qw( methods MICROPATENT_login MICROPATENT_country_known MICROPATENT_pdf  MICROPATENT_html  MICROPATENT_xml    MICROPATENT_terms  )
	;    # MICROPATENT_xml_tree
use LWP::UserAgent 2.003;
require HTTP::Request;
use HTTP::Request::Common;
use HTML::TokeParser;
use URI;
use HTML::Form;
use URI;

$| = 1;

#use PDF::API2 2.000;
use WWW::Patent::Page::Response;
our ( $VERSION, @ISA, %_country_known );
$VERSION = "0.07";

sub _data_hash_from_arrays {

	# my $hash_ref = hash_from_arrays( \@keys, \@vals );
	#perldoc perldata

	#@numbers=(4,5,6);
	#@keys = qw/size atime ctime/;
	#map{$myHash{$_}=$numbers[$i];$i++}@keys;

	my %title2key = (
		'Patent/Publication No.'            => 'identification',
		'Country Code'                      => 'country',
		'Document Kind'                     => 'kind',
		'Publication Year'                  => 'publication_year',
		'Date of Publication'               => 'publication_date',
		'Application Date'                  => 'application_date',
		'Application No.'                   => 'application_number',
		'US Class (primary)'                => 'class_us_primary',
		'US Classes (all)'                  => 'class_us',
		'International Class (primary)'     => 'class_international_primary',
		'IPC Classes'                       => 'class_ipc',
		'ECLA'                              => 'ecla',
		'Assignee / Applicant'              => 'assignee',
		'Standardized Assignee / Applicant' => 'assignee_standardized',
		'Inventor (first only)'             => 'inventor_first',
		'Inventor(s)'                       => 'inventor',
		'Priority Year(s)'                  => 'priority_year',
		'Priority Date'                     => 'priority_date',
		'Priority Country'                  => 'priority_country',
		'Priority Number'                   => 'priority_identification',
		'PCT Application Number' => 'application_pct_identification',
		'Patent Citations'       => 'citation_patent',
		'Non-Patent Citations'   => 'citation_non_patent',
		'Related Applications'   => 'application_related',
		'Agent'                  => 'agent',
		'Correspondent'          => 'correspondent',
		'Examiner'               => 'examiner',
		'Designated States'      => 'states_designated',
		'Title'                  => 'title_english',
		'French Title'           => 'title_french',
		'German Title'           => 'title_german',
		'Spanish Title'          => 'title_spanish',
		'Abstract'               => 'abstract_english',
		'French Abstract'        => 'abstract_french',
		'German Abstract'        => 'abstract_german',
		'Spanish Abstract'       => 'abstract_spanish',
		'English Claims'         => 'claims_english',
		'French Claims'          => 'claims_french',
		'German Claims'          => 'claims_german',
		'Spanish Claims'         => 'claims_spanish',
		'Family Members'         => 'family_identification',
		'Legal Status'           => 'status',
		'Litigations US'         => 'litigation_US',
		'Oppositions EP'         => 'oppositions_EP',
	);

	my ( $keys, $values ) = @_;
	croak "Mismatched number of keys and values" if @$keys != @$values;

	my %hash;

	# @hash{ @$keys } = @$values;
	my $i = 0;
	map { $hash{ $title2key{$_} } = ${$values}[$i]; $i++ } @{$keys};
	return \%hash;
}

sub methods {
	return (
		'MICROPATENT_login' => \&MICROPATENT_login,
		'MICROPATENT_pdf'   => \&MICROPATENT_pdf,
		'MICROPATENT_html'  => \&MICROPATENT_html,
		'MICROPATENT_xml'   => \&MICROPATENT_xml,
		'MICROPATENT_data'  => \&MICROPATENT_data,

		#		'MICROPATENT_xml_tree'      => \&MICROPATENT_xml_tree,
		'MICROPATENT_country_known' => \&MICROPATENT_country_known,

		#		'MICROPATENT_parse_doc_id'        => \&MICROPATENT_parse_doc_id,
		'MICROPATENT_terms' => \&MICROPATENT_terms,
	);
}

sub MICROPATENT_login {
	my $self = shift;
	my ($username) = shift
		|| $self->{patent}->{office_username}
		|| warn 'no MicroPatent username';
	my ($password) = shift
		|| $self->{patent}->{office_password}
		|| warn 'no MicroPatent password';

	#	print " HI! username = $username \n";
	our ( $url, $request, $http_response );
	$url = HTTP::Request->new(
		POST => "http://www.micropat.com/cgi-bin/login" );
	$url->content(
		"password=$password&patservices=PatentWeb%20Services&loginname=$username&"
	);
	$http_response = $self->request($url);
	my $last_request = $http_response->base;

	#	print $last_request ;
	if ( $last_request =~ m/(\d\d\d\d\d\d\d\d\d\d+)/ ) {
		$self->{'patent'}{'session_token'} = $1;
	}
	else {
		carp
			"Login response '$last_request' from Request 'http://www.micropat.com/cgi-bin/login' has no session id  with status line "
			. $http_response->status_line
			. "and string \n\n"
			. $http_response->as_string
			. "\n\n and content \n\n"
			. $http_response->content
			. "\n\n  Bummer.\n";
		return ($http_response);
	}
}

sub MICROPATENT_country_known {
	my $self = shift;
	my ($country_in_question) = shift;
	if ( exists $_country_known{$country_in_question} ) {
		return ( $_country_known{$country_in_question} );
	}
	else {
		return (undef);
	}
}

sub MICROPATENT_xml {
	my ($self) = @_;
	my (   $url,       $request, $http_response, $base,
		$zero_fill, $html,    $p,             $referer,
		%bookmarks, $first,   $last,          $screenseq,
		$match
	);

	# sanity checks
	$self->{'message'} = '';
	if ( !$self->{'patent'}{'country'} ) {
		$self->{'message'}
			= "country not specified (or doc_id has unrecognized country)";
		$self->{'is_success'} = 0;
		return ($self);
	}
	if ( !&MICROPATENT_country_known( $self, $self->{'patent'}{'country'} ) )
	{    #unrecognized country
		$self->{'message'}
			= "country '" . $self->{'patent'}{'country'} . "' unrecognized";
		$self->{'is_success'} = 0;
		return ($self);
	}

	if ( !$self->{'patent'}{'session_token'} ) {
		$self->{'message'}    = "login token not available";
		$self->{'is_success'} = 0;
		return ($self);
	}

	if ( !$self->{'patent'}{'number'} ) {
		$self->{'message'}    = "number '$self->{'patent'}{'number'}' bad";
		$self->{'is_success'} = 0;
		return ($self);
	}
	my $number   = $self->{'patent'}{'number'};
	my $short_id = $self->{'patent'}{'country'} . $number;
	my $id;
	if ( defined $self->{'patent'}{'kind'} ) {
		$id = $short_id . $self->{'patent'}{'kind'};
	}
	else {
		$id = $short_id;
	}
	$request = POST "http://www.micropat.com/perl/sunduk/avail-check.pl",
		[     'ticket'        => "$self->{'patent'}{'session_token'}",
		'familylist'    => "",
		'patnumtaglist' => "$id",
		'textonly.x'    => "60",
		'textonly.y'    => "9",
		];

	$http_response = $self->request($request);
	$html = $http_response->content;

	# print "\n$html\n";
	if (   $html =~ m{  value \s* = \s* "	(\d\d\d\d\d\d\d+\-0) "   #   			
		}xms
		)
	{
		$match = $1;
	}
	else {
		$self->{'message'}
			= "no match found e.g. match-1-0 value 12345678-0 , do not know how to continue \n$html\n no match found e.g. match-1-0 value 12345678-0 , do not know how to continue";
		$self->{'is_success'} = 0;
		return ($http_response);
	}

	if (   $html =~ m{ name \s* = \s* "screenseq" \s* # 
					   value \s* = \s* "(\d+)"   #   			
		}xms
		)
	{
		$screenseq = $1;
	}
	else {
		$self->{'message'}
			= "no screenseq found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = 0;
		return ($http_response);
	}

	$request = POST "http://www.micropat.com/perl/sunduk/order-submit.pl",
		[     'ticket'            => "$self->{'patent'}{'session_token'}",
		'userref'           => "$id",
		'bundle_format'     => "as_ordered",
		'screenseq'         => "$screenseq",
		'del_CAPS_standard' => "DOWNLOADXML",
		'match-1-0'         => "$match",
		];
	$http_response = $self->request($request);
	while ( $http_response->content
		!~ m { (http://www.micropat.com:80/get-file/\d+/)  }xms )
	{
		my @forms = HTML::Form->parse($http_response);
		if ( !$forms[0] ) {
			croak( "html page does not have the expected form:\n"
					. $http_response->content() );
		}

		$http_response = $self->request( $forms[0]->click );
	}

	#	print $http_response->content;

	$html = $http_response->content;
	if ( $html
		=~ m{ (http://www.micropat.com:80/get-file/\d+/[^\.]+\.xml)  }xms )
	{
		$url = $1;
	}
	else {
		$self->{'message'}
			= "no url to xml found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = 0;
		return ($http_response);
	}
	$request       = GET "$url";
	$http_response = $self->request($request);
	return ($http_response);
}

sub MICROPATENT_pdf {
	my ($self) = @_;
	my (   $url,       $request, $http_response, $base,
		$zero_fill, $html,    $p,             $referer,
		%bookmarks, $first,   $last,          $screenseq,
		$del_CAPS ,
		$match
	);

	# sanity checks
	$self->{'message'} = '';
	if ( !$self->{'patent'}{'country'} ) {
		$self->{'message'}
			= "country not specified (or doc_id has unrecognized country)";
		$self->{'is_success'} = 0;
		return ($self);
	}
	if ( !&MICROPATENT_country_known( $self, $self->{'patent'}{'country'} ) )
	{    #unrecognized country
		$self->{'message'}
			= "country '" . $self->{'patent'}{'country'} . "' unrecognized";
		$self->{'is_success'} = 0;
		return ($self);
	}

	if ( !$self->{'patent'}{'session_token'} ) {
		$self->{'message'}    = "login token not available";
		$self->{'is_success'} = 0;
		return ($self);
	}

	if ( !$self->{'patent'}{'number'} ) {
		$self->{'message'}    = "number '$self->{'patent'}{'number'}' bad";
		$self->{'is_success'} = 0;
		return ($self);
	}
	my $number   = $self->{'patent'}{'number'};
	my $short_id = $self->{'patent'}{'country'} . $number;
	my $id;
	if ( defined $self->{'patent'}{'kind'} ) {
		$id = $short_id . $self->{'patent'}{'kind'};
	}
	else {
		$id = $short_id;
	}
	$request = POST "http://www.micropat.com/perl/sunduk/avail-check.pl",
		[     'ticket'        => "$self->{'patent'}{'session_token'}",
		'familylist'    => "",
		'patnumtaglist' => "$id",
		'images.x'      => "60",
		'images.y'      => "9",
		];

	$http_response = $self->request($request);
	$html = $http_response->content;
#$self->{'patent'}{2} = $http_response->content ; 
	

	if (   $html =~ m{  value \s* = \s* "	(\d\d\d\d\d\d\d+\-0) "   #   			
		}xms
		)
	{
		$match = $1;
	}
	else {
		$self->{'message'}
			= "no match found e.g. match-1-0 value 12345678-0 , do not know how to continue \n$html\n no match found e.g. match-1-0 value 12345678-0 , do not know how to continue";
		$self->{'is_success'} = 0;
		return ($http_response);
	}

	if (   $html =~ m{ name \s* = \s* "screenseq" \s* # 
					   value \s* = \s* "(\d+)"   #   			
		}xms
		)
	{
		$screenseq = $1;
	}
	else {
		$self->{'message'}
			= "no screenseq found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = 0;
		return ($http_response);
	}

	if (   $html =~ m{ name \s* = \s* "del_CAPS_(\w+)" }xms
		)
	{
		$del_CAPS = $1;
	}
	else {
		$self->{'message'}
			= "no del_CAPS found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = 0;
		return ($http_response);
	}

	# print "\n4\n";

	$request = POST "http://www.micropat.com/perl/sunduk/order-submit.pl",
		[     'ticket'            => "$self->{'patent'}{'session_token'}",
		'userref'           => "id",
		'bundle_format'     => "normalized",
		'screenseq'         => "$screenseq",
		'del_CAPS_'.$del_CAPS => "DOWNLOADCONCATPDF",  #either special or standard 
		'match-1-0'         => "$match",
		];
	$http_response = $self->request($request);
#	$self->{'patent'}{3} = $http_response->content ; 
	while ( $http_response->content
		=~ m {order-detail\.pl}xms )
	{
		my $count++;
		my @forms = HTML::Form->parse($http_response);
		if ( !$forms[0] ) {
			carp( "html page does not have the expected form:\n"
					. $http_response->content() );
			$http_response->is_success = 0;
			return $http_response ;
		}

		$http_response = $self->request( $forms[0]->click );
		if ($count >= 5 ) {  # give micropatent time to find it...
			carp( "html page does not have the expected form after 5 attempts:\n"
					. $http_response->content() );		
			$http_response->is_success = 0;
			return $http_response ;
		}
	}
	$html = $http_response->content;
	#print "\n5- here it is:\n$html\n";
	if ( $html
		=~ m{ (http://www.micropat.com:80/get-file/\d+/[^\.]+\.pdf)  }xms )
	{
		$url = $1;
	}
	else {
		$self->{'message'}
			= "no url to PDF found, do not know how to continue \n$html\n";
		$self->{'is_success'} = 0;
		return ($self);
	}
	$request       = GET "$url";
	$http_response = $self->request($request);
	return ($http_response);
}

sub MICROPATENT_data {
	my ($self) = @_;
	my (   $url,       $request,   $http_response, $base,
		$zero_fill, $html,      $p,             $input,
		$referer,   %bookmarks, $first,         $last,
		$screenseq, $match
	);

	# sanity checks
	$self->{'message'} = '';
	if ( !$self->{'patent'}{'country'} ) {
		$self->{'message'}
			= "country not specified (or doc_id has unrecognized country)";
		$self->{'is_success'} = 0;
		return ($self);
	}
	if ( !&MICROPATENT_country_known( $self, $self->{'patent'}{'country'} ) )
	{    #unrecognized country
		$self->{'message'}
			= "country '" . $self->{'patent'}{'country'} . "' unrecognized";
		$self->{'is_success'} = 0;
		return ($self);
	}

	#	print "\n3.1\n";
	if ( !$self->{'patent'}{'session_token'} ) {
		$self->{'message'}    = "login token not available";
		$self->{'is_success'} = 0;
		return ($self);
	}

	# print "\n3.2\n";
	if ( !$self->{'patent'}{'number'} ) {
		$self->{'message'}    = "number '$self->{'patent'}{'number'}' bad";
		$self->{'is_success'} = 0;
		return ($self);
	}
	my $number   = $self->{'patent'}{'number'};
	my $short_id = $self->{'patent'}{'country'} . $number;
	my $id;
	if ( defined $self->{'patent'}{'kind'} ) {
		$id = $short_id . $self->{'patent'}{'kind'};
	}
	else {
		$id = $short_id;
	}
	$request = POST "http://www.micropat.com/cgi-bin/preorder",
		[     'ticket'        => "$self->{'patent'}{'session_token'}",
		'familylist'    => "",
		'patnumtaglist' => "$id",
		'worksheet.x'   => "60",
		'worksheet.y'   => "9",
		];
	$http_response = $self->request($request);
	my @forms
		= HTML::Form->parse($http_response);    # asks for the worksheet name
	if ( !$forms[0] ) {
		confess( "html page does not have the expected form:\n"
				. $http_response->content() );
	}
	my @names = $forms[0]->param;               # returns all input names

	#	carp "form 0 has input names @names";
	$forms[0]->param( 'worksheet_name',
		'delete_me_' . time() . '_' . int( rand(1000) ) )
		;                                       #give a worksheet name
	$http_response = $self->request( $forms[0]->click )
		;    # returns the main worksheet selection page
#   	@forms = HTML::Form->parse( $http_response );
# gave a moved page.... 302 ... the location is in the headers, so hopefully LWP follows it without problems.
#
	@forms = HTML::Form->parse($http_response);
	if ( !$forms[0] ) {
		confess( "html page does not have the expected form:\n"
				. $http_response->content() );
	}

	$input = $forms[0]->find_input('cb-1');
	$input->readonly(0);
	$forms[0]->param( 'cb-1', 'on' );    # check the first patent

	$input = $forms[0]->find_input('action');
	$input->readonly(0);
	$forms[0]->param( 'action', 'export_ft' );    # check the first patent
	     #above sets up request worksheets/process.pl
	$http_response = $self->request( $forms[0]->click );    #
	# intermediate 302 document moved
	@forms = HTML::Form->parse($http_response)
		;    # now we want to set up order-submit-export.pl
	my $data
		= 'Patent/Publication No.,Country Code,Document Kind,Publication Year,Date of Publication,Application Date,Application No.,US Class (primary),US Classes (all),International Class (primary),IPC Classes,ECLA,Assignee / Applicant,Standardized Assignee / Applicant,Inventor (first only),Inventor(s),Priority Year(s),Priority Date,Priority Country,Priority Number,PCT Application Number (US and EP),Patent Citations (US EP WO),Non-Patent Citations (US EP WO),Related Applications (US and recent EP),Agent (US WO),Correspondent,Examiner (US Only),Designated States (EP and PCT),Title,French Title (Some EP WO),German Title (all DE; some EP WO),Spanish Title (some WO),Abstract,French Abstract (some EP-A WO; all EP-B),German Abstract (all DE; some EP WO),Spanish Abstract (WO),English Claims (all US EP-B; some WO EP-A),French Claims (all EP-B; some EP-A WO),German Claims (all DE EP-B; some EP-A WO),Spanish Claims (some WO),Family Members,Legal Status,Litigations US,Oppositions EP,';
	$input = $forms[0]->find_input('fltx_fields_sel');
	$input->readonly(0);
	$input = $forms[0]->find_input('format');
	$input->readonly(0);

	$forms[0]->param( 'fltx_fields_sel', $data );   # set up the data requests

	#	$forms[0]->param('submit.x' , 46);
	#	$forms[0]->param('submit.y' , 17);
	$forms[0]->param( 'format', 'EXPORT_FLTXFIELDS_TSV' );
	$http_response = $self->request( $forms[0]->click );
	# first we get the refresh form.
	# then we get the processing page, with form 0 to update it.

	@forms = HTML::Form->parse($http_response);
	if ( !$forms[0] ) {
		confess( "html page does not have the expected form:\n"
				. $http_response->content() );
	}
	;    # now we want to set up order-submit-export.pl
	$http_response->content('');    #set content to nothing
	my $stop_count;
	while ($http_response->content !~ m{http://www.micropat.com:80/get-file/} )
	{
		$stop_count++;
		if ( $stop_count > 15 ) {
			carp "too many attempts to reload "
				. $forms[0]->dump()
				. " so bailing out. ";
			return ($self);
		}
		$http_response = $self->request( $forms[0]->click );
	}

	$p = HTML::TokeParser->new( \$http_response->content() )
		;    #notice reference
	 #carp "stop_count = $stop_count; here is the content:\n". $http_response->content ;
FINDURL: while ( my $token = $p->get_tag("a") ) {
		$url = $token->[1]{href} || "-";    #very strange or construct ???
		                                    #print "url = '$url'\n";
		if ( $url
			=~ m{(http://.*micropat.*\.com.*/get-file/\d+/export_\d+\.txt)} )
		{
			last FINDURL;
		}

		#print "\nnot good enough.\n\n" ;
	}

	#	$url = $1;
	#print "After $stop_count tries, got a good url: $url\n";
	my $url_object = HTTP::Request->new( GET => $url );
	$http_response = $self->request($url_object)
		;    # this should be the tab separated text file
	#   	carp "last one!/n".$http_response->content;
	$http_response->{'is_success'} = 'data successfully retrieved';
	my ( $title, $datal ) = split( qr/\n/, $http_response->content );
	$datal =~ s/"//g;

	#	print "\$title = '$title'\n";
	#	print "\$datal = '$datal'\n";
	my (@title) = split( qr/\t/, $title );
	my (@data)  = split( qr/\t/, $datal );

	#	print &_data_hash_from_arrays(\@title,\@data);
	my $data_hash_ref = &_data_hash_from_arrays( \@title, \@data );
	$http_response->{'data'} = $data_hash_ref ;
	$http_response->content($data_hash_ref); 
	return ($http_response);
}

sub MICROPATENT_html {
	my ($self) = @_;
	my (   $url,       $request, $http_response, $base,
		$zero_fill, $html,    $p,             $referer,
		%bookmarks, $first,   $last,          $screenseq,
		$match
	);

	# sanity checks
	$self->{'message'} = '';
	if ( !$self->{'patent'}{'country'} ) {
		$self->{'message'}
			= "country not specified (or doc_id has unrecognized country)";
		$self->{'is_success'} = 0;
		return ($self);
	}
	if ( !&MICROPATENT_country_known( $self, $self->{'patent'}{'country'} ) )
	{    #unrecognized country
		$self->{'message'}
			= "country '" . $self->{'patent'}{'country'} . "' unrecognized";
		$self->{'is_success'} = 0;
		return ($self);
	}

	#	print "\n3.1\n";
	if ( !$self->{'patent'}{'session_token'} ) {
		$self->{'message'}    = "login token not available";
		$self->{'is_success'} = 0;
		return ($self);
	}

	# print "\n3.2\n";
	if ( !$self->{'patent'}{'number'} ) {
		$self->{'message'}    = "number '$self->{'patent'}{'number'}' bad";
		$self->{'is_success'} = 0;
		return ($self);
	}
	my $number   = $self->{'patent'}{'number'};
	my $short_id = $self->{'patent'}{'country'} . $number;
	my $id;
	if ( defined $self->{'patent'}{'kind'} ) {
		$id = $short_id . $self->{'patent'}{'kind'};
	}
	else {
		$id = $short_id;
	}
	$request = POST "http://www.micropat.com/perl/sunduk/avail-check.pl",
		[     'ticket'        => "$self->{'patent'}{'session_token'}",
		'familylist'    => "",
		'patnumtaglist' => "$id",
		'textonly.x'    => "60",
		'textonly.y'    => "9",
		];
	$http_response = $self->request($request);
	# find new parameters, match and screenseq
	$html = $http_response->content;

	# print "\n$html\n";
	if (   $html =~ m{  value \s* = \s* "	(\d\d\d\d\d\d\d+\-0) "   #   			
		}xms
		)
	{
		$match = $1;
	}
	else {
		$self->{'message'}
			= "no match found e.g. match-1-0 value 12345678-0 , do not know how to continue \n$html\n no match found e.g. match-1-0 value 12345678-0 , do not know how to continue";
		$self->{'is_success'} = 0;
		return ($self);
	}

	# print "\n3.5\n";
	if (   $html =~ m{ name \s* = \s* "screenseq" \s* # 
					   value \s* = \s* "(\d+)"   #   			
		}xms
		)
	{
		$screenseq = $1;
	}
	else {
		$self->{'message'}
			= "no screenseq found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = 0;
		return ($self);
	}

	# print "\n4\n";

	$request = POST "http://www.micropat.com/perl/sunduk/order-submit.pl",
		[     'ticket'            => "$self->{'patent'}{'session_token'}",
		'userref'           => "$id",
		'bundle_format'     => "normalized",
		'screenseq'         => "$screenseq",
		'del_CAPS_standard' => "DOWNLOADHTML",
		'match-1-0'         => "$match",
		];

#<form method="GET" action="order-detail.pl">
#<input type="hidden" name="orderid" value="3784175"/>
#<input type="hidden" name="ticket" value="100228090378"/>
#<input type="submit" value="Click Here for Current Status of Order">
#</form>  This will take you to response also, like a reload while waiting for availability

	$http_response = $self->request($request);
	while ( $http_response->content
		!~ m { (http://www.micropat.com:80/get-file/\d+/)  }xms )
	{
		my @forms = HTML::Form->parse($http_response);
		if ( !$forms[0] ) {
			confess( "html page does not have the expected form:\n"
					. $http_response->content() );
		}
		$http_response = $self->request( $forms[0]->click );
	}

$html = $http_response->content;
	while ( $html !~ m{(http://www.micropat.com:80/get-file/\d+/)}xms )
	{
		my @forms = HTML::Form->parse($http_response);
		if ( !$forms[0] ) {
			$html = $http_response->content;
			confess( "html page does not have the expected form:\n"
					. $http_response->content() );
		}
		$http_response = $self->request( $forms[0]->click );
		$html = $http_response->content;
	}
	$html = $http_response->content;
	if ( $html
		=~ m{ (http://www.micropat.com:80/get-file/\d+/[^\.]+\.html)  }xms )
	{
		$url = $1;
	}
	else {
		$self->{'message'}
			= "no url to html found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = 0;
		return ($http_response);
	}
	$request       = GET "$url";
	$http_response = $self->request($request);
	return ($http_response);
}

sub MICROPATENT_terms {
	my ($self) = @_;
	return ("Pay to play. Consult your contract.  Your mileage may vary. ");
}
%_country_known = (    # 20060922
	'OA' => 'from 1966',   # African Intellectual Property Organisation (OAPI)
	'AP' => 'from 1985'
	,    # African Regional Industrial Property Organisation (ARIPO)
	'AT' => 'from 1920',                                # Austria
	'BE' => 'from 1920',                                # Belgium
	'CA' => 'from 2000',                                # Canada--grants
	'CA' => 'from July 1999',                           # Canada--applications
	'CA' => 'from Uniques (no other family filing)',    # Canada--other
	'DK' => 'from 1920',                                # Denmark
	'EP' => 'from 19800109 to 20060913',    # European Patent Office--grants
	'EP' =>
		'from 19781220 to 20060913',    # European Patent Office--applications
	'FR' => 'from 1920',                    # France
	'DD' => 'from YES',                     # German Democratic Republic
	'DE' => 'from 1920 to 20060914',        # Germany
	'GB' => 'from 19160608 to 20060913',    # Great Britain
	'IE' => 'from 1996',                    # Ireland
	'IT' => 'from 1978',                    # Italy
	'JP' => 'from 19800109 to 20060906',    # Japan--B
	'JP' => 'from 19830527 to 20060824',    # Japan--A
	'JP' => 'from 1980 (partial coverage)', # Japan--other
	'LU' => 'from 1945',                    # Luxembourg
	'MC' => 'from 1957',                    # Monaco
	'NL' => 'from 1913',                    # The Netherlands
	'PT' => 'from 1980',                    # Portugal
	'ES' => 'from 1969',                    # Spain
	'SE' => 'from 1918',                    # Sweden
	'CH' => 'from 1920',                    # Switzerland
	'US' => 'from 1790',                    # United States of America--grants
	'USB' => 'from 19640114  ',    # United States of America--grants
	'USA' => 'from 20010315 ',     # United States of America--applications
	'WO'  => 'from 19781019 ',     # WIPO
	'AR'  => 'limited',            # Argentina
	'AU'  => 'limited',            # Australia
	'BR'  => 'limited',            # Brazil
	'BG'  => 'limited',            # Bulgaria
	'CN'  => 'limited',            # China
	'CZ'  => 'limited',            # Czech Republic
	'CS'  => 'limited',            # Czechoslovakia
	'FI'  => 'limited',            # Finland
	'GR'  => 'limited',            # Greece
	'HU'  => 'limited',            # Hungary
	'LV'  => 'limited',            # Latvia
	'LT'  => 'limited',            # Lithuania
	'MX'  => 'limited',            # Mexico
	'MN'  => 'limited',            # Mongolia
	'NO'  => 'limited',            # Norway
	'PH'  => 'limited',            # Philippines
	'PL'  => 'limited',            # Poland
	'RO'  => 'limited',            # Romania
	'RU'  => 'limited',            # Russian Federation/former Soviet Union
	'SU'  => 'limited',            # Russian Federation/former Soviet Union
	'SK'  => 'limited',            # Slovakia
	'SI'  => 'limited',            # Slovenia
);
1;

=head1 WWW::Patent::Page::MICROPATENT

support MicroPatent (TM) commercial service of Thomson (TM)
	
=cut

=head2 methods

set up the methods available for each document type 

=cut

=head2 MICROPATENT_login

You need a username and password.

=cut

=head2 MICROPATENT_xml

xml download

=cut

=head2 MICROPATENT_html

html download

=cut

=head2 MICROPATENT_pdf

pdf download, presently full document only

=cut

=head2 MICROPATENT_data

get the worksheet data for a single patent

=cut

=head2 _data_hash_from_arrays

an internal helper function to transform worksheet data titles into attribute names

=cut

=head2 MICROPATENT_terms

You get what you pay for.

=cut

=head2 MICROPATENT_country_known

hash with keys of two letter acronyms, values of the dates covered

=cut

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Wanda B. Anon wanda_b_anon@yahoo.com . 
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the Artistic License version 2.0 
or above ( http://www.perlfoundation.org/artistic_license_2_0 ) .

=cut

