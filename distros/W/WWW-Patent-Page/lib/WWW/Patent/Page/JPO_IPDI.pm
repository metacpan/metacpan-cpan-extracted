
package WWW::Patent::Page::JPO_IPDI;
use Carp qw(cluck confess carp croak);
use strict;
use warnings;
use diagnostics;
use subs qw( methods JPO_IPDI_country_known),
	qw(  JPO_IPDI_terms
	JPO_IPDI_translation JPO_IPDI_request 
	_output_next_request_form 
	_output_next_request_re
	_save_image )
	;    ## JPO_IPDI_xml_tree
use LWP::UserAgent 2.003;
require HTTP::Request;
use HTTP::Request::Common;
use URI;
use HTML::Form;
use PDF::API2 2.000;
use WWW::Patent::Page::Response;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use HTML::TokeParser;
use HTTP::Headers; 
use IO::Scalar;
use Data::Dumper  ; 

# use HTML::Display;    ## comment out after completion; used for testing.
$Carp::Verbose = 1;
my $POST;
$POST = 'GET'; 
$POST = 'POST'; 


# print "$] $^O $^V $^X @INC \n" ; exit;
# my $browser = HTML::Display->new(class => 'HTML::Display::Win32::IE',);

our ($VERSION, %_country_known); $VERSION = '0.02';

#$|       = 1;

