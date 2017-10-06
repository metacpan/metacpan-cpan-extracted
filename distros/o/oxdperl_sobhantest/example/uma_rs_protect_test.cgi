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
 * Updated On: 08/14/2017
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

my $oxdId = $session->param('oxd_id');


###Test
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



###Test

$uma_rs_protect = new UmaRsProtect();
$uma_rs_protect->setRequestOxdId($oxdId);

# $uma_rs_protect->addConditionForPath(["GET"],["https://photoz.example.com/dev/actions/view"], ["https://photoz.example.com/dev/actions/view"]);
# $uma_rs_protect->addConditionForPath(["POST"],[ "https://photoz.example.com/dev/actions/add"],[ "https://photoz.example.com/dev/actions/add"]);
# $uma_rs_protect->addConditionForPath(["DELETE"],["https://photoz.example.com/dev/actions/remove"], ["https://photoz.example.com/dev/actions/remove"]);
# $uma_rs_protect->addResource('/photo');


$uma_rs_protect->addConditionForPath(["GET"],["https://scim-test.gluu.org/identity/seam/resource/restv1/scim/vas1"], ["https://scim-test.gluu.org/identity/seam/resource/restv1/scim/vas1"]);
$uma_rs_protect->addResource('/scim');
$uma_rs_protect->setRequestProtectionAccessToken(getClientToken_authentication());


$uma_rs_protect->request();
print "UMA RS PROTECT";
print "<br/><br/>";
print "<pre>";
print Dumper( $uma_rs_protect->getResponseObject() );

print '</pre><br/>';

