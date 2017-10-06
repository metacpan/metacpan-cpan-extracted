#!/usr/bin/perl

use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser); # show errors in browser
use CGI::Session;
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

if(defined $session->param("state") && $session->param('user_oxd_id_token') && $session->param('session_state')){
    
    print '<p>User login process via OpenID.</p>';
    print '<p>Logout.</p>';
    
    my $oxd_id = $cgi->escapeHTML($session->param('oxd_id'));
	my $user_oxd_id_token = $cgi->escapeHTML($session->param("user_oxd_id_token"));
	my $session_state = $cgi->escapeHTML($session->param("session_state"));
	my $state = $cgi->escapeHTML($session->param("state"));
    
    $logout = new OxdLogout();
    $logout->setRequestOxdId($oxd_id);
    $logout->setRequestPostLogoutRedirectUri($postLogoutRedirectUrl);
    $logout->setRequestIdToken($user_oxd_id_token);
    $logout->setRequestSessionState($session_state);
    $logout->setRequestState($state);
    $logout->request();

    $session->delete();
    $logoutUrl = $logout->getResponseObject()->{data}->{uri};
    print '<meta http-equiv="refresh" content="0;URL='.$logoutUrl.'" /> ';
    exit(0);
}else{
	print '<meta http-equiv="refresh" content="0;URL=https://oxd-perl-example.com/" /> ';
}
exit(0);