sub JPO_IPDI_translation {
	my $self = shift;

	$self->agent('Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6');

#	$self->proxy(['http', 'ftp'], 'http://localhost:5364/');
	## Howard P. Katseff, "Web Scraping Proxy" wsp http://www.research.att.com/~hpk/
	my $re;    ## regular expression
	my (@english_response, @japanese_page, @image, %image_hash);
	## @english_response 0=>summary 1=>claims 2=>detailed description
	my (@response, $response, @request, $request);
	my (@next_request, $next_request);
	my $html;
	my %parameter;

	#	print "'$self->{'patent'}->{'doc_type'}' doc_type\n";
	if (defined($self->{'patent'}->{'doc_type'})) {
		%parameter = (
			N2001 => $self->{'patent'}->{'doc_type'} . $self->{'patent'}->{'number'},
			N1001 => $self->{'patent'}->{'kind'}
		);
	}
	else {
		%parameter = (
			N2001 => $self->{'patent'}->{'number'},
			N1001 => $self->{'patent'}->{'kind'}
		);
	}
##	print "Number '$parameter{N2001}'   type '$parameter{N1001}'\n";

	my $name = $parameter{N2001} . '_' . $parameter{N1001};
	$request = HTTP::Request->new(GET => "http://www4.ipdl.inpit.go.jp/Tokujitu/tjsogodben.ipdl?" . "N0000=115");

	my $output_next_request = sub {    ## take the raw html, find the right form, fill in
		my $response = shift;
		my $html     = $response->content;
		if ($html =~ m/The whole service will not be provided in the following time for regular maintenance/mxi) {
			$self->{success} = 0;
			$self->{message} = 'The whole service will not be provided in the following time for regular maintenance.';
			return ($response, $request);
		}
		my @forms = HTML::Form->parse($response);
		if (!scalar(@forms)) {
			carp 'returned html has no forms; possibly maintenance time at JPO? ';
			$request = HTTP::Request->new(GET => 'http://www.ipdl.inpit.go.jp/homepg_e.ipdl');
			$response = $self->request($request);
			confess $response->content;
			$self->{is_success} = q{};
			$self->{message}    = 'returned html has no forms; possibly maintenance time? ';
			return $self;
			## this kicks out error at $response[1] = $self->request( $next_request[0] ); due to WWW::Patent::Page object not request object
		}
		my @inputs = $forms[0]->inputs;
		foreach my $name (keys %parameter) {
			my $input = $forms[0]->find_input($name);
			$input->readonly(0);
			$forms[0]->value($name, $parameter{$name});

			#	print "\$name = '$name' , \$parameter{$name} = '$parameter{$name}'\n";
		}

		#		exit;
		$forms[0]->method($POST); 
		my $next_request = $forms[0]->click;    # request for form submission
		return $next_request;
	};
	($response[0], $next_request[0])            # the html with forms, and the next url
		= (JPO_IPDI_request($self, $request, $output_next_request));
	$response[1] = $self->request($next_request[0]);     #obtain frames and URLs
	$re = qr/NAME="tjlistdben" \s+ SRC="([^"]+)"/imx;    # find the url for our number
	($next_request[2]) = (_output_next_request_re($response[1], $re));
	my $referer = $next_request[2]->uri;                 # use later
	$response[2] = $self->request($next_request[2]);
	$html = $response[2]->content;
	## to click on the number, fill out the form
	if (   $html                                            # (
		=~ m/ \) [\n\s]* \{ \s* document\.form1\.N0000\.value \s* = \s* (\d+) \s* ;/isxm
		)                                                # }
	{
		$parameter{'N0000'} = $1;
	}
	else {carp "No N0000 in \$html:\n$html\n"}

	if ($html =~ m/"N0703" \s+ VALUE=" ([^"]+) "/isxm) {
		$parameter{'N0703'} = $1;
	}
	else {carp 'No N0703 in \$html'}

	if ($html =~ m/"N0700" \s+ VALUE=" ([^"]+) "/isxm) {
		$parameter{'N0700'} = $1;
	}
	else {carp 'No N0700 in \$html'}

	if ($html =~ m/"N0701" \s+ VALUE=" ([^"]+) "/isxm) {
		$parameter{'N0701'} = $1;
	}
	else {carp 'No N0701 in \$html'}

	if ($html =~ m/"N0702" \s+ VALUE=" ([^"]+) "/isxm) {
		$parameter{'N0702'} = $1;
	}
	else {carp 'No N0702 in \$html'}

	if ($html =~ m/DL\[0\]=" ([^"]+) "/isxm) {
		$parameter{'N0500'} = $1;
	}
	else {carp 'No N0500 in \$html'}

	if ($html =~ m/PI\[0\]=" ([^"]+) "/isxm) {    # PI[0]="000100110011"
		$parameter{'N0501'} = $1;
		$parameter{'N0501'} =~ s/\n//imxg;
	}
	else {carp 'No N0501 in $html'}

	$parameter{'N0502'} = substr($parameter{'N0501'}, 0, 4);
	$parameter{'N0503'} = '0';
	$parameter{'N0504'} = 2;
	if ($html =~ m/MID=" ([^"]+) "/isxm) {
		$parameter{'N0001'} = $1;
		$parameter{'N0001'} =~ s/\n//mxig; 
	}
	else {carp 'No N0001 in \$html'}

	if ($html =~ m/DK= ([^;]+) ;/isxm) {
		$parameter{'N0002'} = $1;
		$parameter{'N0002'} =~ s/\n//mxig;
	}
	else {carp 'No N0002 in \$html'}

	($next_request[5]) = (_output_next_request_form($response[2], 0, %parameter));

	$next_request[5]->header(referer => $referer);

	$response[5] = $self->request($next_request[5]);    # click on the patent number

	# now you should have the CALLPAJ routine- click the form 0
	$next_request[13] = (_output_next_request_form($response[5], 0,));
	$response[13]     = $self->request($next_request[13]);
	
#	print "\$next_request[13] < \$english[0] = ".Dumper($next_request[13])."\n"; 
#if ($debug) { } 
#	    $browser->display(html => $http_response->content);


	#first branch, now a passing move
	my $html13 = $response[13]->content(); 
#	print "\$html13 = \n$html13\n"; 
	if ($html13 =~ m/SRC="([^"]+)" \s+ NAME="FTMMAIN"/imx ) {
#		print "2!\n"; 
		$request = _output_next_request_re($response[13], qr/SRC="([^"]+)" \s+ NAME="FTMMAIN"/imx);	
		$english_response[0] = $self->request($request);    #->content; # summary, coversheet, first page
		$next_request[13] = _output_next_request_re($response[13], qr/SRC="([^"]+)" \s+ NAME="FTMNAVI"/imx);
		$response[14]     = $self->request($next_request[13]);                                                #  Detail / Japanese
		($next_request[6]) = (_output_next_request_form($response[14], 1));                                    # 0 or 1 ?
