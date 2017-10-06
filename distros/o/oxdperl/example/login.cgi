#!/usr/bin/perl

use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser); # show errors in browser
use CGI::Session;

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

print '<p>User login process via OpenID.</p>';
print '<p><a href="https://oxd-perl-example.com/logout.cgi">Logout</a></p>';
print '<p>Giving user information.</p>';
print '<p><h2>Get User info</h2></p>';

		

if (defined $cgi->escapeHTML($session->param('oxd_id')) && $cgi->escapeHTML($session->param('oxd_id')) ne '' && not defined $cgi->escapeHTML($session->param('state'))) {
	if (defined $cgi->param("code") && defined $cgi->param("state")) {
		
		my $oxd_id = $cgi->escapeHTML($session->param('oxd_id'));
		my $code = $cgi->escapeHTML($cgi->param("code"));
		my $state = $cgi->escapeHTML($cgi->param("state"));
		
		$get_tokens_by_code = new GetTokenByCode();
        $get_tokens_by_code->setRequestOxdId($oxd_id);
        $get_tokens_by_code->setRequestCode($code);
        $get_tokens_by_code->setRequestState($state);
        $get_tokens_by_code->request();
        #store values in sessions
        $session->param('user_oxd_id_token', $get_tokens_by_code->getResponseIdToken());
        $session->param('state', $state);
        $session->param('session_state', $cgi->escapeHTML($cgi->param("session_state")));
        
        $get_user_info = new GetUserInfo();
        $get_user_info->setRequestOxdId($oxd_id);
        $get_user_info->setRequestAccessToken($get_tokens_by_code->getResponseAccessToken());
        $get_user_info->request();
        
        print Dumper( $get_user_info->getResponseObject() );
        exit(0);
       
	}else{
		print Dumper( $cgi->param );
		exit(0);
	}
}else{
	#print Dumper( $session->param );
	print '<b>user_oxd_id_token: </b>'.$session->param('user_oxd_id_token');
	print "<br />";
	print '<b>state: </b>'.$session->param('state');
	print "<br />";
	print '<b>session_state: </b>'.$session->param('session_state');
	print "<br />";
	print '<b>oxd_id: </b>'.$session->param('oxd_id');
	exit(0);
}
