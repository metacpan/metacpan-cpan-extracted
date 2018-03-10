#!/usr/bin/perl
# OxdConfig.pm, a number as an object

#
# Gluu-oxd-library
#
# An open source application library for Perl
#
# This content is released under the MIT License (MIT)
#
# Copyright (c) 2018, Gluu inc, USA, Austin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @package	Gluu-oxd-library
# @version      3.1.2
# @author	Ourdesignz, Sobhan Panda
# @author	gaurav.chhabra6785@gmail.com, sobhan@centroxy.com
# @copyright	Copyright (c) 2018, Gluu inc federation (https://gluu.org/)
# @license	http://opensource.org/licenses/MIT	MIT License
# @link         https://gluu.org/
# @since	Version 3.1.2
# @filesource
#/

#
# Oxd RP config
#
# Class OxdConfig, setting all configuration
#
# @package		Gluu-oxd-library
# @subpackage	Libraries
# @category	Base class for all protocols
# @author		Ourdesignz
# @author		gaurav.chhabra6785@gmail.com
#/
package OxdConfig;
use vars qw($VERSION);
$VERSION = '0.01';
use strict;
use warnings;
use JSON::PP;

sub new{
    my $class = shift;
    
    my $self = {
		 
		# @static
		# @var string $op_host        Gluu server url, which need to connect
		_op_host => shift,
        
		# @static
		# @var int $oxd_host_port        Socket connection port
		_oxd_host_port  => shift,
         
		# @static
		# @var string $authorization_redirect_uri        Site authorization redirect uri
        _authorization_redirect_uri => shift,
        
		# @static
		# @var string $post_logout_redirect_uri        Site logout redirect uri
        _post_logout_redirect_uri => shift,
        
		# @static
		# @var string $client_frontchannel_logout_uris              Client logout uri        
        _client_frontchannel_logout_uris => shift,
		# @static
		# @var array $scope        For getting needed scopes from gluu-server
        _scope => shift,
       
		# @static
		# @var string $application_type        web or mobile
        _application_type => shift,
        
		# @static
		# @var array $response_types        OpenID Authentication response types
        _response_types => shift,
       
		# @static
		# @var array $grant_types        OpenID Token Request type
        _grant_types => shift,
         
		# @static
		# @var array $acr_values        Gluu login acr type, can be basic, duo, u2f, gplus and etc.
        _acr_values => shift,
        
                # @static
		# @var array $rest_service_url        Gluu rest service url
        _rest_service_url => shift,
        
                # @static
		# @var array $connection_type        Connection type, can be Socket or http.
        _connection_type => shift,
        
        _oxd_id => shift,
        _client_name => shift,
        _client_id => shift,
        _client_secret => shift,
        _claims_redirect_uri => shift,
        _resource_end_point => shift
    };
    
    # Print all the values just for clarification.
    #print "OP HOST is :". $self->{_op_host};
    #print "<br>";
    #print "OXD HOST PORT is :".$self->{_oxd_host_port};
    our $oxdHostPort;
    $oxdHostPort = 'package'; 
    
    bless $self, $class;
    $self->json_read;
    return $self;
}

sub setOpHost {
    #my ( $self, $op_host,$oxd_host_port,$authorization_redirect_uri,$post_logout_redirect_uri,$scope,$application_type,$response_types,$grant_types,$acr_values ) = @_;
    my ( $self, $op_host ) = @_;
    $self->{_op_host} = $op_host if defined($op_host);
    return $self->{_op_host};
}

sub getOpHost {
    my( $self ) = @_;
    return $self->{_op_host};
}

sub setOxdHostPort {
    my ( $self, $oxd_host_port ) = @_;
    $self->{_oxd_host_port} = $oxd_host_port if defined($oxd_host_port);
    return $self->{_oxd_host_port};
}

sub getOxdHostPort {
    my( $self ) = @_;
    return $self->{_oxd_host_port};
}

sub setAuthorizationRedirectUrl {
    my ( $self, $authorization_redirect_uri ) = @_;
    $self->{_authorization_redirect_uri} = $authorization_redirect_uri if defined($authorization_redirect_uri);
    return $self->{_authorization_redirect_uri};
}

sub getAuthorizationRedirectUrl {
    my( $self ) = @_;
    return $self->{_authorization_redirect_uri};
}

