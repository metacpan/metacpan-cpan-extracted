#!/usr/bin/perl
# OxdSetupClient.pm, a number as an object

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
# @version      3.1.3
# @author	Sobhan Panda
# @author	sobhan@centroxy.com
# @copyright	Copyright (c) 2018, Gluu inc federation (https://gluu.org/)
# @license	http://opensource.org/licenses/MIT	MIT License
# @link         https://gluu.org/
# @since	Version 3.1.3
# @filesource
#/

use JSON::PP;

package OxdSetupClient;	# This is the &quot;Class&quot;
    use vars qw($VERSION);
    $VERSION = '0.01';
    
	use OxdPackages::OxdClient;
	use base qw(OxdClient Class::Accessor);
	#use base 'OxdClient';
	use strict;
	our @ISA = qw(OxdClient);    # inherits from OxdClient
	
	sub new {
		my $class = shift;
		
		my $self = {
			#_firstName => shift,
			#_lastName  => shift,
			#_ssn       => shift,
			
			# @var string _request_op_host                         Gluu server url
			_request_op_host => shift,
			
			# @var array _request_acr_values                       Gluu login acr type, can be basic, duo, u2f, gplus and etc.
			_request_acr_values => [],
			
			# @var string _request_authorization_redirect_uri      Site authorization redirect uri
			_request_authorization_redirect_uri => shift,
			
			# @var string _request_post_logout_redirect_uri             Site logout redirect uri
			_request_post_logout_redirect_uri => shift,
			
			# @var array _request_contacts
			_request_contacts => shift,
			
			# @var array _request_grant_types                     OpenID Token Request type
			_request_grant_types => [],
			
			#@var array _request_response_types                   OpenID Authentication response types
			_request_response_types => [],
			
			# @var array _request_scope                            For getting needed scopes from gluu-server
			_request_scope => [],
			
			# @var string _request_application_type                web or mobile
			_request_application_type => shift,
			
			# @var string _request_client_id                       OpenID provider client id
			_request_client_id => shift,
			
			# @var string _request_client_name                     OpenID provider client name
			_request_client_name => shift,
			
			# @var string _request_client_secret     OpenID provider client secret
			_request_client_secret => shift,
			
			
			# @var string _request_client_jwks_uri
			_request_client_jwks_uri => shift,
			
			# @var string _request_client_token_endpoint_auth_method
			_request_client_token_endpoint_auth_method => shift,
			
			# @var array _request_client_sector_identifier_uri
			_request_client_sector_identifier_uri => shift,
			
			# @var array _request_client_request_uris
			_request_client_request_uris => shift,
			
			# @var array _request_client_logout_uris
			_request_client_frontchannel_logout_uris => shift,
			
			# @var array _request_ui_locales
			_request_ui_locales => shift,
			
			# @var array _request_claims_locales
			_request_claims_locales => shift,
			
			# @var string _request_claims_redirect_uri
			_request_claims_redirect_uri => shift,
			
			
			# Response parameter from oxd-server
			# It is basic parameter for other protocols
			#
			# @var string _response_oxd_id
			_response_oxd_id => shift,

			# @var string _response_op_host
			_response_op_host => shift,
			
			# @var string _response_client_id
			_response_client_id => shift,
			
			# @var string _response_client_secret
			_response_client_secret => shift,
			
			# @var string _response_client_registration_access_token
			_response_client_registration_access_token => shift,
			
			# @var string _response_client_registration_client_uri
			_response_client_registration_client_uri => shift,
			
			# @var string _response_client_id_issued_at
			_response_client_id_issued_at => shift,
			
			# @var string _response_client_secret_expires_at
			_response_client_secret_expires_at => shift,
			
		};
		# Print all the values just for clarification.
		#print "First Name is $self->{_firstName}\n";
		#print "Last Name is $self->{_lastName}\n";
		#print "URl is $self->{_request_authorization_redirect_uri}\n";
		#print "<br>";
		bless $self, $class;
		return $self;
	}  
	sub _initialize {} 
    # @return string
	sub getRequestClientName{
        my( $self ) = @_;
		return $self->{_request_client_name};
    }

    # @param string $request_client_name
    sub setRequestClientName{
        my ( $self, $request_client_name ) = @_;
		$self->{_request_client_name} = $request_client_name if defined($request_client_name);
		return $self->{_request_client_name};
    }
    
    # @return string
    sub getRequestClientSecret{
        my( $self ) = @_;
		return $self->{_request_client_secret};
    }

    # @param string $request_client_secret
    sub setRequestClientSecret{
        my ( $self, $request_client_secret ) = @_;
		$self->{_request_client_secret} = $request_client_secret if defined($request_client_secret);
		return $self->{_request_client_secret};
    }
    
    # @return string
    sub getRequestClientId{
        my( $self ) = @_;
		return $self->{_request_client_id};
    }

    # @param string $request_client_id
    sub setRequestClientId{
        my ( $self, $request_client_id ) = @_;
		$self->{_request_client_id} = $request_client_id if defined($request_client_id);
		return $self->{_request_client_id};
    }
    
    # @param string $request_op_host
    # @return void
    sub setRequestOpHost {
		my ( $self, $request_op_host ) = @_;
		$self->{_request_op_host} = $request_op_host if defined($request_op_host);
		return $self->{_request_op_host};
	}
  
    # @return string
    sub getRequestOpHost {
		my( $self ) = @_;
		return $self->{_request_op_host};
	}
    
    # @return array
    sub getRequestClientLogoutUris{
        my( $self ) = @_;
		return $self->{_request_client_frontchannel_logout_uris};
    }

    # @param array $request_client_logout_uris
    # @return void
    sub setRequestClientLogoutUris{
        my ( $self, $request_client_frontchannel_logout_uris ) = @_;
		$self->{_request_client_frontchannel_logout_uris} = $request_client_frontchannel_logout_uris if defined($request_client_frontchannel_logout_uris);
		return $self->{_request_client_frontchannel_logout_uris};
    }
	
	# @return array
    sub getRequestResponseTypes{
        my( $self ) = @_;
		return $self->{_request_response_types};
    }

    # @param array $request_response_types
    # @return void
    sub setRequestResponseTypes{
        my ( $self, $request_response_types ) = @_;
		$self->{_request_response_types} = $request_response_types if defined($request_response_types);
		return $self->{_request_response_types};
    }
    
    # @return array
    sub getRequestGrantTypes{
        my( $self ) = @_;
		return $self->{_request_grant_types};
    }

    # @param array $request_grant_types
    # @return void
    sub setRequestGrantTypes{
        my ( $self, $request_grant_types ) = @_;
		$self->{_request_grant_types} = $request_grant_types if defined($request_grant_types);
		return $self->{_request_grant_types};
    }
    
    # @return array
    sub getRequestScope{
        my( $self ) = @_;
		return $self->{_request_scope};
    }

    # @param array $request_scope
    # @return void
    sub setRequestScope{
        my ( $self, $request_scope ) = @_;
		$self->{_request_scope} = $request_scope if defined($request_scope);
		return $self->{_request_scope};
    }

    # @return string
    sub getRequestPostLogoutRedirectUri{
        my( $self ) = @_;
		return $self->{_request_post_logout_redirect_uri};
    }

    # @param string $request_post_logout_redirect_uri
    # @return void
    sub setRequestPostLogoutRedirectUri{
        my ( $self, $request_post_logout_redirect_uri ) = @_;
		$self->{_request_post_logout_redirect_uri} = $request_post_logout_redirect_uri if defined($request_post_logout_redirect_uri);
		return $self->{_request_post_logout_redirect_uri};
    }

    # @return string
    sub getRequestClientJwksUri{
        my( $self ) = @_;
		return $self->{_request_client_jwks_uri};
    }

    # @param string $request_client_jwks_uri
    # @return void
    sub setRequestClientJwksUri{
        my ( $self, $request_client_jwks_uri ) = @_;
		$self->{_request_client_jwks_uri} = $request_client_jwks_uri if defined($request_client_jwks_uri);
		return $self->{_request_client_jwks_uri};
    }

    # @return array
    sub getRequestClientSectorIdentifierUri{
        my( $self ) = @_;
		return $self->{_request_client_sector_identifier_uri};
    }

    # @param array $request_client_sector_identifier_uri
    sub setRequestClientSectorIdentifierUri{
        my ( $self, $request_client_sector_identifier_uri ) = @_;
		$self->{_request_client_sector_identifier_uri} = $request_client_sector_identifier_uri if defined($request_client_sector_identifier_uri);
		return $self->{_request_client_sector_identifier_uri};
    }

    # @return string
    sub getRequestClientTokenEndpointAuthMethod{
        my( $self ) = @_;
		return $self->{_request_client_token_endpoint_auth_method};
    }

    # @param string $request_client_token_endpoint_auth_method
    # @return void
    sub setRequestClientTokenEndpointAuthMethod{
        my ( $self, $request_client_token_endpoint_auth_method ) = @_;
		$self->{_request_client_token_endpoint_auth_method} = $request_client_token_endpoint_auth_method if defined($request_client_token_endpoint_auth_method);
		return $self->{_request_client_token_endpoint_auth_method};
    }

    # @return array
    sub getRequestClientRequestUris{
        my( $self ) = @_;
		return $self->{_request_client_request_uris};
    }

    # @param array $request_client_request_uris
    # @return void
    sub setRequestClientRequestUris{
        my ( $self, $request_client_request_uris ) = @_;
		$self->{_request_client_request_uris} = $request_client_request_uris if defined($request_client_request_uris);
		return $self->{_request_client_request_uris};
    }

    # @return string
    sub getRequestApplicationType{
        my( $self ) = @_;
		return $self->{_request_application_type};
    }

    # @param string $request_application_type
    # @return void
    sub setRequestApplicationType{
        my ( $self, $request_application_type ) = @_;
        
        $request_application_type =  $request_application_type ? $request_application_type : 'web';
        
		$self->{_request_application_type} = $request_application_type if defined($request_application_type);
		return $self->{_request_application_type};
    }

    # @return string
    sub getRequestAuthorizationRedirectUri{
        my( $self ) = @_;
        return $self->{_request_authorization_redirect_uri};
    }

    # @param string $request_authorization_redirect_uri
    # @return void
    sub setRequestAuthorizationRedirectUri{
        my ( $self, $request_authorization_redirect_uri ) = @_;
		$self->{_request_authorization_redirect_uri} = $request_authorization_redirect_uri if defined($request_authorization_redirect_uri);
		return $self->{_request_authorization_redirect_uri};
    }

    # @return array
    sub getRequestAcrValues{
        my( $self ) = @_;
		return $self->{_request_acr_values};
    }

    # @param array $request_acr_values
    # @return void
    sub setRequestAcrValues{
        my ( $self, $request_acr_values ) = @_;
		$self->{_request_acr_values} = $request_acr_values if defined($request_acr_values);
		return $self->{_request_acr_values};
    }

    # @return array
    sub getRequestContacts{
        my( $self ) = @_;
		return $self->{_request_contacts};
    }

    # @param array $request_contacts
    # @return void
    sub setRequestContacts{
        my ( $self, $request_contacts ) = @_;
		$self->{_request_contacts} = $request_contacts if defined($request_contacts);
		return $self->{_request_contacts};
    }

    # @return string
    sub getResponseOxdId {
		my( $self ) = @_;
		$self->{_response_oxd_id} = $self->getResponseData()->{oxd_id};
        return $self->{_response_oxd_id};
    }
    
    # @return string
    sub getResponseOpHost {
		my( $self ) = @_;
		$self->{_response_op_host} = $self->getResponseData()->{op_host};
        return $self->{_response_op_host};
    }
    
    # @return string
    sub getResponseClientId {
		my( $self ) = @_;
		$self->{_response_client_id} = $self->getResponseData()->{client_id};
        return $self->{_response_client_id};
    }
    
    # @return string
    sub getResponseClientSecret {
		my( $self ) = @_;
		$self->{_response_client_secret} = $self->getResponseData()->{client_secret};
        return $self->{_response_client_secret};
    }
    
    # @return string
    sub getResponseClientRegistrationAccessToken {
		my( $self ) = @_;
		$self->{_response_client_registration_access_token} = $self->getResponseData()->{client_registration_access_token};
        return $self->{_response_client_registration_access_token};
    }
    
    # @return string
    sub getResponseClientRegistrationClientUri {
		my( $self ) = @_;
		$self->{_response_client_registration_client_uri} = $self->getResponseData()->{client_registration_client_uri};
        return $self->{_response_client_registration_client_uri};
    }
    
    # @return string
    sub getResponseClientIdIssuedAt {
		my( $self ) = @_;
		$self->{_response_client_id_issued_at} = $self->getResponseData()->{client_id_issued_at};
        return $self->{_response_client_id_issued_at};
    }
    
    # @return string
    sub getResponseClientSecretExpiresAt {
		my( $self ) = @_;
		$self->{_response_client_secret_expires_at} = $self->getResponseData()->{client_secret_expires_at};
        return $self->{_response_client_secret_expires_at};
    }

    # @return array
    sub getRequestUiLocales{
        my( $self ) = @_;
		return $self->{_request_ui_locales};
    }

    # @param array $request_ui_locales
    sub setRequestUiLocales{
        my ( $self, $request_ui_locales ) = @_;
		$self->{_request_ui_locales} = $request_ui_locales if defined($request_ui_locales);
		return $self->{_request_ui_locales};
    }

    # @return array
    sub getRequestClaimsLocales{
        my( $self ) = @_;
		return $self->{_request_claims_locales};
    }

    # @param array $request_claims_locales
    sub setRequestClaimsLocales{
        my ( $self, $request_claims_locales ) = @_;
		$self->{_request_claims_locales} = $request_claims_locales if defined($request_claims_locales);
		return $self->{_request_claims_locales};
    }
    
    
    # @return string
    sub getRequestClaimsRedirectUri {
        my( $self ) = @_;
		return $self->{_request_claims_redirect_uri};
    }

    # @param string $request_client_secret
    sub setRequestClaimsRedirectUri {
        my ( $self, $request_client_redirect_uri ) = @_;
		$self->{_request_claims_redirect_uri} = $request_client_redirect_uri if defined($request_client_redirect_uri);
		return $self->{_request_claims_redirect_uri};
    }

    # Protocol command to oxd server
    # @return void
    sub setCommand{
		# my $command = 'setup_client';
        my ( $self, $command ) = @_;
		$self->{_command} = 'setup_client';
		return $self->{_command};
		#return $command;
    }
    
    # Protocol command to oxd to http server
    # @return void
    sub sethttpCommand{
		# my $httpCommand = 'setup-client';
        my ( $self, $httpCommand ) = @_;
		$self->{_httpcommand} = 'setup-client';
		return $self->{_httpcommand};
		#return $httpcommand;
    }
    
    # Method: setParams
    # This method sets the parameters for setup_client command.
    # This module uses `request` method of OxdClient module for sending request to oxd-server
    # 
    # Parameters:
    #
    #	string $authorization_redirect_uri - (Required) Uri to Redirect for Authorization
    #
    #	string $op_host - (Optional) Url that must points to a valid OpenID Connect Provider that supports client registration like Gluu Server.
    #
    #	string $post_logout_redirect_uri - (Optional) Uri to Redirect after Logout
    #
    #	string $application_type - (Optional) Application Type
    #
    #	array $response_types - (Optional) Response Types
    #
    #	array $grant_types - (Optional) Grant Types
    #
    #	array $scope - (Optional) Scope
    #
    #	array $acr_values - (Optional) ACR Values
    #
    #	string $client_name - (Optional) Client Name
    #
    #	string $client_jwks_uri - (Optional) Client JWKS Uri
    #
    #	string $client_token_endpoint_auth_method - (Optional) Client Token Endpoint Auth Method
    #
    #	array $client_request_uris - (Optional) Client Request URIs
    #
    #	array $client_frontchannel_logout_uris - (Optional) Client Front Channel Logout URIs
    #
    #	array $client_sector_identifier_uri - (Optional) Client Sector Identifier URIs
    #
    #	array $contacts - (Optional) Contacts
    #
    #	array $ui_locales - (Optional) UI Locales
    #
    #	array $claims_locales - (Optional) Claims Locales
    #
    #	string $client_id - (Optional) Client ID. If value presents, Ignores all other parameters and Skips new client registration forcing to use existing client. ClientSecret is REQUIRED if this parameter is set
    #
    #	string $client_secret - (Optional) Client Secret. Must be used together with ClientId.
    #
    #	array $claims_redirect_uri - (Optional) Claims Redirect URI.
    #
    # Returns:
    #	void
    #
    # This module uses `getResponseObject` method of OxdClient module for getting response from oxd.
    # 
    # *Example response from getResponseObject:*
    # --- Code
    # { "status": "ok", "data": { "oxd_id": "c73134c8-c4ca-4bab-9baa-2e0ca20cc433", "op_host": "https://idp-hostname", "client_id": "@!4116.DF7C.62D4.D0CF!0001!D420.A5E5!0008!616C.398A.1380.1F45", "client_secret": "f996649f-b027-4537-abe5-71b7cb71ebae", "client_registration_access_token": "67e957b8-823e-412d-8e89-616c45b2db62", "client_registration_client_uri": "https://idp-hostname/oxauth/restv1/register?client_id=@!4116.DF7C.62D4.D0CF!0001!D420.A5E5!0008!616C.398A.1380.1F45", "client_id_issued_at": 1513857463, "client_secret_expires_at": 1513943863 } }
    # ---
    #
    sub setParams{
		
		my ( $self, $params ) = @_;
		#use Data::Dumper;
		my $paramsArray = {
            "authorization_redirect_uri" => $self->getRequestAuthorizationRedirectUri(),
            "op_host" => $self->getRequestOpHost(),
            "post_logout_redirect_uri" => $self->getRequestPostLogoutRedirectUri(),
            "application_type" => $self->getRequestApplicationType(),
            "response_types"=> $self->getRequestResponseTypes(),
            "grant_types" => $self->getRequestGrantTypes(),
            "scope" => $self->getRequestScope(),
            "acr_values" => $self->getRequestAcrValues(),
            "client_name"=> $self->getRequestClientName(),
            "client_jwks_uri" => $self->getRequestClientJwksUri(),
            "client_token_endpoint_auth_method" => $self->getRequestClientTokenEndpointAuthMethod(),
            "client_request_uris" => $self->getRequestClientRequestUris(),
            "client_frontchannel_logout_uris"=> $self->getRequestClientLogoutUris(),
            "client_sector_identifier_uri"=> $self->getRequestClientSectorIdentifierUri(),
            "contacts" => $self->getRequestContacts(),
            "ui_locales" => $self->getRequestUiLocales(),
            "claims_locales" => $self->getRequestClaimsLocales(),
            "client_id"=> $self->getRequestClientId(),
            "client_secret"=> $self->getRequestClientSecret(),
            "claims_redirect_uri"=> $self->getRequestClaimsRedirectUri(),
            "oxd_rp_programming_language" => 'perl'
        };
       
		$self->{_params} = $paramsArray;
		return $self->{_params};
        #print Dumper( $params );
        #return $paramsArray;
    }
    
1;		# this 1; is neccessary for our class to work