#		print "\$next_request[6] > \$english[0] = ".Dumper($next_request[6])."\n"; 
		$response[6] = $self->request($next_request[6]);
	}
	else {
#		print "1!\n"; 
		$self->{is_success} = 0;
		$self->{message}    = 'no PAJ translation available';
#		carp('no PAJ translation available- possibly reference is too old or too new?');
		$english_response[0] = HTTP::Response->new(200, 'sham' , HTTP::Headers->new  , 
			'<html><head><title>JP ' . $name . '</title></head><body><h1 align=center>JP ' . $name . '</h1><p>No translated patent abstract is available. </p> </body></html>');
		$response[6] = $response[13];
	}    # end of branch 1, now returning to linear flow .

	$html = $response[6]->content;
	if ($html =~ m/"N0000" \s+ VALUE=" ([^"]+) "/isxm) {
		$parameter{'N0000'} = $1;
	}
	else {carp "No N0000 in \$html:\n$html\n".Dumper($response[6]) }

	($next_request[6]) = (_output_next_request_form($response[6], 0, %parameter));    # 0 or 1 ?
	$response[6] = $self->request($next_request[6]);
	$html = $response[6]->content;

	my $K_flg;
	if ($html =~ m/K_flg \s* = \s* " ([^"]+) "/isxm) {
		$K_flg = $1;
	}
	else {carp "No \$K_flg $K_flg in \$html:\n$html\n"}
	my $mid;
	if ($html =~ m/MID \s* = \s* (\d+) /isxm) {
		$mid = $1;
	}
	else {carp "No \$mid $mid in \$html:\n$html\n"}

	$re = qr/FRAME \s+ NAME="tjitemidx" \s+ SRC="([^"]+)"/imsx;
	($next_request[7]) = (_output_next_request_re($response[6], $re));

	$re = qr/FRAME \s+ NAME="tjitemcnt" \s+ SRC="([^"]+)"/imsx;
	($next_request[8]) = (_output_next_request_re($response[6], $re));

	$re = qr/FRAME  \s+ NAME="tjitemdrw" \s+ SRC="([^"]+)"/imsx;
	($next_request[9]) = (_output_next_request_re($response[6], $re));

	$response[6]         = $self->request($next_request[6]);    #obtain frames and URLs
	$response[7]         = $self->request($next_request[7]);    #navigation
	$response[8]         = $self->request($next_request[8]);    #claims
	$english_response[1] = $response[8];                        #claims
	$response[9]         = $self->request($next_request[9]);    #drawings navigator

	# now let's get the English
	$html = $response[7]->content;
	if ($html =~ m/document\.form3\.N0000\.value \s* = \s* (\d+) \s* ;/isxm) {
		$parameter{'N0000'} = $1;
	}
	else {carp "No N0000 in \$html:\n$html\n"}

	$parameter{'N0550'} = $K_flg;

	$parameter{'N0551'} = '00000000000010000000';               # drawings
	$parameter{'N0580'} = '0';
	$parameter{'N0001'} = $mid;
	
	($next_request[20]) = (_output_next_request_form($response[7], 3, %parameter));    # 0 or 1 ?
	$response[20] = $self->request($next_request[20]);
	#  &japanese();   if you want the images of the untranslated patent
	$html = $response[6]->content;
	my $japanese_url;
	if ($html =~ m/location\.href="([^;]+)/ismx) {
		$japanese_url = $1;
		$japanese_url =~ s/"$//i;
		if (! $japanese_url =~ m/"\+ MID \+"/i) { warn "\$japanese_url '$japanese_url'\n"}                   # variable # of spaces around + sign
		$japanese_url =~ s/"\+ MID \+"/$parameter{'N0001'}/i;
		$japanese_url =~ s/"\+ DK \+ *"/$parameter{'N0002'}/i;
		$japanese_url =~ s/" \+ DL \+ "/$parameter{'N0500'}/i;
		$japanese_url =~ s/" \+ PI \+ "/$parameter{'N0501'}/i;
		$japanese_url =~ s/" \+ PI.substring\( 0, 4 \) \+ "/$parameter{'N0502'}/i;
		$japanese_url =~ s/" \+ count \+ "/0/i;

		#		print "\$japanese_url = '$japanese_url'\n";
	}
	else {
		carp "No Japanese location.href in function SubmitDataLayout: \n$html\n";
	}

	my $japanese_request = HTTP::Request->new('GET', URI->new($japanese_url));
	$response[30] = $self->request($japanese_request);