sub setPostLogoutRedirectUrl {
    my ( $self, $post_logout_redirect_uri ) = @_;
    $self->{_post_logout_redirect_uri} = $post_logout_redirect_uri if defined($post_logout_redirect_uri);
    return $self->{_post_logout_redirect_uri};
}

sub getPostLogoutRedirectUrl {
    my( $self ) = @_;
    return $self->{_post_logout_redirect_uri};
}


sub setClientFrontChannelLogoutUris {
    my ( $self, $client_frontchannel_logout_uris ) = @_;
    $self->{_client_frontchannel_logout_uris} = $client_frontchannel_logout_uris if defined($client_frontchannel_logout_uris);
    return $self->{_client_frontchannel_logout_uris};
}

sub getClientFrontChannelLogoutUris {
    my( $self ) = @_;
    return $self->{_client_frontchannel_logout_uris};
}


sub setScope {
    my ( $self, $scope ) = @_;
    $self->{_scope} = $scope if defined($scope);
    return $self->{_scope};
}

sub getScope {
    my( $self ) = @_;
    return $self->{_scope};
}

sub setApplicationType {
    my ( $self, $application_type ) = @_;
    $self->{_application_type} = $application_type if defined($application_type);
    return $self->{_application_type};
}

sub getApplicationType {
    my( $self ) = @_;
    return $self->{_application_type};
}

sub setResponseType {
    my ( $self, $response_types ) = @_;
    $self->{_response_types} = $response_types if defined($response_types);
    return $self->{_response_types};
}

sub getResponseType {
    my( $self ) = @_;
    return $self->{_response_types};
}

sub setGrantTypes {
    my ( $self, $grant_types ) = @_;
    $self->{_grant_types} = $grant_types if defined($grant_types);
    return $self->{_grant_types};
}

sub getGrantTypes {
    my( $self ) = @_;
    return $self->{_grant_types};
}

sub setAcrValues {
    my ( $self, $acr_values ) = @_;
    $self->{_acr_values} = $acr_values if defined($acr_values);
    return $self->{_acr_values};
}

sub getAcrValues {
    my( $self ) = @_;
    return $self->{_acr_values};
}

sub setRestServiceUrl {
    my ( $self, $rest_service_url ) = @_;
    $self->{_rest_service_url} = $rest_service_url if defined($rest_service_url);
    return $self->{_rest_service_url};
}

sub getRestServiceUrl {
    my( $self ) = @_;
    return $self->{_rest_service_url};
}

sub setConnectionType {
    my ( $self, $connection_type ) = @_;
    $self->{_connection_type} = $connection_type if defined($connection_type);
    return $self->{_connection_type};
}

sub getConnectionType {
    my( $self ) = @_;
    return $self->{_connection_type};
}


sub setOxdId {
    my ( $self, $oxd_id ) = @_;
    $self->{_oxd_id} = $oxd_id if defined($oxd_id);
    return $self->{_oxd_id};
}

sub getOxdId {
    my( $self ) = @_;
    return $self->{_oxd_id};
}


sub setClientName {
    my ( $self, $clientName ) = @_;
    $self->{_client_name} = $clientName if defined($clientName);
    return $self->{_client_name};
}

sub getClientName {
    my( $self ) = @_;
    return $self->{_client_name};
}


sub setClientId {
    my ( $self, $client_id ) = @_;
    $self->{_client_id} = $client_id if defined($client_id);
    return $self->{_client_id};
}

sub getClientId {
    my( $self ) = @_;
    return $self->{_client_id};
}


sub setClientSecret {
    my ( $self, $client_secret ) = @_;
    $self->{_client_secret} = $client_secret if defined($client_secret);
    return $self->{_client_secret};
}

sub getClientSecret {
    my( $self ) = @_;
    return $self->{_client_secret};
}


sub setClaimsRedirectUri {
    my ( $self, $claims_redirect_uri ) = @_;
    $self->{_claims_redirect_uri} = $claims_redirect_uri if defined($claims_redirect_uri);
    return $self->{_claims_redirect_uri};
}

sub getClaimsRedirectUri {
    my( $self ) = @_;
    return $self->{_claims_redirect_uri};
}


sub setResourceEndPoint {
    my ( $self, $resource_end_point ) = @_;
    $self->{_resource_end_point} = $resource_end_point if defined($resource_end_point);
    return $self->{_resource_end_point};
}

sub getResourceEndPoint {
    my( $self ) = @_;
    return $self->{_resource_end_point};
}

