#!/usr/bin/perl
# IntrospectAccessToken.pm, a number as an object


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
 # @version		3.1.3
 # @author		Sobhan Panda
 # @author_email	sobhan@centroxy.com
 # @copyright		Copyright (c) 2018, Gluu inc federation (https://gluu.org/)
 # @license		http://opensource.org/licenses/MIT	MIT License
 # @link		https://gluu.org/
 # @since		Version 3.1.3
 # @filesource
 #
 #/

package IntrospectAccessToken;	# This is the &quot;Class&quot;
    use OxdPackages::OxdClient;
	use base qw(OxdClient Class::Accessor);
	use strict;
	our @ISA = qw(OxdClient);    # inherits from OxdClient
	
	use vars qw($VERSION);
    $VERSION = '0.01';
	
	sub new {
		my $class = shift;
		my $self = {
			
			# @var string $request_oxd_id                           This parameter you must get after registration site in gluu-server
			 
			_request_oxd_id => shift,
			
			# @var string $request_access_token                    This parameter you must get after using get_token_code or get_client_token class
			 
			_request_access_token => shift,
			
			
			
			# Response parameter from oxd-server
			# It shows whether the token is active or not
			#
			# @var string $response_active
			 
			_response_active => shift,
			
			# Response parameter from oxd-server
			# Shows the registered client_id to whom the token is assigned
			#
			# @var string $response_client_id
			 
			_response_client_id => shift,
			
			
			# Response parameter from oxd-server
			# Shows the user name to whom the token is assigned
			#
			# @var string $response_user_name
			 
			_response_user_name => shift,

		
		};
		# Print all the values just for clarification.
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
    # @return	void
    
    sub setRequestOxdId
    {  
		my ( $self, $request_oxd_id ) = @_;
		$self->{_request_oxd_id} = $request_oxd_id if defined($request_oxd_id);
		return $self->{_request_oxd_id};
    }

    
    # @return string
    
    sub getRequestAccessToken
    {   
		my( $self ) = @_;
		return $self->{_request_access_token};
	}

    
    # @param string $request_access_token
    # @return	void
    
    sub setRequestAccessToken
    {  
		my ( $self, $request_access_token ) = @_;
		$self->{_request_access_token} = $request_access_token if defined($request_access_token);
		return $self->{_request_access_token};
	}

    
    # @return string
    
    sub getResponseActive
    {   
		my( $self ) = @_;
		$self->{_response_active} = $self->getResponseData()->{active};
		return $self->{_response_active};
	}

    
    # @return string
    
    sub getResponseClientId
    {  
		my( $self ) = @_;
		$self->{_response_client_id} = $self->getResponseData()->{client_id};
		return $self->{_response_client_id};
	}


    # @return string
    
    sub getResponseUserName
    {
		my( $self ) = @_;
		$self->{_response_user_name} = $self->getResponseData()->{user_name};
		return $self->{_response_user_name};
	}
    
    
    # Protocol command for oxd server
    # @return void
    
    sub setCommand
    {
		my ( $self, $command ) = @_;
		$self->{_command} = 'introspect_access_token';
		return $self->{_command};
	}
	
    # Protocol command for oxd-https-extension
    # @return void
    
    sub sethttpCommand
    {
		my ( $self, $httpCommand ) = @_;
		$self->{_httpcommand} = 'introspect-access-token';
		return $self->{_httpcommand};
	}
    
    # Method: setParams
    # This method sets the parameters for introspect_access_token command.
    # This module uses `request` method of OxdClient module for sending request to oxd-server
    # 
    # Parameters:
    #
    #	string $oxd_id - (Required) oxd Id from Client registration
    #
    #	string $access_token - (Required) Acccess Token
    #
    # Returns:
    #	void
    #
    # This module uses `getResponseObject` method of OxdClient module for getting response from oxd.
    # 
    # *Example response from getResponseObject:*
    # --- Code
    # { "status": "ok", "data": { "active": true, "scopes": ["openid"], "client_id": "@!DEEA.B5F2.074F.4295!0001!5BE0.4886!0008!C314.0AC7.C908.77D0", "username": null, "token_type": "bearer", "exp": 1517391098, "iat": 1517390798, "sub": null, "aud": "@!DEEA.B5F2.074F.4295!0001!5BE0.4886!0008!C314.0AC7.C908.77D0", "iss": "https://idp.gluu.org", "jti": null, "acr_values": null } }
    # ---
    #
    sub setParams
    {  
	my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "access_token" => $self->getRequestAccessToken()
        };
        
        $self->{_params} = $paramsArray;
		return $self->{_params};
    }
	 
	
1;		# this 1; is neccessary for our class to work
