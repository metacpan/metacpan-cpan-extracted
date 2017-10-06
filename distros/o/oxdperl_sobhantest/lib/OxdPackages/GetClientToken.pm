#!/usr/bin/perl
# GetClientToken.pm, a number as an object

#
# Gluu-oxd-library
#
# An open source application library for Perl
#
# This content is released under the MIT License (MIT)
#
# Copyright (c) 2017, Gluu inc, USA, Austin
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
# @version	3.1.0
# @author	Sobhan Panda
# @author_email	sobhan@centroxy.com
# @copyright	Copyright (c) 2017, Gluu inc federation (https://gluu.org/)
# @license	http://opensource.org/licenses/MIT	MIT License
# @link		https://gluu.org/
# @since	Version 3.1.0
# @filesource
#/

use JSON::PP;

package GetClientToken;	# This is the &quot;Class&quot;
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
			
			
			
			# Response parameter from oxd-server
			# It is basic parameter for other protocols
			#
			# @var string _response_access_token
			_response_access_token => shift,
			
			# @var string _response_expires_in
			_response_expires_in => shift,

			# @var string _response_refresh_token
			_response_refresh_token => shift,			
			
			# Response parameter from oxd-server
			#
			# @var string _response_scope
			_response_scope => shift,
		};
		#print "<br>";
		bless $self, $class;
		return $self;
	}  
	sub _initialize {} 
    
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
    sub getRequestOpDiscoveryPath{
        my( $self ) = @_;
		return $self->{_request_op_discovery_path};
    }

    # @param array $request_op_discovery_path
    # @return void
    sub setRequestOpDiscoveryPath{
        my ( $self, $request_op_discovery_path ) = @_;
		$self->{_request_op_discovery_path} = $request_op_discovery_path if defined($request_op_discovery_path);
		return $self->{_request_op_discovery_path};
    }

    # @return string
    sub getResponseAccessToken {
		my( $self ) = @_;
		$self->{_response_access_token} = $self->getResponseData()->{access_token};
        return $self->{_response_access_token};
    }
    
    # @return int
    sub getResponseExpiresIn {
		my( $self ) = @_;
		$self->{_response_expires_in} = $self->getResponseData()->{expires_in};
        return $self->{_response_expires_in};
    }
    
    # @return string
    sub getResponseRefreshToken {
		my( $self ) = @_;
		$self->{_response_refresh_token} = $self->getResponseData()->{refresh_token};
        return $self->{_response_refresh_token};
    }
    
    # @return string
    sub getResponseScope {
		my( $self ) = @_;
		$self->{_response_scope} = $self->getResponseData()->{scope};
        return $self->{_response_scope};
    }

    # Protocol command to oxd server
    # @return void
    sub setCommand{
		# my $command = 'get_client_token';
        my ( $self, $command ) = @_;
		$self->{_command} = 'get_client_token';
		return $self->{_command};
		#return $command;
    }
    
    # Protocol command to oxd to http server
    # @return void
    sub sethttpCommand{
		# my $httpCommand = 'get-client-token';
        my ( $self, $httpCommand ) = @_;
		$self->{_httpcommand} = 'get-client-token';
		return $self->{_httpcommand};
		#return $httpcommand;
    }
    
    # Protocol parameter to oxd server
    # @return void
    sub setParams{
		
		my ( $self, $params ) = @_;
		#use Data::Dumper;
		my $paramsArray = {
            "client_id"=> $self->getRequestClientId(),
            "client_secret"=> $self->getRequestClientSecret(),
            "op_host" => $self->getRequestOpHost(),
            "op_discovery_path" => $self->getRequestOpDiscoveryPath()
        };
       
		$self->{_params} = $paramsArray;
		return $self->{_params};
        #print Dumper( $params );
        #return $paramsArray;
    }
    
1;		# this 1; is neccessary for our class to work