# next is where it goes wrong 
	$next_request[31] = _output_next_request_re($response[30], qr/NAME="tjcontentdben" \s* SRC="([^"]+)"/imx);
	$response[31]     = $self->request($next_request[31]);
	$next_request[32] = _output_next_request_re($response[30], qr/NAME="tjdispdben" \s* SRC="([^"]+)"/imx);
	$response[32]     = $self->request($next_request[32]);

	$html = $response[32]->content;
	my $time = int(1000 * time - int(rand(1000)));

	my %page_parameter;
	$page_parameter{ImgKind} = 1;
	$page_parameter{RolKind} = 0;
	$page_parameter{'N0001'} = $parameter{'N0001'}; 
	$page_parameter{'N0002'} = $parameter{'N0002'};
	$page_parameter{'N0500'} = $parameter{'N0500'};
	$page_parameter{'N0501'} = $parameter{'N0501'};
	$page_parameter{'N0502'} = $parameter{'N0502'};
	$page_parameter{'N0503'} = $parameter{'N0503'};
	$page_parameter{'N0700'} = $page_parameter{ImgKind};

	# 1
	$page_parameter{'N0701'} = 0;

	# 0 = no rotation
	$page_parameter{'N0702'} = 0;

	# 0 = reversal->no
	$page_parameter{'N0703'} = 0;

	# opposite (1's complement) of 700

	my $last_page = substr($parameter{'N0501'}, 4, 4);
	$last_page =~ s/^0+//mxi;

	#	print "\$last_page = '$last_page'\n";

	# eliminate this image fetching.
	#	my $JPO_page = '000';
	#	foreach my $image_count (1 .. $last_page) {
	#		$JPO_page++;
	#		$page_parameter{'N0502'} = $image_count;
	#		($next_request[33]) = (&_output_next_request_form($response[32], 0, %page_parameter));    # 0 or 1 ?
	#		$response[33]     = $self->request($next_request[33]);
	#		$next_request[34] = &_output_next_request_re($response[33], qr/NAME="tjcontentdben" \s* SRC="([^"]+)"/imx);
	#		$response[37]     = $self->request($next_request[34]);
	#		$next_request[38] = &_output_next_request_re($response[37], qr/IMG \s* SRC="([^"]+)"/imx);
	#		$response[38]     = $self->request($next_request[38]);
	#		print 'uri = ', $next_request[38]->uri, "\n";
	#		&_save_image($response[38], 'image' . $JPO_page . '.gif');
	#	}    #japanese images

	undef $parameter{'N0000'};
	$html = $response[20]->content;

	if ($html =~ m/"N0000" \s+ VALUE=" ([^"]+) "/isxm) {
		$parameter{'N0000'} = $1;
	}
	else {carp "No N0000 in $html"}

	#DETAILED DESCRIPTION    javascript:ShowFrames('00010000000000000000')
	#TECHNICAL FIELD         javascript:ShowFrames('00001000000000000000')
	#PRIOR ART               javascript:ShowFrames('00000100000000000000')
	#EFFECT OF THE INVENTION javascript:ShowFrames('00000010000000000000')
	#EXAMPLE                 javascript:ShowFrames('00000000100000000000')
	#TECHNICAL PROBLEM       javascript:ShowFrames('00000000010000000000')
	#MEANS                   javascript:ShowFrames('00000000001000000000')
	#DESCRIPTION OF DRAWINGS javascript:ShowFrames('00000000000100000000')
	#DRAWINGS                javascript:ShowFrames('00000000000010000000')

	my $count = 1;
	foreach my $N0551 (
		'00010000000000000000',    # Detailed Description
		'00000000000100000000',    # Description of Drawings
		'00000000000010000000'     # Drawings
		)
	{
		$parameter{'N0551'} = $N0551;
		$count++;
		($next_request[21]) = (_output_next_request_form($response[20], 1, %parameter));    # 0 or 1 ?
		$english_response[$count] = $self->request($next_request[21]);
	}    # loop to get translated pages

	# now we get the drawings (this works as to web)

	$html    = $response[9]->content;    #drawings navigator
	$referer = $next_request[9]->uri;
	my %drawing2image;

	#	print "drawings navigator referer [9] = $referer\n";
	if ($html =~ m/IMG \s+ SRC=" ([^"]+) "/isxm) {
		$re = qr/IMG \s+ SRC=" ([^"]+) "/isxm;
		($next_request[0]) = (_output_next_request_re($response[9], $re));
		$response[0] = $self->request($next_request[0]);
		$image[0]    = $response[0]->content;
	}
	else {carp "NO expected representative drawing in \n" . $html . "\n";}
	my ($images);
	if ($html =~ m/drawing \s+ (\d+) \s* <\/ SELECT /isxm) {
		($images) = ($1);    #how many drawings / images in patent

		#		print "$images drawings found.\n";
	}
	else {carp 'no last drawing number found.'}

	#my $drawing;
	foreach my $drawing (1 .. $images) {    # $images from drawings navigator

		#		print "processing drawing $drawing\n";
		if ($html =~ m/VALUE=" ([^"]+) "> \n* drawing \s+ $drawing \n* /isxm) {
			my $number = $1;
			my %image  = (
				select1 => "$number",
				N0552   => substr($number, 0, 1),
				N0553   => substr($number, 2, 6),
				N0500   => $parameter{N0500},
			);
			$drawing2image{$image{N0553}} = $drawing;
			($next_request[1]) = (_output_next_request_form($response[9], 0, %image));
			$next_request[1]->header(referer => $referer);

			#				print "url = ", $next_request[1]->uri , "\n";
			$response[1] = $self->request($next_request[1]);    #html that holds link to drawing
			my $html2 = $response[1]->content;

			if ($html2 =~ m/IMG \s+ SRC=" ([^"]+) "/isxm) {
				$re = qr/IMG \s+ SRC=" ([^"]+) "/isxm;          # drawing link
				($next_request[0]) = (_output_next_request_re($response[1], $re));
				$response[0] = $self->request($next_request[0]);
				$image[$drawing] = $response[0]->content;

				#				_save_image($response[0],"Image__$drawing");
			}
		}
		else {
			confess "single drawing number $drawing of $images not found.\nhtml = $html\n";
		}
	}

	$html = $english_response[2]->content;    #detailed description
	if ($html =~ m/IMG \s+ SRC=" ([^"]+)".?ALT="ID=\s*([^"]+)"/isxm) {
		my $link   = $1;
		my $number = $2;
		$re = qr/IMG \s+ SRC=" ([^"]+) "/isxm;

		# table like-drawing
		($next_request[0]) = (_output_next_request_re($english_response[2], $re));
		$response[0] = $self->request($next_request[0]);

		#		print "saving 'table' as image[$images]; link = '$link' number = '$number'\n";
		$image[++$images] = $response[0]->content;
		$image_hash{$number} = $response[0]->content;

		#		print "got representative image\n";
	}

	#	else {carp "NO expected table drawing in here: \n" . "\$html :\n$html\n" . "\n";}

