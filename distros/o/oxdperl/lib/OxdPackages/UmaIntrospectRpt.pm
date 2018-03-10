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
 # @version     	3.1.2
 # @author		Sobhan Panda
 # @author_email	sobhan@centroxy.com
 # @copyright		Copyright (c) 2018, Gluu inc federation (https://gluu.org/)
 # @license		http://opensource.org/licenses/MIT	MIT License
 # @link		https://gluu.org/
 # @since		Version 3.1.2
 # @filesource
 #


package UmaIntrospectRpt;
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
			
			# @var string $request_oxd_id                            This parameter you must get after registration site in gluu-server
			_request_oxd_id => shift,
			
			_request_rpt => shift,
			
			
			# Response parameter from oxd-server
			# 
			# @var string $response_active
			
			_response_active => shift,
			
		};
		
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

    ##
    # @param string $request_oxd_id
    # @return void
    #
    sub setRequestOxdId
    {   
		my ( $self, $request_oxd_id ) = @_;
		$self->{_request_oxd_id} = $request_oxd_id if defined($request_oxd_id);
		return $self->{_request_oxd_id};
    }

    
    # @return string
    sub getRequestRPT
    {   
		my( $self ) = @_;
		return $self->{_request_rpt}
    }

    ##
    # @param string $request_rpt
    # @return void
    #
    sub setRequestRPT
    {   
		my ( $self, $request_rpt ) = @_;
		$self->{_request_rpt} = $request_rpt if defined($request_rpt);
		return $self->{_request_rpt};
    }
    
    
    ##
    # @return string
    #
    sub getResponseActive
    {    
		my( $self ) = @_;
		$self->{_response_active} = $self->getResponseData()->{active};
        return $self->{_response_active};
    }


    ##
    # Protocol command to oxd server
    # @return void
    #
    sub setCommand
    {	
		my ( $self ) = @_;
        $self->{_command} = 'introspect_rpt';
    }
    
    ##
    # Protocol command to oxd to http server
    # @return void
    #
    sub sethttpCommand
    {	
		my ( $self ) = @_;
        $self->{_httpcommand} = 'introspect-rpt';
    }

    # Method: setParams
    # This method sets the parameters for introspect_rpt command.
    # This module uses `request` method of OxdClient module for sending request to oxd-server
    # 
    # Parameters:
    #
    #	string $oxd_id - (Required) oxd Id from Client registration
    #
    #	string $rpt - (Required) Request Party Token
    #
    # Returns:
    #	void
    #
    # This module uses `getResponseObject` method of OxdClient module for getting response from oxd.
    # 
    # *Example response from getResponseObject:*
    # --- Code
    # { "status": "ok", "data": { "active": true, "exp": 1518091492556, "iat": 1518091192556, "nbf": null, "permissions": [{ "resource_id": "dd270f7b-551c-42e5-a1fa-a1811cff3f72", "resource_scopes": ["https://client.example.com:44300/api"], "exp": 1518094783755 }], "client_id": null, "sub": null, "aud": null, "iss": null, "jti": null } }
    # ---
    #
    sub setParams
    {
        my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "rpt" => $self->getRequestRPT()
        };
        $self->{_params} = $paramsArray;
        return $self->{_params};
    }

1;		# this 1; is neccessary for our class to work
