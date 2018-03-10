#!/usr/bin/perl
# OxdRemove.pm, a number as an object

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
# @version 	3.1.2
# @author	Sobhan Panda
# @author_email	sobhan@centroxy.com
# @copyright	Copyright (c) 2018, Gluu inc federation (https://gluu.org/)
# @license	http://opensource.org/licenses/MIT	MIT License
# @link		https://gluu.org/
# @since	Version 3.1.2
# @filesource
#/

use JSON::PP;

package OxdRemove;	# This is the &quot;Class&quot;
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
			
			# @var string _request_oxd_id				OxdId from Client registration
			_request_oxd_id => shift,
			
			# @var array $request_protection_access_token          To protect the command with access token
			_request_protection_access_token => shift,
			
			# Response parameter from oxd-server
			# It is basic parameter for other protocols
			#
			# @var string _response_oxd_id
			_response_oxd_id => shift,

		};
		
		bless $self, $class;
		return $self;
	}
	
	sub _initialize {} 
    
    
    # @param string $request_op_host
    # @return void
    sub setRequestOxdId {
		my ( $self, $request_op_host ) = @_;
		$self->{_request_oxd_id} = $request_op_host if defined($request_op_host);
		return $self->{_request_oxd_id};
	}
  
    # @return string
    sub getRequestOxdId {
		my( $self ) = @_;
		return $self->{_request_oxd_id};
	}
    

    # @return string
    sub getResponseOxdId{
		my( $self ) = @_;
		$self->{_response_oxd_id} = $self->getResponseData()->{oxd_id};
        return $self->{_response_oxd_id};
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
    sub setCommand{
		# my $command = 'remove_site';
        my ( $self, $command ) = @_;
		$self->{_command} = 'remove_site';
		return $self->{_command};
		#return $command;
    }
    
    # Protocol command to oxd to http server
    # @return void
    sub sethttpCommand{
		# my $command = 'remove-site';
        my ( $self, $httpCommand ) = @_;
		$self->{_httpcommand} = 'remove-site';
		return $self->{_httpcommand};
		#return $httpcommand;
    }
    
    # Method: setParams
    # This method sets the parameters for remove_site command.
    # This module uses `request` method of OxdClient module for sending request to oxd-server
    # 
    # Parameters:
    #
    #	string $oxd_id - (Required) oxd Id from Client registration
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
    # { "status":"ok", "data":{ "oxd_id":"c73134c8-c4ca-4bab-9baa-2e0ca20cc433" } }
    # ---
    #
    sub setParams{
		
		my ( $self, $params ) = @_;
		#use Data::Dumper;
		my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "protection_access_token"=> $self->getRequestProtectionAccessToken()
        };
       
		$self->{_params} = $paramsArray;
		return $self->{_params};
        #print Dumper( $params );
        #return $paramsArray;
    }
    
1;		# this 1; is neccessary for our class to work