#=cover.html'); 1=> claims.html');2=>detailed_description.html'); 3=>drawing_description.html');4=>\drawings.html');
	$html = q{};

	## here is the start of the html manipulation and zip

	# my (@english_response, $tokenizer, $re, @image, %alt2image_file_name, $id, %alt2image);

	my ($id, %alt2image, %alt2image_file_name);

	my $other_image = 'other000';

	for my $page (0 .. $#english_response) {

		#		print "processing english page $page\n";
		my $p = HTML::TokeParser->new(\$english_response[$page]->content) or cluck "page $page problem!";

		my $base = $english_response[$page]->base;

		#		print "\$base = '$base'\n" ;
		my $url;
		while (my $token = $p->get_token) {
			if (!$token) {

				#				print "end of page $page";
			}
			if (${$token}[0] eq 'S' and ${$token}[1] eq 'a') {
				##			print "found an anchor.\n ${$token}[0] ${$token}[1] " . join ' ',	%{ ${$token}[2] }, "\n", ${$token}[4], "\n";
				if (${$token}[2]{'href'} =~ m/N0553%3D(\d+)/mxi) {
					$id = $1;
				}
				else {carp "token ${$token}[4] not parsed"}
				if ($page == 4) {
					$html .= "\n<a name='$id'>\n";
				}
				else {$html .= "\n<a href='#$id'>\n"}
			}
			elsif (${$token}[0] eq 'S' and ${$token}[1] eq 'base') { }    # no base markup
			elsif (${$token}[0] eq 'S' and ${$token}[1] eq 'emi')  { }    # no emi markup
			elsif (${$token}[0] eq 'S' and ${$token}[1] eq 'txf')  { }    # no txf markup
			elsif (${$token}[0] eq 'S' and ${$token}[1] eq 'dp')   { }    # no dp markup
			elsif (${$token}[0] eq 'E' and ${$token}[1] eq 'base') { }    # no base markup
			elsif (${$token}[0] eq 'E' and ${$token}[1] eq 'emi')  { }    # no emi markup
			elsif (${$token}[0] eq 'E' and ${$token}[1] eq 'txf')  { }    # no txf markup
			elsif (${$token}[0] eq 'E' and ${$token}[1] eq 'dp')   { }    # no dp markup
			         #		elsif (${$token}[0] eq 'S' and ${$token}[1] eq 'base') { }    # no base markup
			elsif (${$token}[0] eq 'S' and ${$token}[1] eq 'base') { }    # no base markup
			elsif (${$token}[0] eq 'S' and ${$token}[1] eq 'img')  {
				my ($img, $type, $count);
				if (exists ${$token}[2]{'src'} and ${$token}[2]{'src'} =~ m{.*/([^\.]+)\.(.+)$}mxi) {
					$img  = $1;
					$type = $2;
				}
				else {
					carp "'${$token}[2]{'src'}' (src) does not pass m|/([^\\.]+)\\.(.+)$|";
				}
				if (exists ${$token}[2]{'alt'} and ${$token}[2]{'alt'} =~ m{^id=(\d+)$|}mxi) {
					$id = $1;
				}
				elsif (${$token}[2]{'border'} == 0) {
					$id = 'representative000';
				}
				else {$id = $other_image++;}    # not drawing or representative image; likely a table or chemical structure
				$alt2image_file_name{$id} = $img . q{.} . $type;

				#		print "\$alt2image_file_name{$id} = $alt2image_file_name{$id}\n" ;
				#				my $ua = LWP::UserAgent->new;
				#				$ua->agent('Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6');
				#				$ua->proxy(['http', 'ftp'], 'http://localhost:5364/')
				;                               #Howard P. Katseff, "Web Scraping Proxy" wsp http://www.research.att.com/~hpk/

				#         		my $req = URI->new_abs(${$token}[2]{'src'}, $base);

				my $req = HTTP::Request->new(GET => URI->new_abs(${$token}[2]{'src'}, $base));
				my $res = $self->request($req);
				$alt2image{$id} = $res->content;

				#				open my $IMG, ">P:\\workspace\\WWW-Patent-Page\\" . "$img" . ".$type";
				#				binmode $IMG;
				#				print $IMG $res->content;
				#				close $IMG;
				my $link = "<img src='$img.$type' alt='$type id = $id' > <hr> ";
				$html .= $link;
			}
			elsif ( $page == 0
				and ${$token}[0] eq 'S'
				and ${$token}[1] eq 'title')
			{
				$token = $p->get_token;    # text of title
				$html .= '<title>' . $name . '</title>' . "\n";
			}
			elsif (${$token}[0] eq 'S' and ${$token}[0] ne 'a' and ${$token}[0] ne 'img') {
				if (            $page > 0
					and (  ${$token}[1] eq 'body'
						or ${$token}[1] eq 'html'
						or ${$token}[1] eq 'head'
						or ${$token}[1] eq 'meta'
						or ${$token}[1] eq 'title')
					)
				{
				}
				else {
					$html .= ${$token}[4];
				}
			}
			elsif (          $page < 4
				and ${$token}[0] eq 'E'
				and (  ${$token}[1] eq 'body'
					or ${$token}[1] eq 'html'
					or ${$token}[1] eq 'head')
				)
			{

				# skip this end link
			}
			elsif ($page == 4 and ${$token}[1] eq 'head' and ${$token}[0] eq 'E') { }

			elsif (          $page > 0
				and ${$token}[0] eq 'S'
				and (  ${$token}[1] eq 'body'
					or ${$token}[1] eq 'html'
					or ${$token}[1] eq 'head'
					or ${$token}[1] eq 'meta'
					or ${$token}[1] eq 'title')
				)
			{
			}
			elsif (${$token}[1] eq 'title') {
			}

			elsif (${$token}[0] eq 'E')  {$html .= ${$token}[2]}
			elsif (${$token}[0] eq 'T')  {$html .= ${$token}[1]}
			elsif (${$token}[0] eq 'C')  {$html .= ${$token}[1]}
			elsif (${$token}[0] eq 'D')  {$html .= ${$token}[1]}
			elsif (${$token}[0] eq 'PI') {$html .= ${$token}[2]}
		}

		#		print " page done : $page\n";
	}

	$html =~ s/\[([^\]]+)\]/[$1] /mxig;    # for readibility

	#	open my $HTML, '>P:\workspace\WWW-Patent-Page\html3.html';
	#	print $HTML $html;
	#	close $HTML;
	my $zip = Archive::Zip->new();

	#	my $directory = q{};
	#	my $dir_member    = $zip->addDirectory("JP_$name/");
	#	my $string_member = $zip->addString($html, "JP_$name/index.html");
	my $string_member = $zip->addString($html, 'index.html');
	$string_member->desiredCompressionMethod(COMPRESSION_DEFLATED);
	my (@image_member, $i);                # $alt2image{$id}
	$i = 0;

	foreach my $key (keys %alt2image) {

		#		$image_member[$i] = $zip->addString($alt2image{$key}, "JP_$name/$alt2image_file_name{$key}");
		$image_member[$i] = $zip->addString($alt2image{$key}, "$alt2image_file_name{$key}");
		$image_member[$i++]->desiredCompressionMethod(COMPRESSION_STORED);
	}

	#	unless ($zip->writeToFileNamed("P:\\workspace\\WWW-Patent-Page\\JP_$name" . '.zip') == AZ_OK) {
	#		carp 'zip write error';
	# }

	#	print "past zip write\n";
	my $zipContents = '';
	my $SH = IO::Scalar->new(\$zipContents);
