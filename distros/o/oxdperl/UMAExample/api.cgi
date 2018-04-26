#!/usr/bin/perl
=pod
/**
 * Language: Perl 5
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @Created On: 03/08/2018
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
use OxdPerlModule;
use Data::Dumper;


# Create the CGI object
my $cgi = new CGI;
# will restore any existing session with the session ID in the query object
my $session = CGI::Session->new($cgi);
# print the HTTP header and set the session ID cookie
print $session->header();

my $object = new OxdConfig();
my $opHost = $object->getOpHost();
my $oxd_id = $object->getOxdId();
my $client_id = $object->getClientId();
my $client_secret = $object->getClientSecret();

check_access();

sub Resource {
	%values = ('1' => 'value1', '2' => 'value2', '3' => 'value3');
	print Dumper( \%values );
}


sub check_access {
    shift @_;
    
    
    
    my $uma_rs_check_access = new UmaRsCheckAccess();
    $uma_rs_check_access->setRequestOxdId($oxd_id);
    if(%ENV->{HTTP_RPT}) {
    	$uma_rs_check_access->setRequestRpt(%ENV->{HTTP_RPT});
    }
    $uma_rs_check_access->setRequestPath("/api.cgi");
    $uma_rs_check_access->setRequestHttpMethod("GET");
    $uma_rs_check_access->setRequestProtectionAccessToken(getClientToken_authentication());
    $uma_rs_check_access->request();
    if($uma_rs_check_access->getResponseObject()->{status} eq 'ok' && $uma_rs_check_access->getResponseObject()->{data}->{access} eq 'granted') {
        Resource();
    }
    elsif($uma_rs_check_access->getResponseObject()->{status} eq 'ok' && $uma_rs_check_access->getResponseObject()->{data}->{access} eq 'denied') {
        print "ticket:".$uma_rs_check_access->getResponseTicket();
    }

    my $uma_ticket = $uma_rs_check_access->getResponseTicket();
    
}


sub getClientToken_authentication {
	
	if($client_id && $client_secret){
		
		$get_client_token = new GetClientToken( );
		$get_client_token->setRequestClientId($client_id);
		$get_client_token->setRequestClientSecret($client_secret);
		$get_client_token->setRequestOpHost($opHost);
		$get_client_token->request();
		
		my $clientAccessToken = $get_client_token->getResponseAccessToken();
		$session->param('clientAccessToken', $clientAccessToken);
		
		return $clientAccessToken;
	}
	else {
		return null;
	}
}
