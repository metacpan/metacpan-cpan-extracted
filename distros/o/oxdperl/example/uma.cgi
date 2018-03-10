#!/usr/bin/perl
=pod
/**
 * Language: Perl 5
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @Created On: 21-10-2016
 * Author: Inderpal Singh
 * Email: inderpal@ourdesignz.com
 * Updated On: 11/16/2017
 * Author: Sobhan Panda
 * Email: sobhan@centroxy.com
 * Company: Gluu Inc.
 * Company Website: https://www.gluu.org/
 * @license   http://www.opensource.org/licenses/mit-license.php MIT License
 */
=cut

###############
## Libraries ##
###############

use warnings;
use CGI qw{ :standard };
use lib './modules';
use JSON::PP;
use CGI::Carp qw(fatalsToBrowser); # show errors in browser
use CGI::Session;
use Data::Dumper;
#Load oxd Perl Module
use OxdPerlModule;

# Create the CGI object
my $cgi = new CGI;
# will restore any existing session with the session ID in the query object
my $session = CGI::Session->new($cgi);
# print the HTTP header and set the session ID cookie
print $session->header();

$object = new OxdConfig();
$oxd_id = $object->getOxdId();
$claims_redirect_uri = $object->getClaimsRedirectUri();
$resource_end_point = $object->getResourceEndPoint();

print "oxd Id: ".$oxd_id;



#print $session->param('client_id');
#print $session->param('client_secret');

##################
## Main program ##
##################
#server_side_ajax();
print_page_header();
print_html_head_section();
print_html_body_section_top();
# Process form if submitted; otherwise display it
if ($cgi->param("uma_rs_protect")) {
	uma_rs_protect_request($cgi);
} elsif ($cgi->param("uma_rs_check_access")) {
	uma_rs_check_access_request($cgi);
} elsif ($cgi->param("uma_rp_get_rpt")) {
	uma_rp_get_rpt_request($cgi);
} elsif ($cgi->param("introspect_rpt")) {
	introspect_rpt_request($cgi);
} elsif ($cgi->param("uma_rp_get_claims_gathering_url")) {
	uma_rp_get_claims_gathering_url_request($cgi);
} elsif ($cgi->param("get_resource")) {
	get_resource_request($cgi);
} else {
	print_html_form();
}

print_html_body_section_bottom();


#################
## Subroutines ##
#################
sub print_page_header {
    # Print the HTML header (don't forget TWO newlines!)
    #print "Content-type:  text/html\n\n";
}


sub print_html_head_section {
    
    print "<!DOCTYPE html>\n";
    print '<html lang="en">'."\n";
    print '<head>'."\n";
    print '<title>oxd Perl Application: UMA</title>'."\n";
    print '<meta charset="utf-8">'."\n";
    print '<meta name="viewport" content="width=device-width, initial-scale=1">'."\n";
    print '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">'."\n";
    print "</head>\n";
}


sub print_html_body_section_top {
    # Create HTML body and show values from 1 - $max ($ncols per row)
    print '<body>'."\n";
    print '<div class="container">'."\n";
    print '<h1>oxd Perl Application - UMA</h1>'."\n";
   
}

sub print_html_body_section_bottom {
   
    print '</div>'."\n";
    print '</body>'."\n";
    print '</html>'."\n";
}

