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
# new query object
my $cgi = CGI->new();

# new session object, will get session ID from the query object
# will restore any existing session with the session ID in the query object
my $session = CGI::Session->new($cgi);

# print the HTTP header and set the session ID cookie
print $session->header();
#BEGIN {push @INC, '..'}
use OxdPerlModule;
use Data::Dumper;

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


display_form();

		
sub display_form()
{
	if (defined $cgi->param("code") && defined $cgi->param("state")) {
		
		my $oxd_id = $session->param('oxd_id');
		my $code = $cgi->escapeHTML($cgi->param("code"));
		my $state = $cgi->escapeHTML($cgi->param("state"));
		
		my $is_dynamic_op = dynamic_op_check($op_host);
		my $protection_access_token = '';
		if($is_dynamic_op eq true) {
			$protection_access_token = getClientToken_authentication();
		}
		
		### Step-1: Get access_token and refresh_token by using code and state
		$get_tokens_by_code = new GetTokenByCode();
		$get_tokens_by_code->setRequestOxdId($oxd_id);
		$get_tokens_by_code->setRequestCode($code);
		$get_tokens_by_code->setRequestState($state);
		$get_tokens_by_code->setRequestProtectionAccessToken($protection_access_token);
		$get_tokens_by_code->request();
		
		#store values in sessions
		$session->param('user_oxd_id_token', $get_tokens_by_code->getResponseIdToken());
		$session->param('state', $state);
		$session->param('session_state', $cgi->escapeHTML($cgi->param("session_state")));
		
		my $access_token = $get_tokens_by_code->getResponseAccessToken();
		
		### If the OP supports dynamic registration, then execute
		if($is_dynamic_op eq true) {
			### Step-2: Introspect the access token which will return the token status (Active=True/False)
			my $introspect_access_token = new IntrospectAccessToken( );
			
			$introspect_access_token->setRequestOxdId($oxd_id);
			$introspect_access_token->setRequestAccessToken($access_token);
			$introspect_access_token->request();
			
			
			### Step-3: If the access_token from Step-1 is not active, get a fresh access_token and refresh_token by using the refresh_token from the previous step-1
			if($introspect_access_token->getResponseActive() ne 1) {
				$get_access_token_by_refresh_token = new GetAccessTokenByRefreshToken();
				$get_access_token_by_refresh_token->setRequestOxdId($oxd_id);
				$get_access_token_by_refresh_token->setRequestRefreshToken($get_tokens_by_code->getResponseRefreshToken());
				#$get_access_token_by_refresh_token->setRequestScopes($scope);
				$get_access_token_by_refresh_token->setRequestProtectionAccessToken($protection_access_token);#Test2
				$get_access_token_by_refresh_token->request();
				
				$access_token = $get_access_token_by_refresh_token->getResponseAccessToken();
				#my $newRefreshToken = $get_access_token_by_refresh_token->getResponseRefreshToken();
			}
		}
		
		### Step-4: Get user info by using the new access_token
		$get_user_info = new GetUserInfo();
		$get_user_info->setRequestOxdId($oxd_id);
		$get_user_info->setRequestAccessToken($access_token);
		$get_user_info->setRequestProtectionAccessToken($protection_access_token);#Test2
		$get_user_info->request();
		
		my $username = $get_user_info->getResponseObject()->{data}->{claims}->{name}[0];
		my $useremail = $get_user_info->getResponseObject()->{data}->{claims}->{email}[0];
		my $givenName = $get_user_info->getResponseObject()->{data}->{claims}->{given_name}[0];
		my $familyName = $get_user_info->getResponseObject()->{data}->{claims}->{family_name}[0];
		$session->param('username', $username);
		$session->param('useremail', $useremail);
		$session->param('givenname', $givenName);
		$session->param('familyname', $familyName);
			
		print '<meta http-equiv="refresh" content="0;URL=userinfo.cgi" /> ';
		
		#exit(0);

		}else{
			print Dumper( $cgi->param );
			#exit(0);
	}
}


