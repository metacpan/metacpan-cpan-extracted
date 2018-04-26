#!/usr/bin/perl
# GetAccessTokenByRefreshToken.pm, a number as an object


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

package GetAccessTokenByRefreshToken;	# This is the &quot;Class&quot;
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
			
			# @var string $request_refresh_token                    This parameter you must get after using get_token_code class
			 
			_request_refresh_token => shift,
			
			# @var string $request_scope                            
			 
			_request_scopes => shift,
			
			# @var string $request_protection_access_token		To protect the command with access token
			_request_protection_access_token => shift,
			
			
			# Response parameter from oxd-server
			# It need to using for get_user_info and logout classes
			#
			# @var string $response_access_token
			 
			_response_access_token => shift,
			
			# Response parameter from oxd-server
			# Showing user expires time
			#
			# @var string $response_expires_in
			 
			_response_expires_in => shift,
			
			
			# Response parameter from oxd-server
			# Showing user claimses and data
			#
			# @var string $response_refresh_token
			 
			_response_refresh_token => shift,

		
		};
		# Print all the values just for clarification.
		bless $self, $class;
		
		return $self;
	} 
	
	
    # @return string
   
    sub getRequestScopes
    {  
		my( $self ) = @_;
		return $self->{_request_scopes};
    }

    
    # @param string $request_scopes
    # @return	void
    
    sub setRequestScopes
    {   
		my ( $self, $request_scopes ) = @_;
		$self->{_request_scopes} = $request_scopes if defined($request_scopes);
		return $self->{_request_scopes};
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
    
    sub getRequestRefreshToken
    {   
		my( $self ) = @_;
		return $self->{_request_refresh_token};
	}

    
    # @param string $request_refresh_token
    # @return	void
    
    sub setRequestRefreshToken
    {  
		my ( $self, $request_refresh_token ) = @_;
		$self->{_request_refresh_token} = $request_refresh_token if defined($request_refresh_token);
		return $self->{_request_refresh_token};
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
    
    sub getResponseAccessToken
    {   
		my( $self ) = @_;
		$self->{_response_access_token} = $self->getResponseData()->{access_token};
		return $self->{_response_access_token};
	}

    
    # @return string
    
    sub getResponseExpiresIn
    {  
		my( $self ) = @_;
		$self->{_response_expires_in} = $self->getResponseData()->{expires_in};
		return $self->{_response_expires_in};
	}


    # @return string
    
    sub getResponseRefreshToken
    {
		my( $self ) = @_;
		$self->{_response_refresh_token} = $self->getResponseData()->{refresh_token};
		return $self->{_response_refresh_token};
	}
    
    
    # Protocol command to oxd server
    # @return void
    
    sub setCommand
    {
		my ( $self, $command ) = @_;
		$self->{_command} = 'get_access_token_by_refresh_token';
		return $self->{_command};
	}
	
    # Protocol command to oXD to http server
    # @return void
    
    sub sethttpCommand
    {
		my ( $self, $httpCommand ) = @_;
		$self->{_httpcommand} = 'get-access-token-by-refresh-token';
		return $self->{_httpcommand};
	}
    
    # Method: setParams
    # This method sets the parameters for get_access_token_by_refresh_token command.
    # This module uses `request` method of OxdClient module for sending request to oxd.
    #
    # Parameters:
    #
    #	string $oxd_id - (Required) oxd Id from Client registration
    #
    #	string $refresh_token - (Required) Refresh Token from get_tokens_by_code command
    #
    #	string $scope - (Optional) Scope
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
    # { "status": "ok", "data": { "access_token": "fb5b52be-fd99-46b7-b87a-6167f86ae4bb", "expires_in": "299", "refresh_token": "49850248-ee70-4d21-85b2-949476c26e1b" } }
    # ---
    #
    sub setParams
    {  
	my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "refresh_token" => $self->getRequestRefreshToken(),
            "scope" => $self->getRequestScopes(),
            "protection_access_token"=> $self->getRequestProtectionAccessToken()
        };
        #use Data::Dumper;
        #print Dumper( $paramsArray );
        $self->{_params} = $paramsArray;
		return $self->{_params};
    }
	 
	
1;		# this 1; is neccessary for our class to work