# Displays the  form
sub print_html_form {
	my $response = shift;
	
	if (defined $cgi->param("state") && defined $cgi->param("ticket")) {
		$session->param('uma_state', $cgi->escapeHTML($cgi->param("state")));
		$session->param('uma_ticket', $cgi->escapeHTML($cgi->param("ticket")));
		
		$response = resource();
		
		print '<h1>Resource:</h1>
			</br>';
		print $response->{_content};
		
		print '</br></br></br></br></br></br>
		<a href="uma.cgi"><span class="btn btn-default btn-md glyphicon glyphicon-arrow-left"></span></a>';
	}
	else {
	
	print '<form action="uma.cgi" method="post">';
	print '<div class="row">'."\n";
	print '<div class="col-md-4">'."\n";
	
	
    #print '<ul class = "list-group">'."\n";
	#print '<li class="list-group-item"><a href="uma_rs_protect_test.cgi" target="_blank" >UMA RS Protect</a></li>'."\n";
	#print '<li class="list-group-item"><a href="uma_rs_ckeck_access_test.cgi" target="_blank" >UMA RS Check Access</a></li>'."\n";
	#print '<li class="list-group-item"><a href="uma_rp_get_rpt_test.cgi" target="_blank" >UMA RP - Get RPT</a></li>'."\n";
	#print '<li class="list-group-item"><a href="uma_rp_get_claims_gathering_url_test.cgi" target="_blank" >UMA RP - Get Claims-Gathering URL</a></li>'."\n";
    #print '</ul>'."\n";
	print '</div>'."\n";
	print '</div>'."\n";
	
	print '<div class="row">
				<div class="col-md-4">
					<input type="submit" value="UMA RS Protect" class="btn btn-primary" id="uma_rs_protect" name="uma_rs_protect" >
				</div>
			</div>';
			
	print '<div class="row">
				<div class="col-md-4">
					<input type="submit" value="UMA RS Check Access" class="btn btn-primary" id="uma_rs_check_access" name="uma_rs_check_access" >
				</div>
			</div>';
	
	print '<div class="row">
				<div class="col-md-4">
					<input type="submit" value="UMA RP Get RPT" class="btn btn-primary" id="uma_rp_get_rpt" name="uma_rp_get_rpt" >
				</div>
			</div>';
			
	print '<div class="row">
				<div class="col-md-4">
					<input type="submit" value="UMA Introspect RPT" class="btn btn-primary" id="introspect_rpt" name="introspect_rpt" >
				</div>
			</div>';
			
	print '<div class="row">
				<div class="col-md-4">
					<input type="submit" value="UMA RP Get Claims-Gathering URL" class="btn btn-primary" id="uma_rp_get_claims_gathering_url" name="uma_rp_get_claims_gathering_url" >
				</div>
			</div>'."</br>";
			
			
	print '<div class="row">
				<div class="col-md-4">
					<input type="submit" value="Get Resource" class="btn btn-success" id="get_resource" name="get_resource" >
				</div>
			</div>';
			
	print "$response";
			
	print '</form>';
	
	}
}

sub resource {
	my $response = '';
	if ($session->param('uma_state') && $session->param('uma_ticket')) {
		my $rptStatus = get_rpt();
		
		if ($rptStatus eq 'error') {
			return 'Error while getting the resource';
		}
		
		$httpmethod = 'GET';
		
		if($rptStatus eq 'got_ticket') {
			$response = get_claims();
		}
		elsif($rptStatus eq 'got_rpt') {
			if(is_rpt_active($session->param('uma_rpt')) eq 1) {
				$response = make_http_request($resource_end_point, $httpmethod, $session->param('uma_rpt'), '');
			}
			else {
				$response = 'Inactive RPT';
			}
		}
	}
	else {
		return 'No Resource found';
	}
	
	return $response;
}


sub get_resource_request {
	$httpmethod = 'GET';
	
	my $response = make_http_request($resource_end_point, $httpmethod, '', '');
	
	my $ticketResponse = get_ticket($response);
	$session->param('uma_ticket', $ticketResponse);
	
	if($ticketResponse eq 'Authorized Resource'){
		print_html_form($response);
	}
	
	my $rptStatus = get_rpt();
	
	if($rptStatus eq 'got_ticket') {
		$response = get_claims();
	}
	elsif($rptStatus eq 'got_rpt') {
		if(is_rpt_active($session->param('uma_rpt')) eq 1) {
			$response = make_http_request($resource_end_point, $httpmethod, $session->param('uma_rpt'), '');
			print_html_form($response);
		}
		else {
			print_html_form('Inactive RPT');
		}
	}
	
	print_html_form($response);
}

sub is_rpt_active {
	my $rpt = shift;
	
	$introspect_rpt = new UmaIntrospectRpt();
	$introspect_rpt->setRequestOxdId($oxd_id);
	$introspect_rpt->setRequestRPT($rpt);
	$introspect_rpt->request();

	return $introspect_rpt->getResponseActive();
	
	}

sub get_ticket {
	my $ticketResponse = shift;
	
	if (index($ticketResponse, 'Unauthorized') != -1) {
		my @values = split(';', $ticketResponse);

		foreach my $ticketString (@values) {
			if (index($ticketString, 'ticket') != -1) {
				my @ticketArray = split(':', $ticketString);
				return $ticketArray[1];
			}
		}
	}
	return "Authorized Resource";
}

