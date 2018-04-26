#!/usr/bin/perl
# UpdateRegistration.pm, a number as an object

 ##
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
 # @package		Gluu-oxd-library
 # @version     	3.1.3
 # @author		Ourdesignz, Sobhan Panda
 # @author_email	inderpal6785@gmail.com, sobhan@centroxy.com
 # @copyright		Copyright (c) 2018, Gluu inc federation (https://gluu.org/)
 # @license		http://opensource.org/licenses/MIT	MIT License
 # @link		https://gluu.org/
 # @since		Version 3.1.3
 # @filesource
 #/


use JSON::PP;

package UpdateRegistration;	
    
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
			# @var string $request_oxd_id                          This parameter you must get after registration site in gluu-server
			_request_oxd_id => shift,
			
			# @var string $request_authorization_redirect_uri      Site authorization redirect uri
			_request_authorization_redirect_uri => shift,
			
			# @var string $request_post_logout_redirect_uri             Site logout redirect uri
			_request_post_logout_redirect_uri => shift,
			
			# @var string $request_client_name                     OpenID provider client name
			_request_client_name => shift,
			
			# @var string $request_client_secret_expires_at        OpenID provider client secret expires at
			_request_client_secret_expires_at => shift,
			
			# @var array $request_acr_values                       Gluu login acr type, can be basic, duo, u2f, gplus and etc.
			_request_acr_values => shift,
			
			# @var string $request_client_jwks_uri
			_request_client_jwks_uri => shift,
			
			# @var string $request_client_token_endpoint_auth_method
			_request_client_token_endpoint_auth_method => shift,
			
			# @var array $request_client_request_uris
			_request_client_request_uris => shift,
			
			# @var array $request_client_logout_uris
			_request_client_frontchannel_logout_uris => shift,
			
			# @var array $request_contacts
			_request_contacts => shift,
			
			# @var array $request_scope                            For getting needed scopes from gluu-server
			_request_scope => shift,
			
			# @var array $request_grant_types                     OpenID Token Request type
			_request_grant_types => shift,
			
			# @var array $request_ui_locales
			_request_ui_locales => shift,
			
			# @var array $request_claims_locales
			_request_claims_locales => shift,
			
			# @var array $request_grant_types                     OpenID Token Request type
			_request_client_sector_identifier_uri => shift,
			
			# @var array $request_response_types                   OpenID Authentication response types
			_request_response_types => shift,
			
			# @var array $request_protection_access_token          To protect the command with access token
			_request_protection_access_token => shift,
			
			# Response parameter from oXD-server
			# It is basic parameter for other protocols
			# @var string $response_oxd_id
			_response_oxd_id => shift,
		
		};
		
		bless $self, $class;
		return $self;
	}  
	
    
    # @return array
    sub getRequestClientSectorIdentifierUri
    {
        my( $self ) = @_;
		return $self->{_request_client_sector_identifier_uri};
    }

    # @param array $request_client_sector_identifier_uri
    sub setRequestClientSectorIdentifierUri
    {  
		my ( $self, $request_client_sector_identifier_uri ) = @_;
		$self->{_request_client_sector_identifier_uri} = $request_client_sector_identifier_uri if defined($request_client_sector_identifier_uri);
		return $self->{_request_client_sector_identifier_uri};
	}

    # @return array
    sub getRequestClaimsLocales
    {  
		my( $self ) = @_;
		return $self->{_request_claims_locales};
    }

    # @param array $request_claims_locales
    sub setRequestClaimsLocales
    {   
		my ( $self, $request_claims_locales ) = @_;
		$self->{_request_claims_locales} = $request_claims_locales if defined($request_claims_locales);
		return $self->{_request_claims_locales};
	}

    # @return array
    sub getRequestUiLocales
    {   
		my( $self ) = @_;
		return $self->{_request_ui_locales};
    }

    # @param array $request_ui_locales
    sub setRequestUiLocales
    {  
		my ( $self, $request_ui_locales ) = @_;
		$self->{_request_ui_locales} = $request_ui_locales if defined($request_ui_locales);
		return $self->{_request_ui_locales};
	}


    # @return array
    sub getRequestClientLogoutUris
    {
        my( $self ) = @_;
	return $self->{_request_client_frontchannel_logout_uris};
    }

    # @param array $request_client_logout_uris
    # @return void
    sub setRequestClientLogoutUris
    {
        my ( $self, $request_client_frontchannel_logout_uris ) = @_;
	$self->{_request_client_frontchannel_logout_uris} = $request_client_frontchannel_logout_uris if defined($request_client_frontchannel_logout_uris);
	return $self->{_request_client_frontchannel_logout_uris};
    }

    
    # @return array
    sub getRequestResponseTypes
    {   
		my( $self ) = @_;
		return $self->{_request_response_types};
    }

    
    # @param array $request_response_types
    # @return void
    sub setRequestResponseTypes
    {   
		my ( $self, $request_response_types ) = @_;
		$self->{_request_response_types} = $request_response_types if defined($request_response_types);
		return $self->{_request_response_types};
	}
	

    # @return array
    sub getRequestProtectionAccessToken
    {   
		my( $self ) = @_;
		return $self->{_request_protection_access_token};
    }

    
    # @param array $request_request_protection_access_token
    # @return void
    sub setRequestProtectionAccessToken
    {   
		my ( $self, $request_protection_access_token ) = @_;
		$self->{_request_protection_access_token} = $request_protection_access_token if defined($request_protection_access_token);
		return $self->{_request_protection_access_token};
	}
    
    # @return array
    sub getRequestGrantTypes
    {   
		my( $self ) = @_;
		return $self->{_request_grant_types};
    }

    
    # @param array $request_grant_types
    # @return void
    sub setRequestGrantTypes
    {
        my ( $self, $request_grant_types ) = @_;
		$self->{_request_grant_types} = $request_grant_types if defined($request_grant_types);
		return $self->{_request_grant_types};
	}

    
    # @return array
    sub getRequestScope
    {   
		my( $self ) = @_;
		return $self->{_request_scope};
    }

    
    # @param array $request_scope
    # @return void
    sub setRequestScope
    {   
		my ( $self, $request_scope ) = @_;
		$self->{_request_scope} = $request_scope if defined($request_scope);
		return $self->{_request_scope};
	}

    
    # @return string
    sub getRequestPostLogoutRedirectUri
    {   
		my( $self ) = @_;
		return $self->{_request_post_logout_redirect_uri};
    }

    
    # @param string $request_post_logout_redirect_uri
    # @return void
    sub setRequestPostLogoutRedirectUri
    {   
		my ( $self, $request_post_logout_redirect_uri ) = @_;
		$self->{_request_post_logout_redirect_uri} = $request_post_logout_redirect_uri if defined($request_post_logout_redirect_uri);
		return $self->{_request_post_logout_redirect_uri};
	}

    
    # @return string
    sub getRequestClientJwksUri
    {
		my( $self ) = @_;
		return $self->{_request_client_jwks_uri};
	}

    
    # @param string $request_client_jwks_uri
    # @return void
    
    sub setRequestClientJwksUri
    {   
		my ( $self, $request_client_jwks_uri ) = @_;
		$self->{_request_client_jwks_uri} = $request_client_jwks_uri if defined($request_client_jwks_uri);
		return $self->{_request_client_jwks_uri};
	}

    
    # @return string
    sub getRequestClientTokenEndpointAuthMethod
    {  
		my( $self ) = @_;
		return $self->{_request_client_token_endpoint_auth_method};
    }

    
    # @param string $request_client_token_endpoint_auth_method
    # @return void
    sub setRequestClientTokenEndpointAuthMethod
    {   
		my ( $self, $request_client_token_endpoint_auth_method ) = @_;
		$self->{_request_client_token_endpoint_auth_method} = $request_client_token_endpoint_auth_method if defined($request_client_token_endpoint_auth_method);
		return $self->{_request_client_token_endpoint_auth_method};
	}

    
    # @return array
    sub getRequestClientRequestUris
    {
		my( $self ) = @_;
		return $self->{_request_client_request_uris};
	}

    
    # @param array $request_client_request_uris
    # @return void
    
    sub setRequestClientRequestUris
    {
		my ( $self, $request_client_request_uris ) = @_;
		$self->{_request_client_request_uris} = $request_client_request_uris if defined($request_client_request_uris);
		return $self->{_request_client_request_uris};
	}

    
    # @return string
    sub getRequestAuthorizationRedirectUri
    {   
		my( $self ) = @_;
		return $self->{_request_authorization_redirect_uri};
    }

    
    # @param string $request_authorization_redirect_uri
    # @return void
    sub setRequestAuthorizationRedirectUri
    {
        my ( $self, $request_authorization_redirect_uri ) = @_;
		$self->{_request_authorization_redirect_uri} = $request_authorization_redirect_uri if defined($request_authorization_redirect_uri);
		return $self->{_request_authorization_redirect_uri};
	}

    
    # @return array
    
    sub getRequestAcrValues
    {
        my( $self ) = @_;
		return $self->{_request_acr_values};
    }

    
    # @param array $request_acr_values
    # @return void
    
    sub setRequestAcrValues
    {
		my ( $self, $request_acr_values ) = @_;
		$request_acr_values =  $request_acr_values ? $request_acr_values : 'basic';
		
		$self->{_request_acr_values} = $request_acr_values if defined($request_acr_values);
		return $self->{_request_acr_values};
	}

    
    # @return array
    
    sub getRequestContacts
    {
        my( $self ) = @_;
		return $self->{_request_contacts};
	}

    
    # @param array $request_contacts
    # @return void
    
    sub setRequestContacts
    {
		my ( $self, $request_contacts ) = @_;
		$self->{_request_contacts} = $request_contacts if defined($request_contacts);
		return $self->{_request_contacts};
	}

    
    # @return string
    
    sub getResponseOxdId
    {
		my( $self ) = @_;
		$self->{_response_oxd_id} = $self->getResponseData()->{oxd_id};
		
		return $self->{_response_oxd_id};
	}


    
    # @param string $request_client_name
    
    sub setRequestClientName
    {
		my ( $self, $request_client_name ) = @_;
		$self->{_request_client_name} = $request_client_name if defined($request_client_name);
		return $self->{_request_client_name};
	}
	
	
    # @return string
    
    sub getRequestClientName
    {
		my( $self ) = @_;
		return $self->{_request_client_name};
	}


    # @param string $request_client_secret_expires_at
    
    sub setRequestClientSecretExpiresAt
    {
		my ( $self, $request_client_secret_expires_at ) = @_;
		$self->{_request_client_secret_expires_at} = $request_client_secret_expires_at if defined($request_client_secret_expires_at);
		return $self->{_request_client_secret_expires_at};
	}
	
	
    # @return string
    
    sub getRequestClientSecretExpiresAt
    {
		my( $self ) = @_;
		return $self->{_request_client_secret_expires_at};
	}
    
    
    
    # @param string $response_oxd_id
    # @return void
    
    sub setResponseOxdId
    {
		my ( $self, $response_oxd_id ) = @_;
		$self->{_response_oxd_id} = $response_oxd_id if defined($response_oxd_id);
		return $self->{_response_oxd_id};
	}
    
    # @return string
    
    sub getRequestOxdId
    { 
		my( $self ) = @_;
		return $self->{_request_oxd_id};
		
    }

    
    # @param string $request_oxd_id
    # @return void
    
    sub setRequestOxdId
    {
		my ( $self, $request_oxd_id ) = @_;
		$self->{_request_oxd_id} = $request_oxd_id if defined($request_oxd_id);
		return $self->{_request_oxd_id};
	}

    
    # Protocol command to oXD server
    # @return void
    
    sub setCommand
    {
		my ( $self, $command ) = @_;
		$self->{_command} = 'update_site';
		return $self->{_command};
	}
	
    # Protocol command to oXD to http server
    # @return void
    
    sub sethttpCommand
    {
		my ( $self, $httpCommand ) = @_;
		$self->{_httpcommand} = 'update-site';
		return $self->{_httpcommand};
	}
    
    # Method: setParams
    # This method sets the parameters for update_site command.
    # This module uses `request` method of OxdClient module for sending request to oxd-server
    # 
    # Parameters:
    #
    #	string $oxd_id - (Required) oxd Id from Client registration
    #
    #	string $authorization_redirect_uri - (Required) Uri to Redirect for Authorization
    #
    #	string $post_logout_redirect_uri - (Optional) Uri to Redirect after Logout
    #
    #	array $client_frontchannel_logout_uris - (Optional) Client Front Channel Logout URIs
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
    #	numeric $client_secret_expires_at - (Optional) Used to extend client lifetime (milliseconds since 1970)
    #
    #	string $client_jwks_uri - (Optional) Client JWKS Uri
    #
    #	string $client_token_endpoint_auth_method - (Optional) Client Token Endpoint Auth Method
    #
    #	array $client_request_uris - (Optional) Client Request URIs
    #
    #	array $client_sector_identifier_uri - (Optional) Client Sector Identifier URIs
    #
    #	array $contacts - (Optional) Contacts
    #
    #	array $ui_locales - (Optional) UI Locales
    #
    #	array $claims_locales - (Optional) Claims Locales
    #
    #	string $protection_access_token - Protection Acccess Token. OPTIONAL for `oxd-server` but REQUIRED for `oxd-https-extension`
    #
    # Returns:
    #	void
    #
    # This module uses `getResponseObject` method of OxdClient module for getting response from oxd.
    # 
    # *Example response from getResponseObject:*
    # --- Code
    # { "status": "ok" }
    # ---
    #
    sub setParams
    {
        my ( $self, $params ) = @_;
		#use Data::Dumper;
		my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "authorization_redirect_uri" => $self->getRequestAuthorizationRedirectUri(),
            "post_logout_redirect_uri" => $self->getRequestPostLogoutRedirectUri(),
            "client_frontchannel_logout_uris"=> $self->getRequestClientLogoutUris(),
            "response_types"=> $self->getRequestResponseTypes(),
            "grant_types" => $self->getRequestGrantTypes(),
            "scope" => $self->getRequestScope(),
            "acr_values" => $self->getRequestAcrValues(),
            "client_name" => $self->getRequestClientName(),
            "client_secret_expires_at" => $self->getRequestClientSecretExpiresAt(),
            "client_jwks_uri" => $self->getRequestClientJwksUri(),
            "client_token_endpoint_auth_method" => $self->getRequestClientTokenEndpointAuthMethod(),
            "client_request_uris" => $self->getRequestClientRequestUris(),
            "client_sector_identifier_uri" => $self->getRequestClientSectorIdentifierUri(),
            "contacts" => $self->getRequestContacts(),
            "ui_locales"=> $self->getRequestUiLocales(),
            "claims_locales"=> $self->getRequestClaimsLocales(),
            "protection_access_token"=> $self->getRequestProtectionAccessToken()
        };
       
		$self->{_params} = $paramsArray;
		return $self->{_params};
        #print Dumper( $params );
        #return $paramsArray;
        #Clientsecretexpiresat:3080736637943;
    }	

1;		# this 1; is neccessary for our class to work
