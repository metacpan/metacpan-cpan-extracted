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
#Load oxd Perl Module
use OxdPerlModule;

# Create the CGI object
my $cgi = new CGI;
# will restore any existing session with the session ID in the query object
my $session = CGI::Session->new($cgi);
# print the HTTP header and set the session ID cookie
print $session->header();


$object = new OxdConfig();
my $opHost = $object->getOpHost();
my $oxdHostPort = $object->getOxdHostPort();
my $authorizationRedirectUrl = $object->getAuthorizationRedirectUrl();
my $postLogoutRedirectUrl = $object->setPostLogoutRedirectUrl();
my $clientFrontChannelLogoutUrl = $object->getClientFrontChannelLogoutUris();
my $scope = $object->getScope();
my $applicationType = $object->getApplicationType();
my $responseType = $object->getResponseType();
my $grantType = $object->getGrantTypes();
my $acrValues = $object->getAcrValues();
my $oxd_id = $object->getOxdId();
my $client_id = $object->getClientId();
my $client_secret = $object->getClientSecret();

#my $oxd_id = "1a571029-ed79-491c-8c27-f2a0a1385e5c";
#$session->param('oxd_id', $oxd_id);
my $client_name = 'Centroxy_Gluu';

###Test
# my $oxd_id = "584d9d83-1429-4611-80f6-2ef6694ff796";
$session->param('oxd_id', $oxd_id);
# print "oxd_id:".$session->param('oxd_id')."\n";

# my $client_id = "@!1736.179E.AA60.16B2!0001!8F7C.B9AB!0008!0C19.FD14.2D7E.206D";
$session->param('client_id', $client_id);
# print "Client_id:".$session->param('client_id')."\n";

# my $client_secret = "f33bf456-a7d7-46d1-b941-fa891ab34915";
$session->param('client_secret', $client_secret);
# print "Client_secret:".$session->param('client_secret')."\n";

$session->param('op_host', $opHost);
###Test


# Output the HTTP header
#print $cgi->header ( );

##################
## User-defined ##
##################

##################
## Main program ##
##################
#server_side_ajax();
print_page_header();
print_html_head_section();
print_html_body_section_top();
# Process form if submitted; otherwise display it
if($cgi->param("OpenIDLogin")) {
	# Parameters are defined, therefore the form has been submitted
	display_results($cgi);
} else {
	# We're here for the first time, display the form
	print_html_form();
}

print_html_body_section_bottom();
print_Jquery_Validations();


#$object->setRequestOpHost( "Mohd." );
#my $firstName = $object->getRequestOpHost();
#print $firstName;


#################
## Subroutines ##
#################
sub print_page_header {
    # Print the HTML header (don't forget TWO newlines!)
    #print "Content-type:  text/html\n\n";
}


sub print_html_head_section {
    # Include stylesheet 'pm.css', jQuery library,
    # and javascript 'pm.js' in the <head> of the HTML.
    ##
    print "<!DOCTYPE html>\n";
    print '<html lang="en">'."\n";
    print '<head>'."\n";
    print '<title>oxd Perl Application</title>'."\n";
    print '<meta charset="utf-8">'."\n";
    print '<meta name="viewport" content="width=device-width, initial-scale=1">'."\n";
    print '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">'."\n";
    print '<script src="//ajax.googleapis.com/ajax/libs/jquery/1.8/jquery.min.js"></script>'."\n";
    print "</head>\n";
}

sub print_Jquery_Validations {
	print '<script type="text/javascript">

	    $(document).ready(function() {
		jQuery("#formLogin").hide();
		
		$(".rbLoginType").change(function() {
		    switch($(this).val()) {
			case "openid" :
			    var formLogin = jQuery("#formLogin");
			    var openIDLogin = jQuery("#openIDLogin");
			    formLogin.hide();
			    openIDLogin.show();
			    break;
			case "loginform" :
			    var formLogin = jQuery("#formLogin");
			    var openIDLogin = jQuery("#openIDLogin");
			    formLogin.show();
			    openIDLogin.hide();
			    break;
		    }
		});
		});

</script>'
}


sub print_html_body_section_top {
    # Create HTML body and show values from 1 - $max ($ncols per row)
    print '<body>'."\n";
    print '<div class="container">'."\n";
    print '<div class="jumbotron"><h1>Gluu oxd Perl Application</h1></div>'."\n";
   
}

sub print_html_body_section_bottom {    
   
    print '</div>'."\n";
    print '</body>'."\n";
    print '</html>'."\n";
}