#	if ($zip->writeToFileHandle( $SH , 0  ) ) {
	$zip->writeToFileHandle( $SH , 0  );
	$self->{is_success} = 1;
	$self->{'patent'}{'content'} = $zipContents;
	return ($zip);
#	}	
#	else {
#		cluck 'no write to file handle $SH'
#	}
}    # JPO_IPDI_translation

sub _output_next_request_re {
	my $response           = shift;
	my $regular_expression = shift;
	my $base               = $response->base;
	my $html               = $response->content;
	my $url;
	if ($html =~ m/$regular_expression/ixm) {
		$url = $1;
	}
	else {carp "no $regular_expression ... regular expression\n$html";}
	my $next_request = URI->new_abs($url, $base);
	$next_request = HTTP::Request->new(GET => $next_request);
	if ($url) {return $next_request;}
	else {return}
}

sub _save_image {
	my ($response, $name) = @_;
	my $image = $response->content;
	open my $IMAGE, '>', "$name";
	binmode $IMAGE;
	print {$IMAGE} $image;
	close $IMAGE;
	return;
}

sub _output_next_request_form {

	# make request given; get response.
	# look at response and figure out next request to make
	# as an absolute URI object
	my ($http_response, $whichform, %replacement) = @_;

	#	my $whichform     = shift @_;
	my $next_request;

	#	my %replacement = @_;
	my @forms = HTML::Form->parse($http_response);

	#		my @f = grep $_->attr("id") eq "form1", @forms;
	#	print scalar(@forms), " forms\n ",;

	#		print scalar(@f) , " matching\n" ;
	my @inputs = $forms[$whichform]->inputs;
	foreach my $name (keys %replacement) {
		my $input = $forms[$whichform]->find_input($name);
		if ($input) {
			$input->readonly(0);
			$forms[$whichform]->value($name, $replacement{$name});
		}
	}
	$forms[$whichform]->method($POST); 
	$next_request = $forms[$whichform]->click;

	#		print $next_request->as_string("\n");
	return $next_request;
}

