#!/usr/bin/perl
=pod
/**
 * Language: Perl 5
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @Created On: 08/01/2017
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


my $opHost = '';
my $oxdHostPort = '';
my $authorizationRedirectUrl = '';
my $postLogoutRedirectUrl = '';
my $clientFrontChannelLogoutUrl = '';
my $scope = '';
my $applicationType = '';
my $responseType = '';
my $grantType = '';
my $acrValues = '';
my $restServiceUrl = '';
my $connectionType = '';
my $oxd_id = '';
my $clientName = '';
my $client_id = '';
my $client_secret = '';
my $claims_redirect_uri = '';

my $clientId_exists = false;
my $clientId_visible = false;
if (!$session->param('clientId_visible')){
	$session->param('clientId_visible', false);
}
Load_config_values();


$session->param('oxd_id', $oxd_id);
$session->param('client_id', $client_id);
$session->param('client_secret', $client_secret);
$session->param('op_host', $opHost);
my $client_name = 'oxd_csharp';


# Output the HTTP header
#print $cgi->header ( );

##################
## User-defined ##
##################

##################
## Main program ##
##################
#server_side_ajax();
# Process form if submitted; otherwise display it
if ($cgi->param("registerSite")) {
	# Parameters are defined, therefore the form has been submitted
	oxd_setup_Client($cgi);
} elsif ($cgi->param("update")	) {
	oxd_update($cgi);
} elsif ($cgi->param("delete")) {
	oxd_delete($cgi);
} elsif ($cgi->param("introspectToken")) {
	oxd_introspectAccessToken($cgi);
} else {
	# We're here for the first time, display the form
	print_html_form();
}

print_Jquery_Validations();
print_Styles();



#################
## Subroutines ##
#################
sub print_page_header {
    # Print the HTML header (don't forget TWO newlines!)
    #print "Content-type:  text/html\n\n";
}


sub Load_config_values {
	$object = new OxdConfig();
	$opHost = $object->getOpHost();
	$oxdHostPort = $object->getOxdHostPort();
	$authorizationRedirectUrl = $object->getAuthorizationRedirectUrl();
	$postLogoutRedirectUrl = $object->getPostLogoutRedirectUrl();
	$clientFrontChannelLogoutUrl = $object->getClientFrontChannelLogoutUris();
	$scope = $object->getScope();
	$applicationType = $object->getApplicationType();
	$responseType = $object->getResponseType();
	$grantType = $object->getGrantTypes();
	$acrValues = $object->getAcrValues();
	$restServiceUrl = $object->getRestServiceUrl();
	$connectionType = $object->getConnectionType();
	$oxd_id = $object->getOxdId();
	$clientName = $object->getClientName();
	$client_id = $object->getClientId();
	$client_secret = $object->getClientSecret();
	$claims_redirect_uri = $object->getClaimsRedirectUri();
	
	if($client_id) {
		$clientId_exists = true;
	}
	else {
		$clientId_exists = false;
	}
	
}




sub print_Jquery_Validations {
	print '<script type="text/javascript">
	
		function edit_enable()
		    {
			dis = document.getElementsByClassName("ip_box");
			for(var i = 0; i < dis.length; i++)
			    dis[i].disabled = false;
			document.getElementById("update").disabled = false;
		    }
	
	    $(document).ready(function() {
		
		$(".rbConnectionType").change(function() {
		    switch($(this).val()) {
			case "web" :
			    var oxdPort = jQuery("#oxdPort");
			    var restServiceUrl = jQuery("#restService");
			    oxdPort.css("display","none");
			    restServiceUrl.css("display","block");
			    break;
			case "local" :
			    var oxdPort = jQuery("#oxdPort");
			    var restServiceUrl = jQuery("#restService");
			    oxdPort.css("display","block");
			    restServiceUrl.css("display","none");
			    break;
		    }
		});
		
		$("#registerSite").click(function (event) {
		    var restServiceUrl = jQuery("#restServiceUrl").val();
		    var port = jQuery("#port").val();
		    var connectionType = jQuery("input[name=rbConnectionType]:checked").val();
		    
		    if (connectionType == "web" && restServiceUrl === "") {
			alert("Web address is required");
			return false;
		    }
		    else if (connectionType == "local" && port === "") {
			alert("Port number is required");
			return false;
		    }
		});
		
		});
		
	    $(window).bind("load", function() {
			var connectionType = jQuery("#connectionType").val();
			if(connectionType == "local")
			{
				jQuery("#oxdPort").css("display","block");
				jQuery("#restService").css("display","none");
			}
			else if(connectionType == "web")
			{
				jQuery("#oxdPort").css("display","none");
				jQuery("#restService").css("display","block");
			}
			else
			{
				jQuery("#oxdPort").css("display","none");
				jQuery("#restService").css("display","none");
			}
			$("input[name=rbConnectionType][value=" + connectionType + "]").attr("checked", "checked");
			//$("input[name=rbConnectionType][value=" + connectionType + "]").attr("disabled", true);
			//$("input[name=rbConnectionType]").attr("disabled", true);
			
		});
	

</script>'
}


sub print_Styles {
	print '<style>
	
		.container-fluid{
    background-color: white;
    border-color: #e5eef1;
}

.hr_modified{
    display: block;
    height: 1px;
    width: 80%;
    margin-left: 0px;
}

#bod_div{
    outline-color: #2eea21;
    outline-width: 1px;
    outline-style: solid;
    background-color: #effdff;
    padding: 10px;
    margin-left: -10px;
    margin-right: -13px;
    margin-top: 50px;
}

.row label {
    width: 35%;
}

.ip_box{
    margin-left: 20px;
    margin-right: 0px;
    border-radius: 5px;
}
input[type="number"] {
   width:384px;
}

.ip{
    margin-left: 30px;
    margin-right: 5px;
    border-radius: 5px;
}

select{
    margin-left: 94px;
    width: 384px;
}

.req:before {
  content:"*";
  color:red;
}


</style>';
    }


sub print_html_header {
	print '<html lang="en">
		    <link>
			<meta charset="utf-8">
			<!--bootstrap cdn -->
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
			<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
			<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
			<title>Gluu OpenID Setting</title>
		    </head>';
}

sub print_html_footer {
	my $message = shift;
	
	print '</form>

			    <br>
				<div class="row">
				    <div class="col-md-8">
					<label>oxd id:</label>';
					if($oxd_id) {
					    print "$oxd_id";
					}
			
			print "</div>
				</div>
			       
			    <br>
				<div class='row'>
				    <div class='col-md-8'>
					<label> $message </label>
				    </div>
				</div>


			</div>
		    </body>
		</html>"."\n";
}

# Displays the  form
sub print_html_form {
	my $message = shift;
    
	Load_config_values();
	print_html_header();
	
	
	print '<body class="container" >
			<div id="bod_div">
			    <h3>Setup Client</h3>
			    <hr class="hr_modified">
			   <form action="settings.cgi" method="post">
				<input runat="server" type="hidden" name="connectionType" id="connectionType" value="'.$connectionType.'">
			       <div class="row">
				   <div class="col-md-8">
				       <label>URI of the OpenID Connect Provider: </label>';
				       
				       if($oxd_id){
					    print '<input type="url" value="'.$opHost.'" size="50" class="ip_box" id="ophost" name="ophost" disabled>';
					} else {
					    print '<input type="url" value="'.$opHost.'" size="50" class="ip_box" id="ophost" name="ophost" required>';
					}
					
			print '</div>
			       </div>
			       <br>
			       <div class="row">
				   <div class="col-md-8">
				       <label>Authorization Redirect URI: </label>';
				       
				       if ($oxd_id) {
					    print '<input type="url" value="'.$authorizationRedirectUrl.'" size="50" class="ip_box" id="redirect_uri" name="redirect_uri" disabled required>';
					} else {
					    print '<input type="url" value="'.$authorizationRedirectUrl.'" size="50" class="ip_box" id="redirect_uri" name="redirect_uri" required>';
					    }
			print '</div>
				</div>
			       <br>
				<div class="row">
				    <div class="col-md-8">
					<label>Post logout URI: </label>';
					
					   if ($oxd_id) {
						print '<input type="url" value="'.$postLogoutRedirectUrl.'" size="50" class="ip_box" id="post_logout_uri" name="post_logout_uri" disabled>';
						}
					else {
						print '<input type="url" value="'.$postLogoutRedirectUrl.'" size="50" class="ip_box" id="post_logout_uri" name="post_logout_uri" required>';
						}
			print '</div>
				</div>
			       <br>
			       <div class="row">
				    <div class="col-md-8">
					<label>oxd Connection Type: </label>
					<span class="ip_box">
					    <input type="radio" name="rbConnectionType" id="local" value="local" checked class="rbConnectionType ip_box"> oxd server
					    <input type="radio" name="rbConnectionType" id="web" value="web" class="rbConnectionType ip_box"> oxd https extension
					    </span>';
					   
			print '</div>
				</div>
				<div runat="server" class="row" id="oxdPort">
				    <div class="col-md-8">
					<label>oxd port: </label>';
					
					if ($oxd_id) {
						print '<input type="text" size="50" value="'.$oxdHostPort.'" class="ip_box" id="port" name="port" disabled>';
					    } else {
						print '<input type="text"size="50" value="'.$oxdHostPort.'" placeholder="8099" class="ip_box" id="port" name="port">';
					    }
			print '</div>
				</div>
				<div runat="server" class="row" id="restService">
				    <div class="col-md-8">
					<label>oxd web address: </label>';
					
					if ($oxd_id) {
						print '<input type="text" value="'.$restServiceUrl.'" size="50" class="ip_box" id="restServiceUrl" name="restServiceUrl" disabled>';
					    } else {
						print '<input type="text" value="'.$restServiceUrl.'" size="50" class="ip_box" id="restServiceUrl" name="restServiceUrl">';
					    }
			print '</div>
				</div>
				<br>
				<div class="row">
				    <div class="col-md-8">
					<label>Client Name: </label>';
					
					if ($oxd_id) {
						print '<input type="text" value="'.$clientName.'" size="50" class="ip_box" id="clientName" name="clientName" disabled>';
					    } else {
						print '<input type="text" value="'.$clientName.'" size="50" class="ip_box" id="clientName" name="clientName">';
					    }
					    
			if ($session->param('clientId_visible') eq true || $clientId_exists eq true)
			{
			print '</div>
				</div>
			       <br>
				<div class="row">
				    <div class="col-md-8">
					<label>Client Id: </label>';
					   if ($oxd_id) {
						print '<input type="text" value="'.$client_id.'" size="50" class="ip_box" id="clientId" name="clientId" disabled>';
						}
					else {
						print '<input type="text" value="'.$client_id.'" size="50" class="ip_box" id="clientId" name="clientId" required>';
						}
			print '</div>
				</div>
			       <br>
				<div class="row">
				    <div class="col-md-8">
					<label>Client Secret: </label>';
					
					   if ($oxd_id) {
						print '<input type="text" value="'.$client_secret.'" size="50" class="ip_box" id="clientSecret" name="clientSecret" disabled>';
						}
					else {
						print '<input type="text" value="'.$client_secret.'" size="50" class="ip_box" id="clientSecret" name="clientSecret" required>';
						}
			}
			
			print '</div>
				</div>
			       <br>';

			       if($oxd_id) {
			print '<input type="submit" value="Register" class="btn btn-success" id="registerSite" name="registerSite" disabled>
				    <input type="button" value="Edit" class="btn btn-primary" id="edit" onclick = "edit_enable()" >
				    <input type="submit" value="Update" class="btn btn-primary" id="update" name="update" disabled>
				    ';
			       } else {
			print '<input type="submit" value="Create" class="btn btn-success" id="registerSite" name="registerSite" >
				    <input type="button" value="Edit" class="btn btn-primary" id="edit" onclick = "edit_enable()" disabled>
				    <input type="submit" value="Update" class="btn btn-primary" id="update" name="update" disabled>';
				}
				
			print '&nbsp; <input type="submit" class="btn btn-danger" id="delete" name="delete" onclick = "edit_enable()" value="Delete" >
				&nbsp; <a href="index.cgi" class="btn btn-default" >Go to Login Page</a>';
			
			# if($message){
				# print '</br>$message';
			# }
			
			#<input type="submit" value="Introspect" class="btn btn-success" id="introspectToken" name="introspectToken" >

			
	print_html_footer($message);
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

sub getClientToken_authentication {
	
	my ($opHost, $client_id, $client_secret) = @_;
	
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

sub oxd_setup_Client {
	
	my $ophost_ui = $cgi->param("ophost");
	my $auth_redirect_uri_ui = $cgi->param("redirect_uri");
	my $post_logout_uri_ui = $cgi->param("post_logout_uri");
	my $connection_type = $cgi->param("rbConnectionType");
	my $oxd_port_ui = $cgi->param("port");
	my $web_url = $cgi->param("restServiceUrl");
	my $client_name_ui = $cgi->param("clientName");
	
	my $is_dynamic_op = dynamic_op_check($ophost_ui);
	
	update_config_file($ophost_ui, $is_dynamic_op, $auth_redirect_uri_ui, $post_logout_uri_ui, $connection_type, $oxd_port_ui, $web_url, $client_name_ui);
	
	
	
	if ($is_dynamic_op eq false && $session->param('clientId_visible') eq false)
	{
		$session->param('clientId_visible', true);
		print_html_form();
	}
	elsif ($is_dynamic_op eq false && $session->param('clientId_visible') eq true)
	{
		$client_id = $cgi->param("clientId");
		$client_secret = $cgi->param("clientSecret");
		
		update_client($client_id, $client_secret);
		
		setup_client_req($ophost_ui, $auth_redirect_uri_ui, $post_logout_uri_ui, $client_name_ui);
		# register_site_req($ophost_ui, $auth_redirect_uri_ui, $post_logout_uri_ui, $client_name_ui);#Test2
		print_html_form('Client Setup completed.');
	}
	else
	{
		setup_client_req($ophost_ui, $auth_redirect_uri_ui, $post_logout_uri_ui, $client_name_ui);
		# register_site_req($ophost_ui, $auth_redirect_uri_ui, $post_logout_uri_ui, $client_name_ui);#Test2
		print_html_form('Client Setup completed.');
	}
}

sub setup_client_req {
	my ($ophost_ui, $auth_redirect_uri_ui, $post_logout_uri_ui, $client_name_ui) = @_;
	
	my $setup_client = new OxdSetupClient( );
	
	$setup_client->setRequestOpHost($ophost_ui);
	#$setup_client->setRequestAcrValues($acrValues);
	$setup_client->setRequestAuthorizationRedirectUri($auth_redirect_uri_ui);
	$setup_client->setRequestPostLogoutRedirectUri($post_logout_uri_ui);
	$setup_client->setRequestClientLogoutUris([$clientFrontChannelLogoutUrl]);
	$setup_client->setRequestClaimsRedirectUri([$claims_redirect_uri]);
	$setup_client->setRequestGrantTypes($grantType);
	$setup_client->setRequestResponseTypes($responseType);
	$setup_client->setRequestScope($scope);
	$setup_client->setRequestApplicationType($applicationType);
	$setup_client->setRequestClientName($client_name_ui);
	if($client_id)
	{
		$setup_client->setRequestClientId($client_id);
	}
	if($client_secret)
	{
		$setup_client->setRequestClientSecret($client_secret);
	}
	$setup_client->request();
	
	setup_config($setup_client->getResponseOxdId(), $setup_client->getResponseClientId(), $setup_client->getResponseClientSecret());
	
	$session->param('op_host', $ophost_ui);
	$session->param('oxd_id', $setup_client->getResponseOxdId());
	$session->param('client_id', $setup_client->getResponseClientId());
	$session->param('client_secret', $setup_client->getResponseClientSecret());
	
}

sub register_site_req {
	my ($ophost_ui, $auth_redirect_uri_ui, $post_logout_uri_ui, $client_name_ui) = @_;
	
	my $register_site = new OxdRegister( );#Test2
	
	$register_site->setRequestOpHost($ophost_ui);
	#$register_site->setRequestAcrValues($acrValues);
	$register_site->setRequestAuthorizationRedirectUri($auth_redirect_uri_ui);
	$register_site->setRequestPostLogoutRedirectUri($post_logout_uri_ui);
	$register_site->setRequestClientLogoutUris([$clientFrontChannelLogoutUrl]);
	$register_site->setRequestClaimsRedirectUri([$claims_redirect_uri]);
	$register_site->setRequestGrantTypes($grantType);
	$register_site->setRequestResponseTypes($responseType);
	$register_site->setRequestScope($scope);
	$register_site->setRequestApplicationType($applicationType);
	$register_site->setRequestClientName($client_name_ui);
	# my $protection_access_token = getClientToken_authentication($ophost_ui, $client_id, $client_secret);#Test2
	# $register_site->setRequestProtectionAccessToken($protection_access_token);#Test2
	if($client_id)
	{
		$register_site->setRequestClientId($client_id);
	}
	if($client_secret)
	{
		$register_site->setRequestClientSecret($client_secret);
	}
	$register_site->request();
	
	setup_config($register_site->getResponseOxdId(), $client_id, $client_secret);
	
	$session->param('op_host', $ophost_ui);
	$session->param('oxd_id', $register_site->getResponseOxdId());
	$session->param('client_id', $client_id);
	$session->param('client_secret', $client_secret);
	
}


sub oxd_update {
	
	my $ophost_ui = $cgi->param("ophost");
	my $auth_redirect_uri_ui = $cgi->param("redirect_uri");
	my $post_logout_uri_ui = $cgi->param("post_logout_uri");
	my $connection_type = $cgi->param("rbConnectionType");
	my $oxd_port_ui = $cgi->param("port");
	my $web_url = $cgi->param("restServiceUrl");
	my $client_name_ui = $cgi->param("clientName");
	
	my $is_dynamic_op = dynamic_op_check($ophost_ui);
	
	update_config_file($ophost_ui, $is_dynamic_op, $auth_redirect_uri_ui, $post_logout_uri_ui, $connection_type, $oxd_port_ui, $web_url, $client_name_ui);
	
	if($is_dynamic_op eq true)
	{
		my $protection_access_token = getClientToken_authentication($ophost_ui, $client_id, $client_secret);
		
		$update_site_registration = new UpdateRegistration();
		
		$update_site_registration->setRequestAcrValues($acrValues);
		$update_site_registration->setRequestOxdId($oxd_id);
		$update_site_registration->setRequestAuthorizationRedirectUri($auth_redirect_uri_ui);
		$update_site_registration->setRequestPostLogoutRedirectUri($post_logout_uri_ui);
		$update_site_registration->setRequestContacts([$emal]);
		$update_site_registration->setRequestGrantTypes($grantType);
		$update_site_registration->setRequestResponseTypes($responseType);
		$update_site_registration->setRequestScope($scope);
		$update_site_registration->setRequestProtectionAccessToken($protection_access_token);
		$update_site_registration->setRequestClientName($client_name_ui);
		#$update_site_registration->setRequestClientSecretExpiresAt(1504051200000);# 1599943950 = 13th September 2020
		$update_site_registration->request();
	}
	
	print_html_form('Client updated successfully.');
}

sub oxd_introspectAccessToken {
	
	#my $ophost_ui = $cgi->param("ophost");
	
	Load_config_values();
	
	my $introspect_access_token = new IntrospectAccessToken( );
	my $protection_access_token = getClientToken_authentication($opHost, $client_id, $client_secret);#Test2
	
	$introspect_access_token->setRequestOxdId($oxd_id);
	$introspect_access_token->setRequestAccessToken($protection_access_token);
	
	$introspect_access_token->request();
	
	$response = Dumper( $introspect_access_token->getResponseData() );
	
	print_html_form($response);
}

sub oxd_delete {
	
	my $ophost_ui = $cgi->param("ophost");
	
	use TryCatch;
	try {
		#my $protection_access_token = getClientToken_authentication($ophost_ui, $client_id, $client_secret);#Test2
		$oxd_remove = new OxdRemove();
		$oxd_remove->setRequestOxdId($oxd_id);
		#$oxd_remove->setRequestProtectionAccessToken($protection_access_token);#Test2
		$oxd_remove->request();
	} catch {
		print "Error!"
	};
	
	# $oxd_remove = new OxdRemove();
	# $oxd_remove->setRequestOxdId($oxd_id);
	# $oxd_remove->setRequestProtectionAccessToken($protection_access_token);
	# $oxd_remove->request();
	
	
	$ophost_ui = '';
	my $is_dynamic_op = '';
	my $auth_redirect_uri_ui = '';
	my $post_logout_uri_ui = '';
	my $connection_type = '';
	my $oxd_port_ui = '';
	my $web_url = '';
	my $clientName = '';
	
	update_config_file($ophost_ui, $is_dynamic_op, $auth_redirect_uri_ui, $post_logout_uri_ui, $connection_type, $oxd_port_ui, $web_url, $clientName);
	setup_config('', '', '');
	$session->clear(["clientId_visible", "client_id", "client_secret"]);
	print_html_form('Client removed successfully.');
}


sub setup_config {
	my ($oxd_id, $client_id, $client_secret) = @_;
	
	my $json;
	{
	  local $/; #Enable 'slurp' mode
	  open my $fh, "<", "oxd-settings.json";
	  $json = <$fh>;
	  close $fh;
	}
	my $data = decode_json($json);
	# Output to screen one of the values read
	# Modify the value, and write the output file as json
	$data->{oxd_id} = $oxd_id;
	$data->{client_id} = $client_id;
	$data->{client_secret} = $client_secret;
	open my $fh, ">", "oxd-settings.json";
	print $fh encode_json($data);
	close $fh;
}

sub update_config_file {
	my $opHost = shift;
	my $dynamicRegistration = shift;
	my $authorizationRedirectUrl = shift;
	my $postLogoutRedirectUrl = shift;
	my $connection_type = shift;
	my $oxdHostPort = shift;
	my $web_url = shift;
	my $clientName = shift;
	
	my $json;
	{
	  local $/; #Enable 'slurp' mode
	  open my $fh, "<", "oxd-settings.json";
	  $json = <$fh>;
	  close $fh;
	}
	my $data = decode_json($json);
	
	$data->{op_host} = $opHost;
	$data->{dynamic_registration} = $dynamicRegistration;
	if($authorizationRedirectUrl)
	{
		$data->{authorization_redirect_uri} = $authorizationRedirectUrl;
	}
	if($connection_type eq 'local')
	{
		$data->{oxd_host_port} = $oxdHostPort;
	}
	elsif($connection_type eq 'web')
	{
		$data->{rest_service_url} = $web_url;
	}
	else
	{
		$data->{oxd_host_port} = $oxdHostPort;
		$data->{rest_service_url} = $web_url;
	}
	
	if($connection_type)
	{
		$data->{connection_type} = $connection_type;
	}
	
	$data->{post_logout_redirect_uri} = $postLogoutRedirectUrl;
	$data->{client_name} = $clientName;
	#$data->{oxd_host_port} = $oxdHostPort;
	open my $fh, ">", "oxd-settings.json";
	print $fh encode_json($data);
	close $fh;
}


sub update_client {
	my $clientId = shift;
	my $clientSecret = shift;
	
	my $json;
	{
	  local $/; #Enable 'slurp' mode
	  open my $fh, "<", "oxd-settings.json";
	  $json = <$fh>;
	  close $fh;
	}
	my $data = decode_json($json);
	
	$data->{client_id} = $clientId;
	$data->{client_secret} = $clientSecret;
	
	open my $fh, ">", "oxd-settings.json";
	print $fh encode_json($data);
	close $fh;
}


sub dynamic_op_check {
	my $opHost = shift;
	
	my $lc = substr($opHost, -1);
	if($lc ne '/')
	{
	    $opHost = $opHost.'/';
	}
	
	my $openidUrl = $opHost.".well-known/openid-configuration";
	
	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });# 0: Do not verify SSL, 1: verify SSL
	$ua->protocols_allowed( [ 'http','https'] );

	my $req = HTTP::Request->new('GET', $openidUrl);

	#Pass request to the user agent and get a response back
	my $response = $ua->request($req);
	
	$content = $response->{_content};
	
	my $json = JSON::PP->new;
	my $jsonContent = $json->decode($content);
	
	my $reg_ep = $jsonContent->{registration_endpoint};
	
	#Check the outcome of the response
	if ($jsonContent->{registration_endpoint}) {
		return true;
	} else {
		return false;
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


