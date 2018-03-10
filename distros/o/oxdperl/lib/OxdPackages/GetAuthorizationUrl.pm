#!/usr/bin/perl
# GetAuthorizationUrl.pm, a number as an object

##########################################
# Oxd client update site registration class
#
# Class is connecting to oXD-server via socket, and updating registered site data in gluu server.
#
# @package	Gluu-oxd-library
# @subpackage	Libraries
# @version	3.1.2
# @author	Ourdesignz, Sobhan Panda
# @author_email	inderpal6785@gmail.com, sobhan@centroxy.com
# @see	        OxdClientSocket
# @see	        OxdClient
# @see	        OxdConfig
#######################################

use JSON::PP;

package GetAuthorizationUrl;	
	use OxdPackages::OxdClient;
	use base qw(OxdClient Class::Accessor);
	#use base 'OxdClient';
	use strict;
	our @ISA = qw(OxdClient);    # inherits from OxdClient
	
	use vars qw($VERSION);
    $VERSION = '0.01';
	
	sub new {
		my $class = shift;
		
		my $self = {
			
			# @var string $request_oxd_id                          This parameter you must get after registration site in gluu-server
			
			_request_oxd_id => shift,
			
			# @var array $request_scope                            May be skipped (by default takes scopes that was registered during register_site command)
			
			_request_scope => shift,
			
			# @var array $request_acr_values                        It is gluu-server login parameter type
			
			_request_acr_values => shift,
			
			# @var string $request_prompt                           Skipped if no value specified or missed. prompt=login is required if you want to force alter current user session (in case user is already logged in from site1 and site2 construsts authorization request and want to force alter current user session)
			
			_request_prompt => shift,
			
			# @var string $request_prompt                           Hosted domain google OP parameter https://developers.google.com/identity/protocols/OpenIDConnect#hd-param
			
			_request_hd => shift,
			
			_request_custom_params => shift,
			
			# @var string $request_protection_access_token		To protect the command with access token
			_request_protection_access_token => shift,

			
			# It is authorization url to gluu server.
			# After getting this parameter go to that url and you can login to gluu server, and get response about your users
			# @var string $response_authorization_url
			
			_response_authorization_url => shift
		
		};
		
		bless $self, $class;
		return $self;
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
		$self->{_request_acr_values} = $request_acr_values if defined($request_acr_values);
		return $self->{_request_acr_values};
	}

    
    # @return array
    
    sub getRequestScope
    {
        my( $self ) = @_;
        return $self->{_request_scope};
    }

    
    # @param array $request_scope
    
    sub setRequestScope
    {
		my ( $self, $request_scope ) = @_;
		$self->{_request_scope} = $request_scope if defined($request_scope);
		return $self->{_request_scope};
	}

    
    # @return string
    
    sub getRequestPrompt
    {
		my( $self ) = @_;
        return $self->{_request_prompt};
    }

    
    # @param string $request_prompt
    
    sub setRequestPrompt
    {
		my ( $self, $request_prompt ) = @_;
		$self->{_request_prompt} = $request_prompt if defined($request_prompt);
		return $self->{_request_prompt};
	}
	
    
    
    # @return array
    sub getRequestCustomParams
    {
	    my( $self ) = @_;
	    return $self->{_request_custom_params};
    }
    
    sub setRequestCustomParams
    {
	    my ( $self, $request_custom_params ) = @_;
	    $self->{_request_custom_params} = $request_custom_params if defined($request_custom_params);
	    return $self->{_request_custom_params};
    }
    
    
    # @return string
    
    sub getRequestHd
    {   
		my( $self ) = @_;
        return $self->{_request_hd};
    }

    
    # @param string $request_hd
    
    sub setRequestHd
    {   
		my ( $self, $request_hd ) = @_;
		$self->{_request_hd} = $request_hd if defined($request_hd);
		return $self->{_request_hd};
	}

    # @return array
    sub getRequestProtectionAccessToken
    {   
		my( $self ) = @_;
		return $self->{_request_protection_access_token};
    }

    
    # @param array $request_protection_access_token
    # @return void
    sub setRequestProtectionAccessToken
    {   
		my ( $self, $request_protection_access_token ) = @_;
		$self->{_request_protection_access_token} = $request_protection_access_token if defined($request_protection_access_token);
		return $self->{_request_protection_access_token};
	}
    
    # @return string
    
    sub getResponseAuthorizationUrl
    {
		my( $self ) = @_;
		$self->{_response_authorization_url} = $self->getResponseData()->{authorization_url};
        return $self->{_response_authorization_url};
    }
    
    # Protocol command to oxd server
    # @return void
    
    sub setCommand
    {
        my ( $self, $request_hd ) = @_;
		$self->{_command} = 'get_authorization_url';
		return $self->{_command};
    }
    
    # Protocol command to oXD to http server
    # @return void
    
    sub sethttpCommand
    {
        my ( $self, $request_hd ) = @_;
		$self->{_httpcommand} = 'get-authorization-url';
		return $self->{_httpcommand};
    }
    
    # Method: setParams
    # This method sets the parameters for get_authorization_url command.
    # This module uses `request` method of OxdClient module for sending request to oxd-server
    # 
    # Parameters:
    #
    #	string $oxd_id - (Required) oxd Id from Client registration
    #
    #	array $scope - (Optional) Scope
    #
    #	array $acr_values - (Optional) ACR Values
    #
    #	string $prompt - (Optional) Prompt. If value not set, this field is skipped. prompt=login is REQUIRED if you want to force alter current user session. In case user is already logged in from SITE1 and SITE2 construsts authorization request and want to force alter current user session.
    #
    #	dict $custom_parameters - (Optional) ACR Values
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
    # { "status": "ok", "data": { "authorization_url": "https://idp-hostname/oxauth/restv1/authorize?response_type=code&client_id=@!4116.DF7C.62D4.D0CF!0001!D420.A5E5!0008!6156.5BD4.5F9B.D172&redirect_uri=https://client.example.com:44383/Home/GetUserInfo&scope=openid+profile+email+uma_protection+uma_authorization&state=cim3uintftqoqckqhgd1vbs6iv&nonce=4pn3vgisdg4em0ups2ud79iig5&custom_response_headers=%5B%7B%22param1%22%3A%22value1%22%7D%2C%7B%22param2%22%3A%22value2%22%7D%5D" } }
    # ---
    sub setParams
    {
		my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "scope" => $self->getRequestScope(),
            "acr_values" => $self->getRequestAcrValues(),
            "prompt" => $self->getRequestPrompt(),
            "custom_parameters" => $self->getRequestCustomParams(),
            "protection_access_token"=> $self->getRequestProtectionAccessToken()
        };
        $self->{_params} = $paramsArray;
		return $self->{_params};
    }

1;		# this 1; is neccessary for our class to work
