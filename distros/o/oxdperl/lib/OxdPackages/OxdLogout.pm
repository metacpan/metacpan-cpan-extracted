#!/usr/bin/perl
# OxdLogout.pm, a number as an object

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


package OxdLogout;	# This is the &quot;Class&quot;
    use vars qw($VERSION);
    $VERSION = '0.01';
    
    use OxdPackages::OxdClient;
	use base qw(OxdClient Class::Accessor);
	use strict;
	our @ISA = qw(OxdClient);    # inherits from OxdClient
	
	sub new {
		my $class = shift;
		my $self = {
			
			# @var string $request_oxd_id                             Need to get after registration site in gluu-server
			_request_oxd_id => shift,
			
			# @var string $request_id_token                           Need to get after registration site in gluu-server
			_request_id_token => shift,
			
			# @var string $request_post_logout_redirect_uri           Need to get after registration site in gluu-server
			_request_post_logout_redirect_uri => shift,
			
			# @var string $request_session_state                      Need to get after registration site in gluu-server
			_request_session_state => shift,
			
			# @var string $request_state                              Need to get after registration site in gluu-server
			_request_state => shift,
			
			# @var array $request_protection_access_token		To protect the command with access token
			_request_protection_access_token => shift,
			
			
			# Response parameter from oxd-server
			# Doing logout user from all sites
			# @var string $response_claims
			_response_html => shift,
        };
		# Print all the values just for clarification.
		bless $self, $class;
		
		return $self;
	} 
	
	# @return string
    sub getRequestState
    {
        my( $self ) = @_;
		return $self->{_request_state};
    }

    
    # @param string $request_state
    # @return	void
    sub setRequestState
    {
        my ( $self, $request_state ) = @_;
		$self->{_request_state} = $request_state if defined($request_state);
		return $self->{_request_access_token};
	}

    
    # @return string
    sub getRequestSessionState
    {   
		my( $self ) = @_;
		return $self->{_request_session_state};
    }

    
    # @param string $request_session_state
    # @return	void
    sub setRequestSessionState
    {  
		my ( $self, $request_session_state ) = @_;
		$self->{_request_session_state} = $request_session_state if defined($request_session_state);
		return $self->{_request_session_state};
	}

    # @param string $request_post_logout_redirect_uri
    # @return	void
    sub setRequestPostLogoutRedirectUri
    {
        my ( $self, $request_post_logout_redirect_uri ) = @_;
		$self->{_request_post_logout_redirect_uri} = $request_post_logout_redirect_uri if defined($request_post_logout_redirect_uri);
		return $self->{_request_post_logout_redirect_uri};
    }

    
    # @return string
    sub getResponseHtml()
    {   
		my( $self ) = @_;
		$self->{_response_html} = $self->getResponseData()->{url};
		return $self->{_response_html};
    }

    # @return string
    sub getRequestIdToken
    {
        my( $self ) = @_;
		return $self->{_request_id_token};
    }

    
    # @return string
    sub getRequestPostLogoutRedirectUri
    {
        my( $self ) = @_;
		return $self->{_request_post_logout_redirect_uri};
	}

    # @param string $request_id_token
    # @return	void
    sub setRequestIdToken
    {
        my ( $self, $request_id_token ) = @_;
		$self->{_request_id_token} = $request_id_token if defined($request_id_token);
		return $self->{_request_id_token};
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
    
    # Protocol command to oxd server
    # @return void
    
    
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
	
	
    
    sub setCommand
    {
        my ( $self, $command ) = @_;
		$self->{_command} = 'get_logout_uri';
		return $self->{_command};
	}
	
    # Protocol command to oXD to http server
    # @return void
    
    sub sethttpCommand
    {
        my ( $self, $httpCommand ) = @_;
		$self->{_httpcommand} = 'get-logout-uri';
		return $self->{_httpcommand};
	}

    # Method: setParams
    # This method sets the parameters for get_logout_uri command.
    # This module uses `request` method of OxdClient module for sending request to oxd-server
    # 
    # Parameters:
    #
    #	string $oxd_id - (Required) oxd Id from Client registration
    #
    #	string $id_token_hint - (Optional) ID Token Hint. oxd Server will use last used ID Token
    #
    #	string $post_logout_redirect_uri - (Optional) Uri to Redirect after Logout
    #
    #	string $state - (Optional) State
    #
    #	string $session_state - (Optional) Session State
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
    # { "status": "ok", "data": { "uri": "https://idp-hostname/oxauth/restv1/end_session?id_token_hint=eyJraWQiOgt6yxMMltA" } }
    # ---
    #
    sub setParams
    {   
		my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "id_token_hint" => $self->getRequestIdToken(),
            "post_logout_redirect_uri" => $self->getRequestPostLogoutRedirectUri(),
            "state" => $self->getRequestState(),
            "session_state" => $self->getRequestSessionState(),
            "protection_access_token"=> $self->getRequestProtectionAccessToken()
        };
        $self->{_params} = $paramsArray;
		return $self->{_params};
    }
	 
	
1;		# this 1; is neccessary for our class to work