sub make_http_request {
	    
	my ($endpoint, $httpmethod, $rpt, $data, $char_count) = @_;
	$char_count =  $char_count ? $char_count : 8192;
	
	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });# 0: Do not verify SSL, 1: verify SSL
	$ua->protocols_allowed( [ 'http','https'] );
	
	my $header = HTTP::Headers->new;
	$header->header(Accept => 'application/json', RPT => $rpt);
	
	my $req = HTTP::Request->new($httpmethod, $endpoint, $header);
	
	$req->content($data);
	#Pass request to the user agent and get a response back
	my $response = $ua->request($req);
	
	
	if($response->{_headers}->{ticket}) {
		return "Unauthorized;ticket:".$response->{_headers}->{ticket};
	}
	
	return $response;
}

sub get_rpt {
	
	$uma_rp_get_rpt = new UmaRpGetRpt();
	$uma_rp_get_rpt->setRequestOxdId($oxd_id);
	if ($session->param('uma_ticket')) {
		$uma_rp_get_rpt->setRequestTicket($session->param('uma_ticket'));
	}
	if ($session->param('uma_state')) {
		$uma_rp_get_rpt->setRequestState($session->param('uma_state'));
	}
	$uma_rp_get_rpt->setRequestProtectionAccessToken(getClientToken_authentication());
	$uma_rp_get_rpt->request();

	
	if($uma_rp_get_rpt->getResponseStatus() eq 'error' && $uma_rp_get_rpt->getResponseError() eq 'need_info') {
		my $uma_ticket = $uma_rp_get_rpt->getResponseTicket();
		$session->param('uma_ticket', $uma_ticket);
		return 'got_ticket';
	}

	if($uma_rp_get_rpt->getResponseStatus() eq 'ok') {
		my $uma_rpt= $uma_rp_get_rpt->getResponseRpt();
		$session->param('uma_rpt', $uma_rpt);
		return 'got_rpt';
	}
	
	return 'error';
}

sub get_claims {

	$uma_rp_get_claims_gathering_url = new UmaRpGetClaimsGatheringUrl();
	$uma_rp_get_claims_gathering_url->setRequestOxdId($oxd_id);
	if($session->param('uma_ticket')) {
		$uma_rp_get_claims_gathering_url->setRequestTicket($session->param('uma_ticket'));
	}
	$uma_rp_get_claims_gathering_url->setRequestClaimsRedirectUri('https://client.example.com:8090/cgi-bin/perl_demo/uma.cgi');
	$uma_rp_get_claims_gathering_url->setRequestProtectionAccessToken(getClientToken_authentication());
	
	$uma_rp_get_claims_gathering_url->request();
	
	my $claimsgatherurl = $uma_rp_get_claims_gathering_url->getResponseUrl();
	print '<meta http-equiv="refresh" content="0;URL='.$claimsgatherurl.'" />    ';

	#print_html_form($response);
}


#### Start: UMA Methods for Test
sub uma_rs_protect_request {
	
	# #### Without scope_expression
	# $uma_rs_protect = new UmaRsProtect();
	# $uma_rs_protect->setRequestOxdId($oxd_id);
	# $uma_rs_protect->addConditionForPath(["GET"],["http://photoz.example.com/dev/actions/a214","http://photoz.example.com/dev/actions/a224","http://photoz.example.com/dev/actions/a234"], ["http://photoz.example.com/dev/actions/a214","http://photoz.example.com/dev/actions/a224","http://photoz.example.com/dev/actions/a234"]);
	# $uma_rs_protect->addResource('/GetAll24');
	# $uma_rs_protect->setRequestProtectionAccessToken(getClientToken_authentication());#Test2
	# ########
	
	
	#### Using scope_expression
	$uma_rs_protect = new UmaRsProtect();
	$uma_rs_protect->setRequestOxdId($oxd_id);
	
	%rule = ('and' => [{'or' => [{'var' => 0},{'var' => 1}]},{'var' => 2}]);
	my $data = ["https://client.example.com:44300/api", "https://client.example.com:44300/api1", "https://client.example.com:44300/api2"];
	
	$uma_rs_protect->addConditionForPath(["GET"], [], [], $uma_rs_protect->getScopeExpression(\%rule, $data));
	$uma_rs_protect->addResource('/values');
	$uma_rs_protect->setRequestProtectionAccessToken(getClientToken_authentication());
	########
	
	$uma_rs_protect->request();
	my $response = Dumper( $uma_rs_protect->getResponseObject() );
	
	print_html_form($response);
}