# Displays the  form
sub print_html_form {
	my $error_message = shift;
    my $your_mail = shift;
    my $gluu_server_url = shift;
    

    # Remove any potentially malicious HTML tags
    if($your_mail){
		$your_mail =~ s/<([^>]|\n)*>//g;
	}else{
		$your_mail = "";
	}
	if(!$gluu_server_url){
		$gluu_server_url = "";
	}
	
	print '<div class="row">'."\n";
    print '<div class="col-md-4">'."\n";
    if($error_message){
		print '<p>'.$error_message.'</p>';
	}
	print '<form name="gluu-form" action="index.cgi" method="post" >
			<br><br>
			<div runat="server" id="formLogin" visible="false" class="jumbotron">
				<div class="form-group">
					<label for="username">User Name</label>
					<input type="text" class="form-control" id="username" name="username" placeholder="Enter UserName" />
				</div>
				<div class="form-group">
					<label for="password">Password</label>
					<input type="text" class="form-control" id="password" name="password" placeholder="Enter Password" />
				</div>
				<input type="button" name="Login" value="Login" class="btn btn-info" >
				
			</div>
			<div runat="server" id="openIDLogin">
				<input type="submit" name="OpenIDLogin" value="Login by OpenID Provider" id="OpenIDLogin" class="btn btn-success" >
				<br><br>
			</div>
				<input type="radio" name="loginMode" id="openid" value="openid" checked class="rbLoginType"> Login by OpenID Provider<br>
				<input type="radio" name="loginMode" id="loginform" value="loginform" class="rbLoginType"> Show Login form
				
			</form><br/><br/><br/><br/><br/>
			<a href="settings.cgi" class="btn btn-default">Settings</a>
			<a href="uma.cgi" class="btn btn-default" target="_blank">UMA</a>
			'."\n";
	print '</div>'."\n";
    print '</div>'."\n";
}

# Validate submiited data
sub validate_form
{
    my $your_mail = $cgi->param("your_mail");
    my $gluu_server_url = $cgi->param("gluu_server_url");
   
    my $error_message = "";

    $error_message .= "Please enter your email<br/>" if ( !$your_mail );
    $error_message .= "Please specify your Gluu url<br/>" if ( !$gluu_server_url );
    
    if ( $error_message )
    {
        # Errors with the form - redisplay it and return failure
        print_html_form ( $error_message, $your_mail, $gluu_server_url);
        return 0;
    }
    else
    {
        # Form OK - return success
        return 1;
    }
}

# Displays the results of the form
sub display_results {
	my $email = $cgi->param('your_mail');
	my $gluu_server_url = $cgi->param('gluu_server_url');
        
        print '<div class="row">'."\n";
        print '<div class="col-md-8">'."\n";
		#print $cgi->h4("Your Email: $email");
		#print $cgi->h4("Your Gluu server url:  $gluu_server_url");
		print '</div>';
		print '</div>';
		# in main program
		#my $worker = Employee->new("Fred Flintstone", 1234, 40);
		oxd_authentication($email, $gluu_server_url);
	
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


sub oxd_authentication{
	
	my ($email, $gluu_server_url) = @_;
   
	use Data::Dumper;
	my $oxd_id = $session->param('oxd_id');
	
	if($session->param('oxd_id') eq ""){
		
		print '<h5><span style="color:red;">First go to setting page and get oxd_id, client_id and client_secret</span></h5>';
		print '<br/><br/><a href="settings.cgi" class="btn btn-default">Settings</a>';
		exit 0;
		
	}
	
	my $is_dynamic_op = dynamic_op_check($opHost);
	
	my $protection_access_token = '';
	if($session->param('client_id') && $session->param('client_secret') && $is_dynamic_op eq true) {
		$protection_access_token = getClientToken_authentication();
	}
	
	## Custom parameters : 'key' => 'value'
	%customParams = ('param1' => 'value1', 'param2' => 'value2');
	
	$get_authorization_url = new GetAuthorizationUrl( );
	$get_authorization_url->setRequestOxdId($session->param('oxd_id'));
	$get_authorization_url->setRequestScope($scope);
	$get_authorization_url->setRequestAcrValues($acrValues);
	$get_authorization_url->setRequestPrompt('login');
	$get_authorization_url->setRequestCustomParams(\%customParams);
	$get_authorization_url->setRequestProtectionAccessToken($protection_access_token);
	$get_authorization_url->request();
    my $oxdurl = $get_authorization_url->getResponseAuthorizationUrl();
    
    #print "<META HTTP-EQUIV=refresh CONTENT=\"$t;URL=$oxdurl\">";
	print '<meta http-equiv="refresh" content="0;URL='.$oxdurl.'" />    ';


	#exit 0;
}

sub getClientToken_authentication {
	my $oxd_id = $session->param('oxd_id');
	my $op_host = $session->param('op_host');
	my $client_id = $session->param('client_id');
	my $client_secret = $session->param('client_secret');
	
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

sub server_side_ajax {
    my $mode = param('mode') || "";
    ($mode eq 'info') or return;

    # If we get here, it's because we were called with 'mode=info'
    # in the HTML request (via the ajax function 'ajax_info()').
    ##
    print "Content-type:  text/html\n\n";  # Never forget the header!
    my $ltime = localtime();
    print "Server local time is $ltime";
    exit;
}