sub JPO_IPDI_request {
	my ($self, $request, $output_next_request, %tests) = @_;

	#	my $request             = shift @_;
	#	my $output_next_request = shift @_;
	my $next_request;

	#	my %tests = @_;

	my $http_response = $self->request($request);
		$next_request = &{$output_next_request}($http_response);
		#    $browser->display(html => $http_response->content);
	return ($http_response, $next_request);
}

# perl -MLWP::Simple -MHTML::Display -e "my \$browser = HTML::Display->new( class => 'HTML::Display::Win32::IE', ); \$browser->display( html => get( 'http://www.google.com'), location => 'http://www.google.com');"

sub methods {
	return (                              ## no method() 
		'JPO_IPDI_translation'   => \&JPO_IPDI_translation,
		'JPO_IPDI_country_known' => \&JPO_IPDI_country_known,
		##     'JPO_IPDI_parse_doc_id'        => \&JPO_IPDI_parse_doc_id,
		'JPO_IPDI_terms' => \&JPO_IPDI_terms,
	);
}

sub JPO_IPDI_country_known {
	my $self = shift;
	my ($country_in_question) = shift;
	if (uc($country_in_question) == 'JP') {
		return ($_country_known{$country_in_question});
	}
	else {
		return (undef);
	}
}

sub JPO_IPDI_terms {
	my ($self) = @_;
	return (
		'The Industrial Property Digital Library (IPDL) offers the public access to IP Gazettes of the JPO free of charge through the Internet.  Certain conditions may apply.  As of February 2007, consult http://www.ipdl.ncipi.go.jp/notice_e.htm .'
	);
}
%_country_known = (    # 20060922
	'JP' => 'from 19800109 to 20060906',       # Japan--B
	'JP' => 'from 19830527 to 20060824',       # Japan--A
	'JP' => 'from 1980 (partial coverage)',    # Japan--other

	# http://www4.ipdl.inpit.go.jp/Tokujitu/tjsogodben.ipdl?N0000=115  ... Stored Data
	# Stored Data Information(Patent & Utility Model Gazette DB)
	# 13/12/2007
	# The coverage of available documents is following. (not necessarily translated)
	#
	# Document Description 	Coverage of Documents
	# A: 	Published patent application 	1971-000001 	- 	2007-325500
	# B: 	Examined patent application publication 	1922-000001 	- 	1996-034772
	# B: 	Patent 	2500001 	- 	4022300
	# C: 	Patent specification 	1 	- 	216017
	# A: 	Japanese translation of PCT international application 	1979-500001 	- 	2007-536890
	# U: 	Registered utility model 	3000001 	- 	3138009
	# U: 	Published utility model application 	1971-000001 	- 	2006-000001
	# U1: 	Unexamined utility model specification 	1971-000001 	- 	1992-138600
	# Y: 	Examined utility model application publication 	1922-000001 	- 	1996-011090
	# Y: 	Examined utility model registration 	2500001 	- 	2607898
	# Z: 	Examined utility model specification 	1 	- 	406203
	# U: 	Japanese translation of PCT international application(utility model) 	1979-500001 	- 	1998-500001
	# H: 	Corrected patent specification 	72 	- 	814
	# I: 	Corrected utility model specification 	32 	- 	330
	# A1: 	Domestic re-publication of PCT international application 	79/000329 	- 	2006/004050
	# N1: 	Journal of technical disclosure 	87/003986 	- 	07/502725

);
1;

__END__

=head1 WWW::Patent::Page::JPO_IPDI

Get (download and assemble into HTML, then zip with images) 
machine translated patents from the Japanese Patent Office, 
specifically the Industrial Property Digital Library at the 
National Center For Industrial Property Information and Training.
=cut

=head2 methods

set up the methods available for each document type

=cut

=head2 JPO_IPDI_request

makes a HTTP::Request

=cut

=head2 JPO_IPDI_translation

Translation download and assembly.  Many HTTP requests are made; failure is not uncommon and eval() trapping is recommended.

=cut

=head2 _output_next_request_form

internal helper method, processes a common HTML CGI form 

=cut

=head2 _output_next_request_re

internal helper method, passes a regular expression to hunt a web page for the next link of interest.  could upgrade to TokeParser ...

=cut

=head2 _save_image

internal helper method, saves an image object obtained from JPO

=cut

=head2 JPO_IPDI_terms

You get what you pay for.

=cut

=head2 JPO_IPDI_country_known

hash with keys of two letter acronyms, values of the dates covered

=cut

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Wanda B. Anon wanda_b_anon@yahoo.com . 
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the Artistic License version 2.0 
or above ( http://www.perlfoundation.org/artistic_license_2_0 ) .

=cut

