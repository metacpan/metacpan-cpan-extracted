#!/usr/bin/perl
=pod
/**
 * Language: Perl 5
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @Created On: 07/18/2017
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
#Load Oxd Perl Module
use OxdPerlModule;
use Data::Dumper;
# Create the CGI object
my $cgi = new CGI;
# will restore any existing session with the session ID in the query object
my $session = CGI::Session->new($cgi);
# print the HTTP header and set the session ID cookie
print $session->header();
 
my $claims_redirect_Uri = 'https://client.example.com:8090/cgi-bin/perl_demo/uma.cgi';
 
my $oxdId = $session->param('oxd_id');

my $op_host = $session->param('op_host');
my $client_id = $session->param('client_id');
my $client_secret = $session->param('client_secret');

sub getClientToken_authentication {
	
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

$uma_rp_get_claims_gathering_url = new UmaRpGetClaimsGatheringUrl();
$uma_rp_get_claims_gathering_url->setRequestOxdId($oxdId);
$uma_rp_get_claims_gathering_url->setRequestTicket($session->param('uma_ticket'));
$uma_rp_get_claims_gathering_url->setRequestClaimsRedirectUri($claims_redirect_Uri);
$uma_rp_get_claims_gathering_url->setRequestProtectionAccessToken(getClientToken_authentication());
$uma_rp_get_claims_gathering_url->request();

print "UMA RP GET Claims Gathering Url";
print "<br/><br/>";
print "<pre>";
print Dumper($uma_rp_get_claims_gathering_url->getResponseObject());