sub uma_rs_check_access_request {

	my $umaRpt = $session->param('uma_rpt');
	
	$uma_rs_check_access = new UmaRsCheckAccess();
	$uma_rs_check_access->setRequestOxdId($oxd_id);
	$uma_rs_check_access->setRequestRpt($umaRpt);
	$uma_rs_check_access->setRequestPath("/values");
	$uma_rs_check_access->setRequestHttpMethod("GET");
	$uma_rs_check_access->setRequestProtectionAccessToken(getClientToken_authentication());#Test2
	
	$uma_rs_check_access->request();
	my $response = Dumper( $uma_rs_check_access->getResponseObject() );

	my $uma_ticket = $uma_rs_check_access->getResponseTicket();
	$session->param('uma_ticket', $uma_ticket);
	
	print_html_form($response);
}


sub uma_rp_get_rpt_request {

	$uma_rp_get_rpt = new UmaRpGetRpt();
	$uma_rp_get_rpt->setRequestOxdId($oxd_id);
	$uma_rp_get_rpt->setRequestTicket($session->param('uma_ticket'));
	$uma_rp_get_rpt->setRequestState($session->param('uma_state'));
	$uma_rp_get_rpt->setRequestProtectionAccessToken(getClientToken_authentication());#Test2
	$uma_rp_get_rpt->request();

	my $response = Dumper($uma_rp_get_rpt->getResponseObject());
	
	
	if($uma_rp_get_rpt->getResponseStatus() eq 'error' && $uma_rp_get_rpt->getResponseError() eq 'need_info') {
		my $uma_ticket = $uma_rp_get_rpt->getResponseTicket();
		$session->param('uma_ticket', $uma_ticket);
	}

	if($uma_rp_get_rpt->getResponseStatus() eq 'ok') {
		my $uma_rpt= $uma_rp_get_rpt->getResponseRpt();
		$session->param('uma_rpt', $uma_rpt);
	}
	
	print_html_form($response);
}


sub introspect_rpt_request {
	
	$introspect_rpt = new UmaIntrospectRpt();
	$introspect_rpt->setRequestOxdId($oxd_id);
	$introspect_rpt->setRequestRPT($session->param('uma_rpt'));
	$introspect_rpt->request();

	my $response = Dumper($introspect_rpt->getResponseObject());
	
	print_html_form($response);
}


sub uma_rp_get_claims_gathering_url_request {

	$uma_rp_get_claims_gathering_url = new UmaRpGetClaimsGatheringUrl();
	$uma_rp_get_claims_gathering_url->setRequestOxdId($oxd_id);
	$uma_rp_get_claims_gathering_url->setRequestTicket($session->param('uma_ticket'));
	$uma_rp_get_claims_gathering_url->setRequestClaimsRedirectUri($claims_redirect_uri);
	$uma_rp_get_claims_gathering_url->setRequestProtectionAccessToken(getClientToken_authentication());#Test2
	
	$uma_rp_get_claims_gathering_url->request();
	my $response = Dumper($uma_rp_get_claims_gathering_url->getResponseObject());
	
	my $claimsgatherurl = $uma_rp_get_claims_gathering_url->getResponseUrl();
	print '<meta http-equiv="refresh" content="0;URL='.$claimsgatherurl.'" />    ';

	#print_html_form($response);
}


sub getClientToken_authentication {

	my $op_host = $session->param('op_host');
	my $client_id = $session->param('client_id');
	my $client_secret = $session->param('client_secret');

	if($client_id && $client_secret){
		
		$get_client_token = new GetClientToken( );
		$get_client_token->setRequestClientId($client_id);
		$get_client_token->setRequestClientSecret($client_secret);
		$get_client_token->setRequestOpHost($op_host);
		$get_client_token->request();
		
		my $clientAccessToken = $get_client_token->getResponseAccessToken();
		$session->param('clientAccessToken', $clientAccessToken);
		
		return $clientAccessToken;
	}
	else {
		return null;
	}
}
#### End: UMA Methods for Test



