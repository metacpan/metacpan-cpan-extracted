#!/usr/bin/perl
# GetUserInfo.pm, a number as an object

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
# @version	3.1.3
# @author	Sobhan Panda
# @author_email	sobhan@centroxy.com
# @copyright	Copyright (c) 2018, Gluu inc federation (https://gluu.org/)
# @license	http://opensource.org/licenses/MIT	MIT License
# @link		https://gluu.org/
# @since	Version 3.1.3
# @filesource
#/

package GetUserInfo;	# This is the &quot;Class&quot;
    use OxdPackages::OxdClient;
	use base qw(OxdClient Class::Accessor);
	use strict;
	our @ISA = qw(OxdClient);    # inherits from OxdClient
	
	use vars qw($VERSION);
    $VERSION = '0.01';
	
	sub new {
		my $class = shift;
		my $self = {
			# @var string $request_oxd_id                            This parameter you must get after registration site in gluu-server
			_request_oxd_id => shift,
			
			# @var string $request_access_token			This parameter you must get after using get_token_code class
			_request_access_token => shift,
			
			# @var array $request_protection_access_token		To protect the command with access token
			_request_protection_access_token => shift,
			
			# Response parameter from oxd-server
			# Showing logedin user information
			# @var array $response_claims
			_response_claims => shift,
        };
		# Print all the values just for clarification.
		#print "setRequestOxdId is $self->{_request_oxd_id}<br>";
		#print "setRequestCode is $self->{_request_code}<br>";
		#print "setRequestState is $self->{_request_state}<br>";
		bless $self, $class;
		
		return $self;
	} 
	
	
   
    # @return array
    
    sub getResponseClaims
    {   
		my( $self ) = @_;
		$self->{_response_claims} = $self->getResponseData()->{claims};
		return $self->{_response_claims};
    }

    
    # @return string
    
    sub getRequestAccessToken
    {   
		my( $self ) = @_;
		return $self->{_request_access_token};
    }

    
    # @param string $request_access_token
    # @return void
    
    sub setRequestAccessToken
    {
		my ( $self, $request_access_token ) = @_;
		$self->{_request_access_token} = $request_access_token if defined($request_access_token);
		return $self->{_request_access_token};
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
	
	
    
    # Protocol command to oxd server
    # @return void
    
    sub setCommand
    {
        my ( $self, $command ) = @_;
		$self->{_command} = 'get_user_info';
		return $self->{_command};
    }
    
    # Protocol command to oXD to http server
    # @return void
    
    sub sethttpCommand
    {
        my ( $self, $httpCommand ) = @_;
		$self->{_httpcommand} = 'get-user-info';
		return $self->{_httpcommand};
    }
	
    # Method: setParams
    # This method sets the parameters for get_user_info command.
    # This module uses `request` method of OxdClient module for sending request to oxd-server
    # 
    # Parameters:
    #
    #	string $oxd_id - (Required) oxd Id from Client registration
    #
    #	string $access_token - (Required) access Token from get_tokens_by_code or get_access_token_by_refresh_token command
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
    # { "status": "ok", "data": { "claims": { "sub": ["SGUMcFlAj3QlkOQVgwYpSozbjvynk4B2VNpr-mDnuVw"], "name": ["Jane Doe"], "given_name": ["Jane"], "family_name": ["Doe"], "preferred_username": ["j.doe"], "email": ["janedoe@example.com"], "picture": null } } }
    # ---
    #
    sub setParams
    {   
		my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "access_token" => $self->getRequestAccessToken(),
            "protection_access_token"=> $self->getRequestProtectionAccessToken()
        };
        $self->{_params} = $paramsArray;
		return $self->{_params};
    }
	 
	
1;		# this 1; is neccessary for our class to work
