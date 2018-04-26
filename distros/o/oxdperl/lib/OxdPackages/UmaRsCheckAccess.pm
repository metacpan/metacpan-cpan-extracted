#!/usr/bin/perl

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
 # @author		Inderpal Singh, Sobhan Panda
 # @author_email	inderpal@ourdesignz.com, sobhan@centroxy.com
 # @copyright		Copyright (c) 2018, Gluu inc federation (https://gluu.org/)
 # @license		http://opensource.org/licenses/MIT	MIT License
 # @link		https://gluu.org/
 # @since		Version 3.1.3
 # @filesource
 #/

##
 # UMA RP - Check Access class
 #
 # Class is connecting to oxd-server via socket, and getting GAT from gluu-server.
 #
 # @package		Gluu-oxd-library
 # @subpackage		Libraries
 # @category		Relying Party (RP) and User Managed Access (UMA)
 # @author		Inderpal Singh, Sobhan Panda
 # @author		inderpal@ourdesignz.com, sobhan@centroxy.com
 # @see	        	OxdClientSocket
 # @see	        	OxdClient
 # @see	        	OxdConfig
 #
 
package UmaRsCheckAccess;
use vars qw($VERSION);
$VERSION = '0.01';
use OxdPackages::OxdClient;
use base qw(OxdClient Class::Accessor);
use strict;
our @ISA = qw(OxdClient);    # inherits from OxdClient 
use Data::Dumper;
    
    sub new {
		my $class = shift;
		my $self = {
			
			# @var string $request_oxd_id                         This parameter you must get after registration site in gluu-server
			_request_oxd_id  => shift,
			
			# @var string $request_rpt                            This parameter you must get after using uma_rp_get_rpt protocol
			_request_rpt  => shift,
			
			# @var string $request_path                           Path of resource (e.g. http://rs.com/phones), /phones should be passed
			_request_path  => shift,
			
			# @var string $request_http_method                    Http method of RP request (GET, POST, PUT, DELETE)
			_request_http_method  => shift,
			_request_protection_access_token => shift,

			# Response parameter from oxd-server
			# Access grant response (granted or denied)
			# @var string $response_access
			_response_access => shift,

			# Response parameter from oxd-server
			# Ticket number
			# @var string $response_ticket
			_response_ticket => shift,
		};
		# Print all the values just for clarification.
		# print "First Name is $self->{_request_oxd_id}\n";
		
		# print "<br>";
		bless $self, $class;
		return $self;
    } 

   
    # @return string
    sub getRequestOxdId
    {
        my( $self ) = @_;
		return $self->{_request_oxd_id}
    }

    
    # @return string
    sub getResponseTicket
    {
        my( $self ) = @_;
        $self->{_response_ticket} = $self->getResponseData()->{ticket};
		return $self->{_response_ticket}
    }

    
    # @param string $request_oxd_id
    # @return void
    sub setRequestOxdId
    {   
		my ( $self, $request_oxd_id ) = @_;
		$self->{_request_oxd_id} = $request_oxd_id if defined($request_oxd_id);
		return $self->{_request_oxd_id};
	}

    # @return string
    sub getRequestRpt
    {   
		my( $self ) = @_;
		return $self->{_request_rpt}
    }

    # @param string $request_rpt
    # @return void
    sub setRequestRpt
    {
        my ( $self, $request_rpt ) = @_;
		$self->{_request_rpt} = $request_rpt if defined($request_rpt);
		return $self->{_request_rpt};
    }

    # @return string
    sub getRequestPath
    {   
		my( $self ) = @_;
		return $self->{_request_path} 
    }

    # @param null $request_path
    # @return void
    sub setRequestPath
    {
        my ( $self, $request_path ) = @_;
		$self->{_request_path} = $request_path if defined($request_path);
		return $self->{_request_path};
    }

    # @return string
    sub getRequestHttpMethod
    {   
		my( $self ) = @_;
		return $self->{_request_http_method} 
    }

    
    # @param string $request_http_method
    # @return void
    sub setRequestHttpMethod
    {   
		 my ( $self, $request_http_method ) = @_;
		$self->{_request_http_method} = $request_http_method if defined($request_http_method);
		return $self->{_request_http_method};
	}


    # @return string
    sub getRequestProtectionAccessToken
    {   
		my( $self ) = @_;
		return $self->{_request_protection_access_token}
    }

    ##
    # @param string $request_protection_access_token
    # @return void
    #
    sub setRequestProtectionAccessToken
    {   
		my ( $self, $request_protection_access_token ) = @_;
		$self->{_request_protection_access_token} = $request_protection_access_token if defined($request_protection_access_token);
		return $self->{_request_protection_access_token};
    }
    
    # @return string
    sub getResponseAccess
    {   
		my( $self ) = @_;
		$self->{_response_access}  = $self->getResponseData()->access;
		return $self->{_response_access} 
	}

    
    # Protocol command to oxd server
    # @return void
    sub setCommand
    {
        my ( $self ) = @_;
        $self->{_command} = 'uma_rs_check_access';
    }
    
    # Protocol command to oxd to http server
    # @return void
    sub sethttpCommand
    {
        my ( $self ) = @_;
        $self->{_httpcommand} = 'uma-rs-check-access';
    }

    
    # Method: setParams
    # This method sets the parameters for uma_rs_check_access command.
    # This module uses `request` method of OxdClient module for sending request to oxd-server
    # 
    # Parameters:
    #
    #	string $oxd_id - (Required) oxd Id from Client registration
    #
    #	string $rpt - (Required) RPT Token. Can have blank value if absent (not send by RP)
    #
    #	string $path - (Required) Path of resource (e.g. http://rs.com/phones), /phones should be passed
    #
    #	string $http_method - (Required) Http method of RP request (GET, POST, PUT, DELETE)
    #
    #	string $protection_access_token - Protection Acccess Token. OPTIONAL for `oxd-server` but REQUIRED for `oxd-https-extension`
    #
    # Returns:
    #	void
    #
    # This module uses `getResponseObject` method of OxdClient module for getting response from oxd.
    # 
    # *Access Granted Response from getResponseObject:*
    # --- Code
    # { "status":"ok", "data":{ "access":"granted" } }
    # ---
    #
    # *Access Denied with Ticket Response from getResponseObject:*
    # --- Code
    # { "status": "ok", "data": { "access": "denied", "www-authenticate_header": "UMA realm=\"rs",as_uri="https://as.example.com",error="insufficient_scope",ticket="d26c30fd-eb94-40da-9f61-0c424acedf0e"", "ticket": "d26c30fd-eb94-40da-9f61-0c424acedf0e", "error": null, "error_description": null } }
    # ---
    #
    # *Access Denied without Ticket Response from getResponseObject:*
    # --- Code
    # { "status": "ok", "data": { "access": "denied", } }
    # ---
    #
    # *Resource is not Protected from getResponseObject:*
    # --- Code
    # { "status":"error", "data":{ "error":"invalid_request", "error_description":"Resource is not protected. Please protect your resource first with uma_rs_protect command." } }
    # ---
    #
    sub setParams
    {
        my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "rpt" => $self->getRequestRpt(),
            "path" => $self->getRequestPath(),
            "http_method" => $self->getRequestHttpMethod(),
            "protection_access_token" => $self->getRequestProtectionAccessToken()
        };
        $self->{_params} = $paramsArray;
        return $self->{_params};
        
    }

1;		# this 1; is neccessary for our class to work
