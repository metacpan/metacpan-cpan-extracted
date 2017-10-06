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
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser); # show errors in browser
use CGI::Session;
use JSON::PP;
use OxdPerlModule;
# new query object
my $cgi = CGI->new();

# new session object, will get session ID from the query object
# will restore any existing session with the session ID in the query object
my $session = CGI::Session->new($cgi);

# print the HTTP header and set the session ID cookie
print $session->header();
#BEGIN {push @INC, '..'}

use Data::Dumper;

$object = new OxdConfig();
my $postLogoutRedirectUrl = $object->getPostLogoutRedirectUrl();


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

sub dynamic_op_check {
	my $json;
	{
	  local $/; #Enable 'slurp' mode
	  open my $fh, "<", "oxd-settings.json";
	  $json = <$fh>;
	  close $fh;
	}
	my $data = decode_json($json);
	my $op_reg_type = $data->{dynamic_registration};
	close $fh;
	
	return $op_reg_type;
}


if(defined $session->param("state") && $session->param('user_oxd_id_token') && $session->param('session_state')){
	print '<p>User login process via OpenID.</p>';
	print '<p>Logout.</p>';
    
	my $oxd_id = $cgi->escapeHTML($session->param('oxd_id'));
	my $user_oxd_id_token = $cgi->escapeHTML($session->param("user_oxd_id_token"));
	my $session_state = $cgi->escapeHTML($session->param("session_state"));
	my $state = $cgi->escapeHTML($session->param("state"));
    
	my $is_dynamic_op = dynamic_op_check($op_host);
	my $protection_access_token = '';
	if($is_dynamic_op eq true) {
		$protection_access_token = getClientToken_authentication();
	}
	    $logout = new OxdLogout();
	    $logout->setRequestOxdId($oxd_id);
	    $logout->setRequestPostLogoutRedirectUri($postLogoutRedirectUrl);
	    $logout->setRequestIdToken($user_oxd_id_token);
	    $logout->setRequestSessionState($session_state);
	    $logout->setRequestState($state);
	    $logout->setRequestProtectionAccessToken($protection_access_token);
	    $logout->request();

	    $session->delete();
	    $logoutUrl = $logout->getResponseObject()->{data}->{uri};
	    print '<meta http-equiv="refresh" content="0;URL='.$logoutUrl.'" /> ';
	    exit(0);
	}else{
		print '<meta http-equiv="refresh" content="0;URL=index.cgi" /> ';
	}
	exit(0);