sub json_read{
	
	my ($self) = @_;
	my $filename = 'oxd-settings.json';
	#my $baseUrl = $self->{_base_url};
	#print $baseUrl;
	my $configOBJECT;
	if (open (my $configJSON, $filename)){
		local $/ = undef;
		my $json = JSON::PP->new;
		$configOBJECT = $json->decode(<$configJSON>);
		  
		if(!$configOBJECT->{authorization_redirect_uri}){
			my $defaultOxdSettingsJson = 'oxd-rp-settings-test.json';
			if(open (my $configJSON, $defaultOxdSettingsJson)){
				if(!my $configJSON){
					#$error = error_get_last();
					OxdClientSocket::log("oxd-configuration-test: ", 'Error problem with json data.');
					OxdClientSocket::error_message("HTTP request failed. Error was: Testing");
				}
				$configOBJECT = $json->decode(<$configJSON>);
			}
		}
		
		#$self->define_variables($configOBJECT);
		
		my $OXD_HOST_PORT = $configOBJECT->{oxd_host_port};
		
		
		if($OXD_HOST_PORT>=0 && $OXD_HOST_PORT<=65535){

		}else{
			OxdClientSocket::error_message($OXD_HOST_PORT." is not a valid port for socket. Port must be integer and between from 0 to 65535.");
		}
		#print $data->{authorization_redirect_uri};
		close($configJSON);
	}
	my $op_host = $configOBJECT->{op_host};
	my $oxd_host_port = $configOBJECT->{oxd_host_port};
	my $authorization_redirect_uri = $configOBJECT->{authorization_redirect_uri};
	my $post_logout_redirect_uri = $configOBJECT->{post_logout_redirect_uri};
	my $client_frontchannel_logout_uris = $configOBJECT->{client_frontchannel_logout_uris};
	my $scope = $configOBJECT->{scope};
	my $application_type = $configOBJECT->{application_type};
	my $response_types = $configOBJECT->{response_types};
	my $grant_types = $configOBJECT->{grant_types};
	my $acr_values = $configOBJECT->{acr_values};
	my $rest_service_url = $configOBJECT->{rest_service_url};
	my $connection_type = $configOBJECT->{connection_type};
	my $oxd_id = $configOBJECT->{oxd_id};
	my $clientName = $configOBJECT->{client_name};
	my $claims_redirect_uri = $configOBJECT->{claims_redirect_uri};
	my $resource_end_point = $configOBJECT->{resource_end_point};
	
	#$self->new( $op_host, $oxd_host_port );
	$self->setOpHost( $op_host );
	$self->setOxdHostPort( $oxd_host_port );
	$self->setAuthorizationRedirectUrl( $authorization_redirect_uri );
	$self->setPostLogoutRedirectUrl( $post_logout_redirect_uri );
	$self->setClientFrontChannelLogoutUris( $client_frontchannel_logout_uris );
	$self->setScope( $scope );
	$self->setApplicationType( $application_type );
	$self->setResponseType( $response_types );
	$self->setGrantTypes( $grant_types );
	$self->setAcrValues( $acr_values );
	$self->setRestServiceUrl( $rest_service_url );
	$self->setConnectionType( $connection_type );
	$self->setOxdId( $oxd_id );
	$self->setClientName( $clientName );
	$self->setClaimsRedirectUri( $claims_redirect_uri );
	$self->setResourceEndPoint( $resource_end_point );
	
	if($configOBJECT->{client_id}){
                my $client_id = $configOBJECT->{client_id};
                $self->setClientId( $client_id );
        }
        if($configOBJECT->{client_secret}){
                my $client_secret = $configOBJECT->{client_secret};
                $self->setClientSecret( $client_secret );
        }
	
	

	
	
=pod	use constant OXD_HOST_PORT => $configOBJECT->{oxd_host_port};
	use constant AUTHORIZATION_REDIRECT_URL => $configOBJECT->{authorization_redirect_uri};
	use constant POST_LOGOUT_REDIRECT_URL => $configOBJECT->{post_logout_redirect_uri};
	use constant SCOPE => $configOBJECT->{scope};
	use constant APPLICATION_TYPE => $configOBJECT->{application_type};
	use constant RESPONSE_TYPES => $configOBJECT->{response_types};
	use constant GRANT_TYPES => $configOBJECT->{grant_types};
	use constant ACR_VALUES => $configOBJECT->{acr_values};
=cut	
	#return $configOBJECT;
}

1;		# this 1; is neccessary for our class to workk
